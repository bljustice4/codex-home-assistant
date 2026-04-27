#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

require_cmd rsync

if [[ ! -d "${LOCAL_CONFIG_DIR}" ]]; then
  echo "Local config directory not found: ${LOCAL_CONFIG_DIR}" >&2
  exit 1
fi

mapfile -t EXCLUDES < <(rsync_exclude_args)

echo "Deploying ${LOCAL_CONFIG_DIR}/ -> ${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/"
rsync -avz --delete \
  -e "ssh -p ${HA_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=8" \
  "${EXCLUDES[@]}" \
  "${LOCAL_CONFIG_DIR}/" \
  "${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/"

echo "Deploy complete. Run targeted reloads or restart only if required."
