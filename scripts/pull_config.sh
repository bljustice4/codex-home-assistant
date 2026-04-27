#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

require_cmd rsync

mkdir -p "${LOCAL_CONFIG_DIR}"

mapfile -t EXCLUDES < <(rsync_exclude_args)

echo "Pulling ${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/ -> ${LOCAL_CONFIG_DIR}/"
rsync -avz --delete \
  -e "ssh -p ${HA_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=8" \
  "${EXCLUDES[@]}" \
  "${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/" \
  "${LOCAL_CONFIG_DIR}/"

echo "Config pull complete"
