#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

echo "Running Home Assistant config check on ${HA_SSH_TARGET}:${HA_SSH_PORT}"
ssh_base "${HA_CHECK_CONFIG_COMMAND}"
