#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

echo "Running Home Assistant config check on ${HA_SSH_TARGET}:${HA_SSH_PORT}"
ssh_base "${HA_CHECK_CONFIG_COMMAND}" &
CHECK_PID="$!"
STARTED_AT="$(date +%s)"

while kill -0 "${CHECK_PID}" >/dev/null 2>&1; do
  NOW="$(date +%s)"
  if (( NOW - STARTED_AT > HA_CHECK_TIMEOUT_SECONDS )); then
    kill "${CHECK_PID}" >/dev/null 2>&1 || true
    echo "Home Assistant config check timed out after ${HA_CHECK_TIMEOUT_SECONDS}s" >&2
    exit 124
  fi
  sleep 2
done

wait "${CHECK_PID}"
