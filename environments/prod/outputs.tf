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
