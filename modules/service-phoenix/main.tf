data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "terraform-spookyfox"
    key    = "shared"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  shared     = data.terraform_remote_state.shared.outputs
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "task_execution" {
  name_prefix = "${var.name}-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "task_execution_ssm" {
  name = "ssm-read"
  role = aws_iam_role.task_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["ssm:GetParameters"]
      Effect   = "Allow"
      Resource = [
        "arn:aws:ssm:us-west-2:${local.account_id}:parameter/spookyfox/services/phoenix/secret",
        "arn:aws:ssm:us-west-2:${local.account_id}:parameter/spookyfox/services/phoenix/admin-password",
      ]
    }]
  })
}

resource "aws_iam_role" "task" {
  name_prefix = "${var.name}-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

resource "aws_efs_file_system" "phoenix" {
  creation_token = "phoenix-data"
  encrypted      = true

  tags = {
    Name      = "phoenix-data"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "efs" {
  name_prefix = "${var.name}-efs-"
  description = "Phoenix EFS mount targets"
  vpc_id      = local.shared.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [local.shared.ecs_security_group_id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_mount_target" "a" {
  file_system_id  = aws_efs_file_system.phoenix.id
  subnet_id       = local.shared.public_subnet_ids[0]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "b" {
  file_system_id  = aws_efs_file_system.phoenix.id
  subnet_id       = local.shared.public_subnet_ids[1]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  volume {
    name = "phoenix-data"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.phoenix.id
    }
  }

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image
    essential = true
    portMappings = [
      { containerPort = 6006, protocol = "tcp" },
      { containerPort = 4317, protocol = "tcp" },
    ]
    mountPoints = [{
      sourceVolume  = "phoenix-data"
      containerPath = "/phoenix/data"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = "us-west-2"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = local.shared.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.shared.public_subnet_ids
    security_groups  = [local.shared.ecs_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = 6006
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb_target_group" "this" {
  name_prefix = "phx-"
  port        = 6006
  protocol    = "HTTP"
  vpc_id      = local.shared.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = var.health_check_path
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = local.shared.https_listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

resource "aws_route53_record" "this" {
  zone_id = var.route53_zone_id
  name    = var.host_header
  type    = "A"

  alias {
    name                   = local.shared.alb_dns_name
    zone_id                = local.shared.alb_zone_id
    evaluate_target_health = true
  }
}
