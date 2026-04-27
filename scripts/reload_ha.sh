#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

DOMAIN="${1:-}"

if [[ -z "${DOMAIN}" ]]; then
  echo "Usage: scripts/reload_ha.sh <core|automations|scripts|scenes|template|groups|input_boolean|input_number|input_select|input_text>" >&2
  exit 64
fi

python3 "${SCRIPT_DIR}/ha_api.py" reload "${DOMAIN}"
