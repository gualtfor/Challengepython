provider "aws" {
  region = var.region
}

/* resource "aws_s3_bucket" "depot" {
  bucket        = "${var.bucket_name}-challenge"
  force_destroy = true

  tags = {
    Name        = "My-bucket"
    Environment = "${var.env}"
  }
} */


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"
  name    = "vpc_challenge"
  cidr    = "10.0.0.0/16"
  azs     = var.availability_zones
  #public_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  #private_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway = true
  enable_vpn_gateway = true

}

resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.vpc_id
  #cidr_block = "10.0.5.0/24"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main1" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Main1"
  }
}
resource "aws_subnet" "main2" {
  vpc_id     = module.vpc.vpc_id
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Main2"
  }
}
resource "aws_subnet" "main3" {
  vpc_id     = module.vpc.vpc_id
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Main3"
  }
}

resource "aws_db_subnet_group" "subnet" {
  name       = "subnets_challenge"
  subnet_ids = [aws_subnet.main1.id, aws_subnet.main2.id, aws_subnet.main3.id]

  tags = {
    Name = "subnets_challenge"
  }
}



resource "aws_security_group" "securitychallenge" {
  name   = "securitychallenge"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 80  
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    # Only allowing traffic in from the load balancer security group
    #security_groups = ["${aws_security_group.securitychallenge.id}"]
  }
  ingress {
    from_port = 3000  
    to_port   = 3000
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    # Only allowing traffic in from the load balancer security group
    #security_groups = ["${aws_security_group.securitychallenge.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "postgres"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}
resource "aws_route" "r" {
  route_table_id            = module.vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.gw.id
  
}

/* resource "aws_route_table" "routetablepublic" { # this is why i cannot connect the database
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
} */

/* 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.routetablepublic.id
}

resource "aws_route_table_association" "b" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.routetablepublic.id
}  */
 
resource "aws_db_instance" "rds_instance" {
  #source                 = "terraform-aws-modules/rds/aws" This module is restricted for some az
  identifier             = "postgresdb"
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
  parameter_group_name   = aws_db_parameter_group.postgres.name
  publicly_accessible    = var.publicly_accessible
  db_subnet_group_name   = aws_db_subnet_group.subnet.id
  vpc_security_group_ids = [aws_security_group.securitychallenge.id]
  apply_immediately      = var.apply_immediately
  availability_zone      = "us-east-1a"
  skip_final_snapshot    = true

}

resource "aws_ecr_repository" "app_ecr_repo" {
  name = "challenge"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "app-challenge" 
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-first-task" # Name your task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-first-task", 
      "image": "${aws_ecr_repository.app_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
      {
          "name": "app-first-task-80-tcp",
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp",
          "appProtocol": "http"
      }
      ],
      "memory": 512,
      "cpu": 256
      
    }
  ]
  DEFINITION
  runtime_platform {
        cpu_architecture = "X86_64"
        operating_system_family = "LINUX"
      }
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type  i take out , "EC2"
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

}

/* ,
      {
          "name": "app-first-task-3000-tcp",
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp",
          "appProtocol": "http"
      },
      {
          "name": "app-first-task-5432-tcp",
          "containerPort": 5432,
          "hostPort": 5432,
          "protocol": "tcp",
          "appProtocol": "http"
      } */
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

 
resource "aws_security_group" "service_security_groupforloadbalancer" {
  name   = "securitychallenge2"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 80  
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    # Only allowing traffic in from the load balancer security group
    #security_groups = ["${aws_security_group.securitychallenge.id}"]
  }
/*   ingress {
    from_port = 3000  
    to_port   = 3000
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    # Only allowing traffic in from the load balancer security group
    #security_groups = ["${aws_security_group.securitychallenge.id}"]
  } */

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "load-balancer-dev" #load balancer name
  load_balancer_type = "application"
  subnets = ["${aws_subnet.main1.id}", "${aws_subnet.main2.id}", "${aws_subnet.main3.id}"]
  # security group
  security_groups = ["${aws_security_group.service_security_groupforloadbalancer.id}"] # it is possible that this security group does not be
}



resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id # default VPC
  health_check {
    matcher     = "200-307"    
  }
  
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.application_load_balancer.arn}" #  load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
}


resource "aws_ecs_service" "app_service" {
  name            = "app-first-service"     # Name the service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.app_task.arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Set up the number of containers to 3
  #health_check_grace_period_seconds = 180

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference the target group
    container_name   = "${aws_ecs_task_definition.app_task.family}"
    container_port   = 80 # Specify the container port change the previous was 3000
  }

  network_configuration {
    subnets          = ["${aws_subnet.main1.id}", "${aws_subnet.main2.id}", "${aws_subnet.main3.id}"]
    assign_public_ip = true     # Provide the containers with public IPs
    security_groups  = ["${aws_security_group.securitychallenge.id}"] # Set up the security group i need to see if be challenge
  }
}
 




/* 







data "aws_iam_policy_document" "ConfLambda" {
  statement {
    sid     = "visual1"
    effect  = "Allow"
    actions = [ "*",
                "logs:CreateLogStream",
                "s3:ListAllMyBuckets",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"]
    resources = [aws_s3_bucket.depot.arn]
    }

  statement {
    sid     = "visual2"
    effect  = "Allow"
    actions = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetObjectVersion",
                "s3:ListMultipartUploadParts"]
    resources = [aws_s3_bucket.depot.arn]
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

/* module "layer" {
  source              = "terraform-aws-modules/lambda/aws"
  create_layer        = true
  layer_name          = "dependencies_of_code"
  description         = "You need to install the libraries"
  compatible_runtimes = ["python3.8"]
  source_path         = "C:/Users/gualtfor/Desktop/Machine Learning/Challengepython/app/libraries/build"
  store_on_s3         = true
  s3_bucket           = aws_s3_bucket.depot.id

} */

 