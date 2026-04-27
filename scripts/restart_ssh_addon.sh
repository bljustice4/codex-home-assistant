#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

"${SCRIPT_DIR}/ha_api.py" restart-addon "${HA_SSH_ADDON_SLUG:-core_ssh}"
