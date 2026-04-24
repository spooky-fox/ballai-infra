# Worker OIDC Federation

Registers a Cloudflare Worker as an OIDC identity provider in AWS IAM and
creates a scoped IAM role the Worker can assume via `sts:AssumeRoleWithWebIdentity`.

## How it works

1. The Worker serves `/.well-known/openid-configuration` and `/jwks` endpoints.
2. AWS IAM trusts the Worker URL as an OIDC provider.
3. At runtime the Worker signs a short-lived JWT (ES256, 5-min TTL) with a
   stored EC private key, then calls `AssumeRoleWithWebIdentity` to get
   temporary AWS credentials (1-hour TTL).
4. The temporary credentials are scoped to `bedrock:InvokeModel` on the
   configured model ARNs.

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `worker_url` | HTTPS URL of the Worker | required |
| `worker_subject` | JWT `sub` claim value | `"ballai-worker"` |
| `role_name` | IAM role name | `"ballai-worker-bedrock"` |
| `bedrock_model_arns` | Bedrock model/profile ARNs | Cohere Embed v4 + Rerank 3.5 |
| `max_session_duration` | Max role session (seconds) | `3600` |
| `tags` | Resource tags | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | ARN of the OIDC provider |
| `role_arn` | ARN of the IAM role (use as `BEDROCK_ROLE_ARN` in the Worker) |
| `role_name` | Name of the IAM role |
