# github-actions-codebuild-runners

Terraform module that provisions AWS CodeBuild managed GitHub Actions runner projects and webhooks for ephemeral, on-demand CI jobs (Linux and Windows today; macOS/`MAC_ARM` when you supply a valid image and compute per AWS docs).

## What it creates

- one CodeBuild project per map entry (same GitHub repo may appear under multiple keys for backup or OS-specific pools)
- one CodeBuild webhook per project (`WORKFLOW_JOB_QUEUED`)
- one IAM service role + inline policy per project
- one CloudWatch log group per project
- optional queue/build duration alarms per project

## Notes

- CodeBuild still requires account-level GitHub source credentials/connection in AWS.
- Workflow jobs must target labels in this format:
  - `codebuild-<project-name>-${{ github.run_id }}-${{ github.run_attempt }}`
- **Backup pools:** add another map entry with the same `repository_name` but a different key (e.g. `ballai-backup`) so GitHub receives a second `runs-on` label without replacing the primary project.
- **macOS:** general CodeBuild supports `MAC_ARM` in select regions; managed GitHub Actions runner *documented* images have historically been Linux/Windows-heavy—confirm the current [supported images](https://docs.aws.amazon.com/codebuild/latest/userguide/sample-github-action-runners-update-yaml.images.html) and [compute types](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html) before setting `environment` / `image` / `compute_type` in Terraform.
