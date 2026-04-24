# environments/prod/ — Legacy Terraform Path

This directory is the **legacy** infrastructure management path. It is used by
CI (GitHub Actions) which runs `terraform plan` and `terraform apply` directly
against these files.

## Managed components

| Component                          | Module source                                           |
|------------------------------------|---------------------------------------------------------|
| `ballai-worker`                    | `../../components/terraform/ballai-worker`              |
| `worker-oidc-federation`           | `../../components/terraform/worker-oidc-federation`     |
| `github-actions-codebuild-runners` | `../../components/terraform/github-actions-codebuild-runners` |

## State

- **Main**: `s3://terraform-spookyfox/shared/ballai/prod/terraform.tfstate`
- **lanzo-web**: `s3://terraform-spookyfox/shared/lanzo-web/prod/terraform.tfstate`

## Migration to Atmos

These components will be migrated to Atmos (`stacks/` + `components/terraform/`)
once CI is updated to use `atmos terraform plan/apply`. See issue #27 for
tracking. Until then, do **not** declare these components in any Atmos stack
file — that would create split-brain dual management.

Compute-only components (`shared-infra`, `service-agent-memory`,
`service-phoenix`) are already managed exclusively via Atmos.
