#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE="static"
if [[ "${1:-}" == "--live" ]]; then
  MODE="live"
elif [[ "${1:-}" == "--full" ]]; then
  MODE="full"
elif [[ "${1:-}" == "--static" || -z "${1:-}" ]]; then
  MODE="static"
else
  echo "Usage: scripts/preflight.sh [--static|--live|--full]" >&2
  exit 64
fi

cd "${PROJECT_ROOT}"

if [[ -x ".venv/bin/python" ]]; then
  PYTHON="${PYTHON:-.venv/bin/python}"
else
  PYTHON="${PYTHON:-python3}"
fi

echo "Checking shell syntax"
find scripts -name "*.sh" -print0 | xargs -0 bash -n

echo "Checking Python syntax"
"${PYTHON}" -m py_compile scripts/ha_api.py scripts/validate_yaml.py

echo "Checking YAML syntax"
"${PYTHON}" scripts/validate_yaml.py

echo "Checking sensitive tracked paths"
SENSITIVE_TRACKED="$(
  git ls-files \
    .env \
    .env.local \
    .local \
    backups \
    config/secrets.yaml \
    config/.storage \
    "config/*db*" \
    "config/*.sqlite*" \
    "config/home-assistant.log*" || true
)"
if [[ -n "${SENSITIVE_TRACKED}" ]]; then
  echo "Sensitive or runtime files are tracked:" >&2
  echo "${SENSITIVE_TRACKED}" >&2
  exit 1
fi

if [[ "${MODE}" == "live" ]]; then
  echo "Checking live Home Assistant connectivity"
  scripts/check_connectivity.sh
fi

if [[ "${MODE}" == "full" ]]; then
  echo "Checking live Home Assistant connectivity"
  scripts/check_connectivity.sh
  echo "Running Home Assistant config check"
  scripts/check_config.sh
fi

echo "Preflight OK (${MODE})"
