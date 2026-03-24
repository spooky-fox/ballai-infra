#!/usr/bin/env bash
# Fetch sudo/become password from AWS Secrets Manager into ansible/.pw (gitignored).
#
# Prereqs: AWS CLI, credentials (e.g. repo-root .env per ballai-infra AGENTS.md).
#
# Usage:
#   export BALLAI_ANSIBLE_BECOME_SECRET_ID=arn:aws:secretsmanager:...:secret:...  # or secret name
#   # Optional: secret is JSON and password is one key:
#   # export BALLAI_ANSIBLE_BECOME_SECRET_JSON_KEY=become_password
#   ./scripts/sync_ansible_secrets_from_aws.sh
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ANSIBLE_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env"
  set +a
fi
unset AWS_PROFILE AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE || true

: "${BALLAI_ANSIBLE_BECOME_SECRET_ID:?Set BALLAI_ANSIBLE_BECOME_SECRET_ID (Secrets Manager name or ARN)}"

RAW="$(aws secretsmanager get-secret-value \
  --secret-id "$BALLAI_ANSIBLE_BECOME_SECRET_ID" \
  --query SecretString \
  --output text)"

if [[ -n "${BALLAI_ANSIBLE_BECOME_SECRET_JSON_KEY:-}" ]]; then
  VALUE="$(RAW="$RAW" KEY="$BALLAI_ANSIBLE_BECOME_SECRET_JSON_KEY" python3 -c "
import json, os, sys
raw = os.environ['RAW']
key = os.environ['KEY']
val = json.loads(raw)[key]
sys.stdout.write(val if isinstance(val, str) else str(val))
")"
else
  VALUE="$RAW"
fi

umask 077
printf '%s' "$VALUE" >"$ANSIBLE_DIR/.pw"
chmod 600 "$ANSIBLE_DIR/.pw"
echo "Wrote $ANSIBLE_DIR/.pw"
