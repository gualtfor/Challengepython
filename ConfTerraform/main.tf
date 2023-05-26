provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "depot" {
  bucket = "${var.bucket_name}-challenge"
  force_destroy = true

  tags = {
    Name        = "My-bucket"
    Environment = "${var.env}"
  }
}

module "vpc" {
  source  = "https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/examples/simple"

  name                 = "vpc_challenge"
  cidr                 = "10.0.0.0/16"
  azs                  = var.availability_zones
  enable_dns_hostnames = true
  enable_dns_support   = true
  
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.40.1"
  name = "subnets_challenge"
  environment = "${var.env}"
  label_order = ["name", "environment"]
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false 
}

resource "aws_security_group" "securitychallenge" {
  name   = "securitychallenge"
  vpc_id = module.vpc.vpc_id
 
  ingress {
    from_port = 0
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]   #["10.0.1.0/24"]
  }
 
  egress {
    from_port = 0
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "rds_instance" {
  source                  = "../../"
  db_name                 = var.database_name
  username                = var.database_user
  password                = var.database_password
  port                    = var.database_port
  multi_az                = var.multi_az
  storage_type            = var.storage_type
  allocated_storage       = var.allocated_storage
  storage_encrypted       = var.storage_encrypted
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  family                  = var.db_parameter_group
  publicly_accessible     = var.publicly_accessible
  subnet_ids              = module.subnets.public_subnet_ids #module.subnets.private_subnet_ids
  vpc_security_group_ids  = [aws_security_group.securitychallenge.id] # [aws_security_group.securitychallenge.security_group_id] #[module.vpc.vpc_default_security_group_id]
  apply_immediately       = var.apply_immediately
  availability_zone       = var.availability_zones

  parameters = [
    {
      name         = "myisam_sort_buffer_size"
      value        = "1048576"
      apply_method = "immediate"
    },
    {
      name         = "sort_buffer_size"
      value        = "2097152"
      apply_method = "immediate"
    }
  ]

}


  data "aws_iam_policy_document" "ConfLambda" {
  statement {
    actions   = ["s3:ListBucket",
                  "s3:GetObject",
                  "s3:CopyObject",
                  "s3:HeadObject"]
    resources = [aws_s3_bucket.depot.arn]
    effect = "Allow"
  }

  statement {
    actions   = ["rds:*"]
    resources = [module.rds_instance.arn] #[module.rds_instance.database_name.arn]
    effect = "Allow"
  }

  statement {
    actions  = ["logs:CreateLogGroup",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents"]
    resources = ["*"]
    effect  = "Allow"
  }
  
}

  resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.database_name}_lambda_policy"
  description = "${var.database_name}_lambda_policy"
  policy = data.aws_iam_policy_document.ConfLambda
  }


  resource "aws_iam_role" "s3_copy_function" {
    name = "app_${var.database_name}_lambda"
    assume_role_policy = jsonencode({
      Version = "2023-05-24"
      Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
        Service = "lambda.amazonaws.com"
        }
      }]
    })
  }
/*       <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
} */

resource "aws_iam_role_policy_attachment" "Join_between_policy_and_roles" {
 role =       aws_iam_role.s3_copy_function.name #"${aws_iam_role.s3_copy_function.id}"
 policy_arn = "${aws_iam_policy.lambda_policy.arn}" # here i think is wrong
}

resource "aws_lambda_permission" "allow_lambda_bucket" {
   statement_id = "AllowExecutionFromS3Bucket"
   action = "lambda:InvokeFunction"
   function_name = "${aws_lambda_function.s3_copy_function.arn}"
   principal = "s3.amazonaws.com"
   source_arn = "${aws_s3_bucket.depot.arn}"
}





/* data "aws_s3_object" "s3_archive_function" {
  bucket = ""${var.bucket_name}-challenge""
  key    = "Functionlambda.zip"
  source = "la ruta de mi github"
  depends_on = [
    null_resource.build  # wait until our upload script is done
  ]
}
 */
resource "aws_lambda_function" "s3_copy_function" {
   filename = data.archive_file.my_lambda_function.output_path
   source_code_hash = data.archive_file.my_lambda_function.output_base64sha256 # filebase64sha256(data.archive_file.my_lambda_function.output_path)
   function_name = "${var.database_name}_s3_copy_lambda"
   role = aws_iam_role.s3_copy_function.arn
   handler = "CopyS3.handler"
   runtime = "python3.8"
   environment {
       variables = {
           APP_DB_USER = "${var.database_user}"
           APP_DB_PASS = "${var.database_password}"
           APP_DB_NAME = "${var.database_for_create_table}"
           DB_HOST = module.rds_instance.address
           DB_INSTANCE_NAME = module.rds_instance.database_name
           ENV = "${var.env}"
           PROJECT = "${var.project}"
       }
   }
}