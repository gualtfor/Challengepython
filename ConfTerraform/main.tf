provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "depot" {
  bucket        = "${var.bucket_name}-challenge"
  force_destroy = true

  tags = {
    Name        = "My-bucket"
    Environment = "${var.env}"
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"
  name    = "vpc_challenge"
  cidr    = "10.0.0.0/16"
  azs     = var.availability_zones
  #private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true

}

resource "aws_db_subnet_group" "subnet" {
  name       = "subnets_challenge"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "subnets"
  }
}


resource "aws_security_group" "securitychallenge" {
  name   = "securitychallenge"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] #["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds_instance" {
  #source                 = "terraform-aws-modules/rds/aws" This module is restricted for some az
  identifier             = "dbmysql"
  db_name                = var.database_name
  username               = var.database_user
  password               = var.database_password
  port                   = var.database_port
  multi_az               = var.multi_az
  storage_type           = var.storage_type
  allocated_storage      = var.allocated_storage
  storage_encrypted      = var.storage_encrypted
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  parameter_group_name   = var.db_parameter_group
  publicly_accessible    = var.publicly_accessible
  db_subnet_group_name   = aws_db_subnet_group.subnet.id
  vpc_security_group_ids = ["${aws_security_group.securitychallenge.id}"]
  apply_immediately      = var.apply_immediately
  availability_zone      = "us-east-1a"
  skip_final_snapshot    = true

}


data "aws_iam_policy_document" "ConfLambda" {
  statement {
    actions = ["s3:ListBucket",
      "s3:GetObject",
      "s3:CopyObject",
    "s3:HeadObject", "s3-object-lambda:GetObject", "s3-object-lambda:GetObjectAcl", "s3-object-lambda:GetObjectLegalHold"]
    resources = [aws_s3_bucket.depot.arn]
    effect    = "Allow"
  }

  statement {
    actions   = ["rds:*"]
    resources = [aws_db_instance.rds_instance.arn] 
    effect    = "Allow"
  }

  statement {
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["*"]
    effect    = "Allow"
  }

}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.database_name}_lambda_policy"
  description = "${var.database_name}_lambda_policy"
  policy      = data.aws_iam_policy_document.ConfLambda.json
}


resource "aws_iam_role" "s3_copy_function" {
  name                  = "app_${var.database_name}_lambda"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }, ]
  })
}


resource "aws_iam_role_policy_attachment" "Join_between_policy_and_roles" {
  role       = aws_iam_role.s3_copy_function.name 
  policy_arn = aws_iam_policy.lambda_policy.arn   
}

resource "aws_lambda_permission" "allow_lambda_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_copy_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.depot.arn
}

resource "aws_s3_object" "folder1" {
    bucket = aws_s3_bucket.depot.id
    #acl    = "public"
    key    = "datacsv/"
    #source = "/null"
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
   bucket             = "${aws_s3_bucket.depot.id}"
   lambda_function {
       lambda_function_arn  = "${aws_lambda_function.s3_copy_function.arn}"
       events               = ["s3:ObjectCreated:*"]
       filter_prefix        = "datacsv/"
       filter_suffix        = ".csv"
   }
   depends_on = [ aws_lambda_permission.allow_lambda_bucket ]
   
}

resource "aws_s3_object" "my_function_to_bucket" {
  bucket = aws_s3_bucket.depot.id
  key    = "${filemd5(local.my_function_source)}.zip"
  source = local.my_function_source
}


resource "aws_lambda_function" "s3_copy_function" {
  s3_bucket        = aws_s3_bucket.depot.id
  s3_key           = aws_s3_object.my_function_to_bucket.key
  source_code_hash = local.my_function_source # filebase64sha256(data.archive_file.my_lambda_function.output_path)
  function_name    = "${var.database_name}_s3_copy_lambda"
  role             = aws_iam_role.s3_copy_function.arn
  handler          = "CopyS3.lambda_handler"
  runtime          = "python3.8"
  layers           = [module.layer.lambda_layer_arn]
  environment {
    variables = {
      APP_DB_USER      = "${var.database_user}"
      APP_DB_PASS      = "${var.database_password}"
      APP_DB_NAME      = "${var.database_for_create_table}"
      DB_HOST          = "${aws_db_instance.rds_instance.address}"
      DB_INSTANCE_NAME = "${aws_db_instance.rds_instance.db_name}"
      ENV              = "${var.env}"
      PROJECT          = "${var.project}"
      Serverless       = "Terraform"
    }
  }
}

/* resource "aws_s3_object" "my_libraries_to_bucket" {
  bucket = aws_s3_bucket.depot.id
  key    = "${filemd5(local.my_library_source)}.zip"
  source = local.my_function_source
} */

module "layer" {
  source              = "terraform-aws-modules/lambda/aws"
  create_layer        = true
  layer_name          = "dependencies_of_code"
  description         = "You need to install the libraries"
  compatible_runtimes = ["python3.8"]
  source_path         = "C:/Users/gualtfor/Desktop/Machine Learning/Challengepython/app/libraries/build"
  store_on_s3         = true
  s3_bucket           = aws_s3_bucket.depot.id

}

