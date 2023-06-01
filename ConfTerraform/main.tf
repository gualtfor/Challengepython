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
    Name = "Main2"
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
      },
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
  requires_compatibilities = ["FARGATE", "EC2"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

}


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
  subnets = ["${aws_subnet.main1.id}", "${aws_subnet.main2.id}"]
  # security group
  security_groups = ["${aws_security_group.service_security_groupforloadbalancer.id}"] # it is possible that this security group does not be
}



resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id # default VPC
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
  health_check_grace_period_seconds = 180

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference the target group
    container_name   = "${aws_ecs_task_definition.app_task.family}"
    container_port   = 3000 # Specify the container port
  }

  network_configuration {
    subnets          = ["${aws_subnet.main1.id}", "${aws_subnet.main2.id}"]
    assign_public_ip = true     # Provide the containers with public IPs
    security_groups  = ["${aws_security_group.securitychallenge.id}"] # Set up the security group i need to see if be challenge
  }
}
