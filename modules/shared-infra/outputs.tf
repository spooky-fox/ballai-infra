output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "alb_arn" {
  value = module.alb.arn
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "alb_zone_id" {
  value = module.alb.zone_id
}

output "https_listener_arn" {
  value = module.alb.listeners["https"].arn
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "acm_certificate_arn" {
  value = module.acm.acm_certificate_arn
}

output "neo4j_instance_id" {
  value = aws_instance.neo4j.id
}

output "neo4j_private_ip" {
  value = aws_instance.neo4j.private_ip
}
