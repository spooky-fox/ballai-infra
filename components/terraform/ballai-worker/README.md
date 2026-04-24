# ballai-worker

Placeholder module for the Ballai Cloudflare Worker stack.

## Intended mapping (from Wrangler)

| Wrangler | Terraform (to add) |
|----------|-------------------|
| `ballai-api` worker | `cloudflare_workers_script` / Worker resources per provider docs |
| KV `TOOL_CACHE` | KV namespace + binding |
| Durable Object `ToolChainSession` | DO namespace + migration alignment |
| D1 `ballai-travel` | D1 database + binding |
| Cron `0 6 * * *` | Worker cron trigger resource |

## Inputs

See `variables.tf`. Values are passed from `environments/prod`.

## Outputs

`summary` — temporary scaffold string until real outputs exist.
