#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

require_cmd tar

mkdir -p "${LOCAL_CONFIG_DIR}"

EXCLUDES=()
while IFS= read -r exclude; do
  EXCLUDES+=("${exclude}")
done < <(tar_exclude_args)

echo "Pulling ${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/ -> ${LOCAL_CONFIG_DIR}/"
find "${LOCAL_CONFIG_DIR}" -mindepth 1 -maxdepth 1 ! -name README.md -exec rm -rf {} +
ssh_base "cd '${HA_REMOTE_CONFIG_DIR}' && tar -cf - ${EXCLUDES[*]} ." | tar -xf - -C "${LOCAL_CONFIG_DIR}"

echo "Config pull complete"
