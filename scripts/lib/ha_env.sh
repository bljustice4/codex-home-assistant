#!/usr/bin/env bash
set -euo pipefail

HA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${HA_LIB_DIR}/../.." && pwd)"

if [[ -f "${PROJECT_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${PROJECT_ROOT}/.env"
  set +a
fi

HA_URL="${HA_URL:-http://homeassistant.local:8123}"
HA_CONFIG_DIR="${HA_CONFIG_DIR:-config}"
HA_REMOTE_CONFIG_DIR="${HA_REMOTE_CONFIG_DIR:-/config}"
HA_SSH_TARGET="${HA_SSH_TARGET:-homeassistant.local}"
HA_SSH_PORT="${HA_SSH_PORT:-22}"
HA_CHECK_CONFIG_COMMAND="${HA_CHECK_CONFIG_COMMAND:-ha core check --no-progress}"
HA_CHECK_TIMEOUT_SECONDS="${HA_CHECK_TIMEOUT_SECONDS:-300}"
HA_RSYNC_EXCLUDES="${HA_RSYNC_EXCLUDES:-secrets.yaml .storage home-assistant_v2.db* home-assistant.log* deps tts backups *.tar *.tar.gz}"

LOCAL_CONFIG_DIR="${PROJECT_ROOT}/${HA_CONFIG_DIR}"
LOCAL_WORK_DIR="${PROJECT_ROOT}/.local"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 127
  fi
}

ssh_base() {
  ssh -p "${HA_SSH_PORT}" -o BatchMode=yes -o ConnectTimeout=8 "${HA_SSH_TARGET}" "$@"
}

tar_exclude_args() {
  local item
  for item in ${HA_RSYNC_EXCLUDES}; do
    printf -- "--exclude=%s\n" "${item}"
  done
}
