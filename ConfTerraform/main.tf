provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "depot" {
  bucket = "${var.bucket_name}-challenge"
  force_destroy = true

  tags = {
    Name        = "My-bucket"
    Environment = "Dev"
  }
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.28.1"
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
 
  tags = {
    Name = "Vpc-challenge"
  }

  
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.40.1"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  
}
resource "aws_security_group" "securitychallenge" {
  name_prefix = "securitychallenge"
  vpc_id = module.vpc.vpc_id
 
  ingress {
    from_port = 0
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
 
  egress {
    from_port = 0
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "rds_instance" {
  source               = "../../"
  database_name        = var.database_name
  database_user        = var.database_user
  database_password    = var.database_password
  database_port        = var.database_port
  multi_az             = var.multi_az
  storage_type         = var.storage_type
  allocated_storage    = var.allocated_storage
  storage_encrypted    = var.storage_encrypted
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_parameter_group   = var.db_parameter_group
  publicly_accessible  = var.publicly_accessible
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.subnets.private_subnet_ids
  security_group_ids   = [aws_security_group.securitychallenge.id] #[module.vpc.vpc_default_security_group_id]
  apply_immediately    = var.apply_immediately
  availability_zone    = var.availability_zone
  db_subnet_group_name = var.db_subnet_group_name

  db_parameter = [
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
    resources = [module.rds_instance.database_name.arn]
    effect = "Allow"
  }
}

  resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.database_name}_lambda_policy"
  description = "${var.database_name}_lambda_policy"
  policy = data.aws_iam_policy_document.ConfLambda
  }


  resource "aws_iam_role" "s3_copy_function" {
    name = "app_${var.database_name}_lambda"
    assume_role_policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "Join_between_policy_and_roles" {
 role = "${aws_iam_role.s3_copy_function.id}"
 policy_arn = "${aws_iam_policy.lambda_policy.arn}"
}
