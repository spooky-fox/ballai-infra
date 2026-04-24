## AWS Auth

- Source repo `.env` before AWS commands:
  - `set -a && source .env && set +a`
- Always clear profile-based config:
  - `unset AWS_PROFILE AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE`
- Verify identity before writes:
  - `aws sts get-caller-identity`
- Do not use named AWS profiles unless explicitly requested by the user.

## Terraform Safety

- Before Terraform apply, create a plan and run preflight:
  - `terraform plan -out=tfplan`
  - `scripts/terraform-preflight.sh check-plan tfplan`
- Destructive actions are blocked unless AWS account is allowlisted via:
  - `TERRAFORM_DESTRUCTIVE_ALLOWLIST="339713066518"`

## Component Ownership (issue #27)

Infrastructure is split across two management paths during migration:

### Legacy path — `environments/prod/`

Managed by **CI (GitHub Actions)** via `terraform plan/apply`.
State: `s3://terraform-spookyfox/shared/ballai/prod/terraform.tfstate`

| Component                        | Description                      |
|----------------------------------|----------------------------------|
| `ballai-worker`                  | Cloudflare Worker secrets        |
| `worker-oidc-federation`         | AWS OIDC for Bedrock access      |
| `github-actions-codebuild-runners` | CodeBuild-backed GHA runners  |

The `environments/prod/lanzo-web/` subdirectory manages Cloudflare Pages for lanzo.app
with its own state at `shared/lanzo-web/prod/terraform.tfstate`.

### Atmos path — `stacks/` + `components/terraform/`

Managed **locally** via `atmos terraform plan/apply`.

| Component              | Description                          |
|------------------------|--------------------------------------|
| `shared-infra`         | Shared networking / base resources   |
| `service-agent-memory` | Agent memory service infrastructure  |
| `service-phoenix`      | Phoenix service infrastructure       |

### Migration plan

Once CI is migrated to Atmos, the legacy components will move into
`stacks/orgs/spookyfox/plat/usw2/prod.yaml` and the `environments/` directory
will be removed. Do **not** declare legacy-path components in Atmos stacks
until that migration is complete.
