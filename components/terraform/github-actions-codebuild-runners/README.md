# github-actions-codebuild-runners

Terraform module that provisions AWS CodeBuild managed GitHub Actions runner projects and webhooks for ephemeral, on-demand Linux CI jobs.

## What it creates

- one CodeBuild project per repository target
- one CodeBuild webhook per project (`WORKFLOW_JOB_QUEUED`)
- one IAM service role + inline policy per project
- one CloudWatch log group per project
- optional queue/build duration alarms per project

## Notes

- CodeBuild still requires account-level GitHub source credentials/connection in AWS.
- Workflow jobs must target labels in this format:
  - `codebuild-<project-name>-${{ github.run_id }}-${{ github.run_attempt }}`
