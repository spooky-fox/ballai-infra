# ballai-infra

Terraform for [Ballai](https://github.com/spooky-fox/Ballai) and related Cloudflare infrastructure, including a migrated root module for **[lanzo-web](https://github.com/spooky-fox/lanzo-web)** (zone, Pages, DNS, email routing).

## Migration status

| Area | Status |
|------|--------|
| Ballai Worker / KV / D1 / Durable Objects | **Scaffold** — `modules/ballai-worker/` is a placeholder until Wrangler resources are mapped |
| **lanzo-web** (Cloudflare zone, Pages, DNS, email routing) | **Migrated** — root module at `environments/prod/lanzo-web/` (was `lanzo-web/infra/`). Provider **`cloudflare` ~> 5.x** in that directory (Ballai prod remains ~> 4.x until upgraded). |
| Remote state | Per root module: copy `backend.tf.example` → `backend.tf` in each environment you apply (**separate state keys** for Ballai vs lanzo-web). |

## Prerequisites

- Terraform `>= 1.5`
- Cloudflare API token with permissions for planned resources (GitHub Actions: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` as `TF_VAR_cloudflare_account_id` where used)
- Remote state: use `environments/prod/backend.tf.example` and `environments/prod/lanzo-web/backend.tf.example` as templates — **do not commit** secrets

## Layout

```text
environments/prod/              # Ballai production root module (cloudflare ~> 4.x)
modules/ballai-worker/          # Reusable module (placeholder)
environments/prod/lanzo-web/    # lanzo.app / Pages / DNS / email routing (cloudflare ~> 5.x)
```

## Next steps

1. Add `backend.tf` per root module (distinct state keys; see `backend.tf.example` files).
2. **State migration:** If lanzo Terraform state lived only in `lanzo-web`, move it to the remote backend for `environments/prod/lanzo-web/` using your usual process (`terraform state pull` / `push`, or migrate backend) before relying on CI apply — **do not duplicate applies** against two state files.
3. Map Ballai Wrangler resources to `modules/ballai-worker/` when ready.
4. Run `terraform fmt`, `terraform validate`, and `terraform plan` from each root directory before apply.

## CI

- **Pull requests:** format check (repo-wide recursive), then **matrix**: `environments/prod` and `environments/prod/lanzo-web` — init, validate, plan (`.github/workflows/terraform-pr.yml`).
- **`main` branch:** apply for **each** matrix workspace that has `backend.tf`, using the **`production`** GitHub Environment.

## Related

- Application repos: [Ballai](https://github.com/spooky-fox/Ballai), [lanzo-web](https://github.com/spooky-fox/lanzo-web) (Terraform removed from `lanzo-web/infra/` in favor of this repo).
