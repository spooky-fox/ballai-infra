#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "check-plan" ]; then
  echo "Usage: $0 check-plan <plan-file>"
  exit 1
fi

PLAN_FILE="${2:-}"
if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "Plan file not found: ${PLAN_FILE:-<empty>}"
  exit 1
fi

ALLOWLIST="${TERRAFORM_DESTRUCTIVE_ALLOWLIST:-339713066518}"
ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text)"

HAS_DESTRUCTIVE="$(terraform show -json "$PLAN_FILE" | python3 - <<'PY'
import json, sys
plan = json.load(sys.stdin)
changes = plan.get("resource_changes", [])
destructive = False
for rc in changes:
    actions = rc.get("change", {}).get("actions", [])
    if "delete" in actions:
        destructive = True
        break
print("true" if destructive else "false")
PY
)"

if [ "$HAS_DESTRUCTIVE" != "true" ]; then
  echo "Preflight OK: no destructive Terraform actions."
  exit 0
fi

for allowed in $ALLOWLIST; do
  if [ "$ACCOUNT_ID" = "$allowed" ]; then
    echo "Preflight OK: destructive Terraform actions allowed in account $ACCOUNT_ID."
    exit 0
  fi
done

echo "Preflight BLOCKED: destructive Terraform actions detected."
echo "Current AWS account: $ACCOUNT_ID"
echo "Allowed accounts: $ALLOWLIST"
exit 1
