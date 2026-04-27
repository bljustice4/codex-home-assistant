#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is dirty. Commit or stash changes before rollback." >&2
  exit 1
fi

echo "Switching to main"
git switch main

echo "Fast-forwarding main from origin"
git fetch origin main
git pull --ff-only origin main

scripts/preflight.sh --live
scripts/backup_ha.sh
scripts/deploy_config.sh

if [[ "${HA_DEPLOY_RUN_CHECK_CONFIG:-0}" == "1" ]]; then
  scripts/check_config.sh
fi

if [[ "$#" -gt 0 ]]; then
  for domain in "$@"; do
    scripts/reload_ha.sh "${domain}"
  done
else
  echo "No reload targets supplied. Run scripts/reload_ha.sh <domain> or restart HA if required."
fi

echo "Rollback deploy complete: main"
