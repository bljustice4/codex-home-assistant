#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

require_cmd curl

echo "Checking Home Assistant HTTP: ${HA_URL}"
HTTP_STATUS="$(curl --silent --show-error --output /dev/null --write-out "%{http_code}" --max-time 8 "${HA_URL}/api/")"
case "${HTTP_STATUS}" in
  200|401)
    echo "HTTP reachable (${HTTP_STATUS})"
    ;;
  *)
    echo "Unexpected HTTP status from ${HA_URL}/api/: ${HTTP_STATUS}" >&2
    exit 1
    ;;
esac

if [[ -n "${HA_TOKEN:-}" ]]; then
  echo "Checking authenticated REST API"
  curl --fail --silent --show-error --max-time 8 \
    -H "Authorization: Bearer ${HA_TOKEN}" \
    -H "Content-Type: application/json" \
    "${HA_URL}/api/config" >/dev/null
  echo "Authenticated REST OK"
else
  echo "HA_TOKEN is not set; skipping authenticated REST check"
fi

echo "Checking SSH: ${HA_SSH_TARGET}:${HA_SSH_PORT}"
if ssh_base "test -d '${HA_REMOTE_CONFIG_DIR}'"; then
  echo "SSH OK"
else
  echo "SSH check failed. Set HA_SSH_TARGET/HA_SSH_PORT in .env after exposing the Terminal & SSH add-on." >&2
  exit 2
fi
