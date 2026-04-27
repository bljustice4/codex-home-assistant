#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

BACKUP_NAME="codex-predeploy-$(date +%Y%m%d-%H%M%S)"

echo "Creating Home Assistant backup: ${BACKUP_NAME}"
ssh_base "ha backups new --name '${BACKUP_NAME}'"
