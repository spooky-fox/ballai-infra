moved {
  from = module.vpc.aws_vpc.this[0]
  to   = aws_vpc.this
}

moved {
  from = module.vpc.aws_internet_gateway.this[0]
  to   = aws_internet_gateway.this
}

moved {
  from = module.vpc.aws_subnet.public[0]
  to   = aws_subnet.public[0]
}

moved {
  from = module.vpc.aws_subnet.public[1]
  to   = aws_subnet.public[1]
}

moved {
  from = module.vpc.aws_subnet.private[0]
  to   = aws_subnet.private[0]
}

moved {
  from = module.vpc.aws_route_table.public[0]
  to   = aws_route_table.public
}

moved {
  from = module.vpc.aws_route.public_internet_gateway[0]
  to   = aws_route.public_internet_gateway
}

moved {
  from = module.vpc.aws_route_table_association.public[0]
  to   = aws_route_table_association.public[0]
}

moved {
  from = module.vpc.aws_route_table_association.public[1]
  to   = aws_route_table_association.public[1]
}

moved {
  from = module.vpc.aws_route_table.private[0]
  to   = aws_route_table.private[0]
}

moved {
  from = module.vpc.aws_route_table.private[1]
  to   = aws_route_table.private[1]
}

moved {
  from = module.vpc.aws_route_table_association.private[0]
  to   = aws_route_table_association.private[0]
}

moved {
  from = module.vpc.aws_default_network_acl.this[0]
  to   = aws_default_network_acl.this
}

moved {
  from = module.vpc.aws_default_route_table.default[0]
  to   = aws_default_route_table.default
}

moved {
  from = module.vpc.aws_default_security_group.this[0]
  to   = aws_default_security_group.this
}

moved {
  from = module.acm.aws_acm_certificate.this[0]
  to   = aws_acm_certificate.this
}

moved {
  from = module.acm.aws_acm_certificate_validation.this[0]
  to   = aws_acm_certificate_validation.this
}

moved {
  from = module.alb.aws_lb.this[0]
  to   = aws_lb.this
}

moved {
  from = module.alb.aws_lb_listener.this["http_redirect"]
  to   = aws_lb_listener.http_redirect
}

moved {
  from = module.alb.aws_lb_listener.this["https"]
  to   = aws_lb_listener.https
}

moved {
  from = module.alb.aws_security_group.this[0]
  to   = aws_security_group.alb
}

moved {
  from = module.alb.aws_vpc_security_group_ingress_rule.this["all_http"]
  to   = aws_vpc_security_group_ingress_rule.alb_http
}

moved {
  from = module.alb.aws_vpc_security_group_ingress_rule.this["all_https"]
  to   = aws_vpc_security_group_ingress_rule.alb_https
}

moved {
  from = module.alb.aws_vpc_security_group_egress_rule.this["all"]
  to   = aws_vpc_security_group_egress_rule.alb_all
}

moved {
  from = module.acm.aws_route53_record.validation[0]
  to   = aws_route53_record.acm_validation[0]
}
