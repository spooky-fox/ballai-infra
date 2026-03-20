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
