output "project_names" {
  description = "CodeBuild project names keyed by repo key."
  value = {
    for key, project in aws_codebuild_project.runner :
    key => project.name
  }
}

output "workflow_runs_on_labels" {
  description = "GitHub Actions runs-on labels to target each CodeBuild runner project."
  value = {
    for key, project in aws_codebuild_project.runner :
    key => "codebuild-${project.name}-$${{ github.run_id }}-$${{ github.run_attempt }}"
  }
}
