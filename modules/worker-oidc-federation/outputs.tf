output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC identity provider."
  value       = aws_iam_openid_connect_provider.worker.arn
}

output "role_arn" {
  description = "ARN of the IAM role the Worker assumes via OIDC federation."
  value       = aws_iam_role.worker_bedrock.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.worker_bedrock.name
}
