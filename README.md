# ballai-infra

Terraform for [Ballai](https://github.com/spooky-fox/Ballai) and related Cloudflare infrastructure, including a migrated root module for **[lanzo-web](https://github.com/spooky-fox/lanzo-web)** (zone, Pages, DNS, email routing).

## Migration status

| Area | Status |
|------|--------|
| Ballai Worker / KV / D1 / Durable Objects | **Scaffold** — `modules/ballai-worker/` is a placeholder until Wrangler resources are mapped |
| **lanzo-web** (Cloudflare zone, Pages, DNS, email routing) | **Migrated** — root module at `environments/prod/lanzo-web/` (was `lanzo-web/infra/`). Provider **`cloudflare` ~> 5.x** in that directory (Ballai prod remains ~> 4.x until upgraded). |
| Remote state | **Configured** on S3 bucket `terraform-spookyfox` with separate keys: `shared/ballai/prod/terraform.tfstate` and `shared/lanzo-web/prod/terraform.tfstate`. |

## Prerequisites

- Terraform `>= 1.5`
- Cloudflare API token with permissions for planned resources (GitHub Actions: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` as `TF_VAR_cloudflare_account_id` where used)
- Remote state: use `environments/prod/backend.tf.example` and `environments/prod/lanzo-web/backend.tf.example` as templates — **do not commit** secrets

## Layout

```text
environments/prod/              # Ballai production root module (cloudflare ~> 4.x)
modules/ballai-worker/          # Reusable module (placeholder)
modules/github-actions-codebuild-runners/ # AWS CodeBuild managed GitHub Actions runners
environments/prod/lanzo-web/    # lanzo.app / Pages / DNS / email routing (cloudflare ~> 5.x)
ansible/                        # macOS self-hosted GitHub runner; ansible-core 2.20+ via `uv sync` in ansible/ (see ansible/README.md)
```

## Next steps

1. Map Ballai Wrangler resources to `modules/ballai-worker/` when ready.
2. Keep `lanzo-web/infra/` retired and manage lanzo only from `environments/prod/lanzo-web/`.
3. Run `terraform fmt`, `terraform validate`, and `terraform plan` from each root directory before apply.

## CI

- **Pull requests:** quality battery (`pre-commit` hooks for fmt/validate/tflint/provider lock) plus matrix init/validate checks for `environments/prod` and `environments/prod/lanzo-web` (`.github/workflows/terraform-pr.yml`).
- **`main` branch:** apply for **each** matrix workspace that has `backend.tf`, using the **`production`** GitHub Environment.
- Apply workflow now enforces a preflight guard that blocks destructive plans unless the active AWS account is allowlisted (`TERRAFORM_DESTRUCTIVE_ALLOWLIST`).

## AWS GitHub Runners (On-Demand)

This repo now provisions AWS CodeBuild managed, ephemeral GitHub Actions runners for:

- `spooky-fox/ballai`
- `spooky-fox/ballai-infra`
- `spooky-fox/lanzo-web`

Runner project names are built from:

- `ballai-gha-ballai`
- `ballai-gha-ballai-infra`
- `ballai-gha-lanzo-web`

Workflows target these with:

- `runs-on: codebuild-<project-name>-${{ github.run_id }}-${{ github.run_attempt }}`
- Repos can bootstrap safely with `USE_CODEBUILD_RUNNERS=false` (default fallback to `ubuntu-latest`) and then flip to `true` after runner projects are ready.

Important prerequisite: AWS account-level CodeBuild GitHub source credentials/connection must exist, or webhook/project setup will not be usable at runtime.

### Observe and tune policy

- Start with on-demand ephemeral only (no warm pool).
- Monitor p95 `QueuedDuration` and p95 `Duration` alarms per runner project.
- Consider daytime pre-warming only if queue latency remains high during working hours for at least one week.

## Terraform Quality Battery

This repo uses community-standard Terraform hooks via [`pre-commit-terraform`](https://github.com/antonbabenko/pre-commit-terraform):

- `terraform_fmt`
- `terraform_validate`
- `terraform_tflint`
- `terraform_providers_lock` (linux + macOS lock targets)

Run locally:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Related

- Application repos: [Ballai](https://github.com/spooky-fox/Ballai), [lanzo-web](https://github.com/spooky-fox/lanzo-web) (Terraform removed from `lanzo-web/infra/` in favor of this repo).
