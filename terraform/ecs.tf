data "aws_caller_identity" "current" {}

# 1. ECR Repositories
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.environment}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "backend" {
  name                 = "${var.environment}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# 3. Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name              = "${var.environment}-ecs-tasks-sg"
  description       = "Allow traffic from ALB only"
  vpc_id            = aws_vpc.main.id

  depends_on        = [aws_vpc.main, aws_security_group.alb_sg]

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-ecs-tasks-sg" }
}

# 4. IAM Roles for ECS Fargate
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [{
      Action         = "sts:AssumeRole"
      Effect         = "Allow"
      Principal      = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role              = aws_iam_role.ecs_execution_role.name
  policy_arn        = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  depends_on = [aws_iam_role.ecs_execution_role]
}

resource "aws_iam_role" "ecs_task_role" {
  name              = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version         = "2012-10-17"
    Statement       = [{
      Action        = "sts:AssumeRole"
      Effect        = "Allow"
      Principal     = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# 5. Frontend Task Definition & Service
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.environment}-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  # Task requires IAM policy attachment to finish BEFORE task registration
  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_ecr_repository.frontend
  ]

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-frontend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "PORT", value = "3000" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.environment}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  # Service strictly requires NAT Gateway, Subnets, ALB Listeners, and Task Definition
  depends_on = [
    aws_ecs_task_definition.frontend,
    aws_lb_listener.http,
    aws_nat_gateway.nat,
    aws_route_table_association.priv_app_1,
    aws_route_table_association.priv_app_2
  ]

  network_configuration {
    subnets          = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 3000
  }
}

# 6. Backend Task Definition & Service
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.environment}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_ecr_repository.backend,
    aws_db_instance.postgres
  ]

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-backend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        { name = "PORT", value = "8000" },
        { name = "DB_HOST", value = aws_db_instance.postgres.address }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  depends_on = [
    aws_ecs_task_definition.backend,
    aws_lb_listener_rule.backend_rule,
    aws_nat_gateway.nat,
    aws_db_instance.postgres
  ]

  network_configuration {
    subnets          = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 8000
  }
}