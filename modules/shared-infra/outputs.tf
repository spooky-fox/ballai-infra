output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "neo4j_instance_id" {
  value = aws_instance.neo4j.id
}

output "neo4j_private_ip" {
  value = aws_instance.neo4j.private_ip
}
