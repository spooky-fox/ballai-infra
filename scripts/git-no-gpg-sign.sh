#!/usr/bin/env sh
# Run once per clone (repo-local): avoid GPG signing / pinentry in CI and automation.
set -e
cd "$(dirname "$0")/.."
git config commit.gpgsign false
echo "Set commit.gpgsign=false for $(pwd) (.git/config)"
