variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "database_name" {
  type        = string
  default     = "DB"
  description = "The name of the database to create when the DB instance is created"
}

variable "database_user" {
  type        = string
  description = "Username for the primary DB user"
}

variable "database_password" {
  type        = string
  description = "Password for the primary DB user"
}

variable "database_port" {
  type        = number
  description = "Database port (_e.g._ `3306` for `MySQL`). Used in the DB Security Group to allow access to the DB instance from the provided `security_group_ids`"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "Set to true to enable deletion protection on the RDS instance"
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Set to true if multi AZ deployment must be supported"
}

variable "availability_zone" {
  type        = string
  default     = null
  description = "The AZ for the RDS instance. Specify one of `subnet_ids`, `db_subnet_group_name` or `availability_zone`. If `availability_zone` is provided, the instance will be placed into the default VPC or EC2 Classic"
}

variable "db_subnet_group_name" {
  type        = string
  default     = null
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. Specify one of `subnet_ids`, `db_subnet_group_name` or `availability_zone`"
}

variable "storage_type" {
  type        = string
  default     = "standard"
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
}

variable "storage_encrypted" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether the DB instance is encrypted. The default is false if not specified"
}

variable "allocated_storage" {
  type        = number
  default     = 5
  description = "The allocated storage in GBs"
}

variable "engine" {
  type        = string
  default     = "mysql"
  description = "Database engine type"
  # http://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
  # - mysql
  # - postgres
  # - oracle-*
  # - sqlserver-*
}

variable "engine_version" {
  type        = string
  default     = "5.7"
  description = "Database engine version, depends on engine type"
  # http://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
}

variable "major_engine_version" {
  type        = string
  default     = "8"
  description = "Database MAJOR engine version, depends on engine type"
  # https://docs.aws.amazon.com/cli/latest/reference/rds/create-option-group.html
}

variable "instance_class" {
  type        = string
  default     = "db.t2.small"
  description = "Class of RDS instance"
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
}

variable "db_parameter_group" {
  type        = string
  default     = "default.mysql5.7"
  description = "Parameter group, depends on DB engine used"
  # "mysql5.6"
  # "postgres9.5"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "Determines if database can be publicly available (NOT recommended)"
}

variable "apply_immediately" {
  type        = bool
  default     = true
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
}
variable "bucket_name" {
  type        = string
  default     = "bucketproof"
  description = "Name of the bucket"

}

variable "env" {
  type        = string
  default     = "Dev"
  description = "Name of environment"

}

variable "project" {
  type        = string
  default     = "Challenge-globant"
  description = "Name of proyect"

}

variable "database_for_create_table" {
  type        = string
  default     = "DBcompany"
  description = "Name of proyect"

}
locals {
  my_function_source = "C:/Users/gualtfor/Desktop/Machine Learning/Challengepython/app/Functionlambda/CopyS3.zip"
  my_library_source  = "C:/Users/gualtfor/Desktop/Machine Learning/Challengepython/app/libraries/build/python.zip"
}

/* data "archive_file" "my_lambda_function" {
  type              = "zip"
  source_dir       = "${path.module}/app/Funtionlambda/CopyS3."
  output_file_mode  = "0666"
  output_path       = "${path.module}/app/Functionlambda/CopyS3.zip"
} */


