#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

require_cmd tar

if [[ ! -d "${LOCAL_CONFIG_DIR}" ]]; then
  echo "Local config directory not found: ${LOCAL_CONFIG_DIR}" >&2
  exit 1
fi

EXCLUDES=()
while IFS= read -r exclude; do
  EXCLUDES+=("${exclude}")
done < <(tar_exclude_args)

echo "Deploying ${LOCAL_CONFIG_DIR}/ -> ${HA_SSH_TARGET}:${HA_REMOTE_CONFIG_DIR}/"
tar -cf - -C "${LOCAL_CONFIG_DIR}" "${EXCLUDES[@]}" . | ssh_base "cd '${HA_REMOTE_CONFIG_DIR}' && tar -xf -"

echo "Deploy complete. Run targeted reloads or restart only if required."
