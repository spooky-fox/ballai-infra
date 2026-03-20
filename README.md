# ballai-infra

Terraform scaffold for migrating [Ballai](https://github.com/spooky-fox/Ballai) Cloudflare infrastructure from **Wrangler** (`backend/wrangler.toml`) to Terraform.

## Migration status

| Area | Status |
|------|--------|
| This repo (Terraform scaffold) | Initial structure in place |
| Worker / KV / D1 / Durable Objects | **Not yet defined in Terraform** — module is a placeholder |
| **Ballai website / app repo split** | **Pending confirmation** — no assumptions made about moving the application repository; coordinate before any repo or deploy pipeline changes |

## Prerequisites

- Terraform `>= 1.5`
- Cloudflare API token with permissions appropriate for planned resources (store in GitHub Actions secrets for CI)
- Remote state: copy `environments/prod/backend.tf.example` to `backend.tf`, fill in real values, and **do not commit** secrets

## Layout

```text
environments/prod/   # Production root module
modules/ballai-worker/ # Reusable module (empty of resources until design is finalized)
```

## Next steps

1. Confirm **remote backend** (S3, GCS, Terraform Cloud, etc.) and add `environments/prod/backend.tf` (see `backend.tf.example`).
2. Map current Wrangler resources (Worker, KV `TOOL_CACHE`, D1 `ballai-travel`, Durable Object `ToolChainSession`, cron triggers) to `cloudflare_*` resources in `modules/ballai-worker/`.
3. Add `terraform.tfvars` locally (gitignored) or use CI/CD variables — **never commit real tokens or private keys**.
4. Wire GitHub Actions secrets: `CLOUDFLARE_API_TOKEN`, and any `TF_VAR_*` or account IDs your root module expects.
5. Run `terraform fmt`, `terraform validate`, and `terraform plan` from `environments/prod` before the first apply.

## CI

- **Pull requests:** format check, validate, and plan (`.github/workflows/terraform-pr.yml`).
- **`main` branch:** apply with the **`production`** GitHub Environment (configure protection rules + required secrets in repo settings).

## Related

- Application repo: Ballai (Wrangler config today: `backend/wrangler.toml`).
