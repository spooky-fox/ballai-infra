#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".env" ]; then
  echo ".env not found in repo root"
  exit 1
fi

set -a
source .env
set +a

unset AWS_PROFILE AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE

aws sts get-caller-identity
