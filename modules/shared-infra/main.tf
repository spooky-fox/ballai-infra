data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# ──── VPC ────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = var.name
    Project   = var.name
    Layer     = "shared"
    ManagedBy = "terraform"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = var.name
    Project   = var.name
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index].cidr
  availability_zone = var.public_subnets[count.index].az

  tags = {
    Name    = "${var.name}-public-${var.public_subnets[count.index].az}"
    Project = var.name
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].az

  tags = {
    Name    = "${var.name}-private-${var.private_subnets[count.index].az}"
    Project = var.name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.name}-public"
    Project = var.name
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.name}-private-${var.private_subnets[count.index].az}"
    Project = var.name
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags = {
    Name      = var.name
    ManagedBy = "terraform"
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = {
    Name      = var.name
    ManagedBy = "terraform"
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = var.name
    ManagedBy = "terraform"
  }
}

# ──── ACM ────

resource "aws_acm_certificate" "this" {
  domain_name               = var.acm_domain
  subject_alternative_names = var.acm_san
  validation_method         = "DNS"

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  count = length(aws_acm_certificate.this.domain_validation_options) > 0 ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
  zone_id         = var.route53_zone_id
  records         = [tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = aws_route53_record.acm_validation[*].fqdn
}

# ──── ALB ────

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-"
  description = "Security group for ${var.name} application load balancer"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name      = var.name
    Project   = var.name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"not_found\"}"
      status_code  = "404"
    }
  }
}

# ──── ECS Cluster ────

resource "aws_ecs_cluster" "main" {
  name = var.name

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

# ──── ECS Security Groups ────

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "ecs-tasks-"
  description = "ECS Fargate tasks"
  vpc_id      = aws_vpc.this.id

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
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_to_ecs_6006" {
  type                     = "ingress"
  from_port                = 6006
  to_port                  = 6006
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.alb.id
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

# ──── Neo4j ────

resource "aws_security_group" "neo4j" {
  name_prefix = "neo4j-"
  description = "Neo4j graph database"
  vpc_id      = aws_vpc.this.id

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
  subnet_id              = aws_subnet.private[0].id
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

# ──── SSM Parameters ────

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
