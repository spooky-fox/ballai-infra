data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = [for s in var.public_subnets : s.az]
  public_subnets  = [for s in var.public_subnets : s.cidr]
  private_subnets = [for s in var.private_subnets : s.cidr]

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnet_tags = {
    Project = var.name
  }

  private_subnet_tags = {
    Project = var.name
  }

  tags = {
    Project   = var.name
    Layer     = "shared"
    ManagedBy = "terraform"
  }
}

resource "aws_ecs_cluster" "main" {
  name = var.name

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name               = var.acm_domain
  subject_alternative_names = var.acm_san
  zone_id                   = var.route53_zone_id
  validation_method         = "DNS"
  wait_for_validation       = true

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"
  internal           = false

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not Found"
          status_code  = "404"
        }
      }
    }
  }

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "ecs-tasks-"
  description = "ECS Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_to_ecs_8000" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "alb_to_ecs_6006" {
  type                     = "ingress"
  from_port                = 6006
  to_port                  = 6006
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "ecs_to_ecs" {
  type                     = "ingress"
  from_port                = 4317
  to_port                  = 4317
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_security_group_rule" "ecs_to_neo4j" {
  type                     = "ingress"
  from_port                = 7687
  to_port                  = 7687
  protocol                 = "tcp"
  security_group_id        = aws_security_group.neo4j.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_security_group" "neo4j" {
  name_prefix = "neo4j-"
  description = "Neo4j graph database"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "neo4j" {
  name_prefix = "neo4j-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "neo4j_ssm" {
  role       = aws_iam_role.neo4j.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "neo4j" {
  name_prefix = "neo4j-"
  role        = aws_iam_role.neo4j.name
}

resource "aws_instance" "neo4j" {
  ami                    = var.neo4j_ami
  instance_type          = var.neo4j_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.neo4j.name
  vpc_security_group_ids = [aws_security_group.neo4j.id]

  root_block_device {
    volume_size           = var.neo4j_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = false
  }

  tags = {
    Name      = "neo4j"
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "neo4j_recovery" {
  alarm_name          = "neo4j-auto-recovery"
  alarm_description   = "Auto-recover Neo4j instance on system status check failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = ["arn:aws:automate:us-west-2:ec2:recover"]

  dimensions = {
    InstanceId = aws_instance.neo4j.id
  }
}

data "aws_iam_policy_document" "dlm_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name_prefix        = "dlm-neo4j-"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume.json
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "neo4j_snapshots" {
  description        = "Daily EBS snapshots for Neo4j volume"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Name = "neo4j"
    }

    schedule {
      name = "daily"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["09:00"]
      }

      retain_rule {
        count = 7
      }

      copy_tags = true
    }
  }
}

resource "aws_ssm_parameter" "neo4j_password" {
  name  = "/spookyfox/shared/neo4j-password"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "together_api_key" {
  name  = "/spookyfox/shared/together-api-key"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "mcp_auth_token" {
  name  = "/spookyfox/services/agent-memory/mcp-auth-token"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "phoenix_secret" {
  name  = "/spookyfox/services/phoenix/secret"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "phoenix_admin_password" {
  name  = "/spookyfox/services/phoenix/admin-password"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "phoenix_api_key" {
  name  = "/spookyfox/services/phoenix/api-key"
  type  = "SecureString"
  value = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [value]
  }
}
