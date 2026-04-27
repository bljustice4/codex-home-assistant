#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/ha_env.sh"

HOST="${HA_URL#http://}"
HOST="${HOST#https://}"
HOST="${HOST%%:*}"
HOST="${HOST%%/*}"

check_port() {
  local host="$1"
  local port="$2"
  local label="$3"

  if nc -z -w 3 "${host}" "${port}" >/dev/null 2>&1; then
    echo "${label}: open (${host}:${port})"
  else
    echo "${label}: closed/refused (${host}:${port})"
  fi
}

echo "Home Assistant diagnostics"
echo "Target: ${HOST}"
echo

echo "Ping:"
if ping -c 2 "${HOST}" >/dev/null 2>&1; then
  echo "Host reachable"
else
  echo "Host did not respond to ping"
fi
echo

echo "Ports:"
check_port "${HOST}" 8123 "Core HTTP"
check_port "${HOST}" "${HA_SSH_PORT}" "SSH add-on"
check_port "${HOST}" 4357 "HAOS Observer"
echo

echo "Observer:"
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' "${HOST}"
import re
import sys
import urllib.request

host = sys.argv[1]
try:
    with urllib.request.urlopen(f"http://{host}:4357/", timeout=5) as response:
        html = response.read().decode("utf-8", errors="replace")
except Exception as exc:
    print(f"Observer unavailable: {exc}")
    raise SystemExit(0)

rows = re.findall(r"<tr>\s*<td>\s*(.*?)\s*</td>\s*<td[^>]*>\s*(.*?)\s*</td>\s*</tr>", html, re.S)
if not rows:
    print("Observer responded, but status rows were not recognized")
else:
    for key, value in rows:
        key = re.sub(r"\s+", " ", key).strip(" :")
        value = re.sub(r"\s+", " ", value).strip()
        print(f"{key}: {value}")
PY
else
  curl --silent --show-error --max-time 5 "http://${HOST}:4357/" || true
fi
