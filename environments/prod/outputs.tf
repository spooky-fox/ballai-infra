output "ballai_worker_summary" {
  description = "Module scaffold status string."
  value       = module.ballai_worker.summary
}

output "github_actions_runner_projects" {
  description = "CodeBuild project names for GitHub Actions runner projects."
  value       = try(module.github_actions_runners[0].project_names, {})
}

output "github_actions_runs_on_labels" {
  description = "runs-on labels for CodeBuild-managed GitHub Actions runners."
  value       = try(module.github_actions_runners[0].workflow_runs_on_labels, {})
}

output "worker_oidc_role_arn" {
  description = "IAM role ARN for the Worker to assume via OIDC. Set as BEDROCK_ROLE_ARN in wrangler.toml."
  value       = module.worker_oidc.role_arn
}

output "worker_oidc_provider_arn" {
  description = "ARN of the OIDC identity provider registered for the Worker."
  value       = module.worker_oidc.oidc_provider_arn
}
