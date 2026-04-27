#!/usr/bin/env python3
"""Small Home Assistant REST helper for CodexHomeAssistant."""

from __future__ import annotations

import json
import os
import socket
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LOCAL_WORK_DIR = PROJECT_ROOT / ".local"
INVENTORY_DIR = LOCAL_WORK_DIR / "inventory"


def load_dotenv() -> None:
    env_path = PROJECT_ROOT / ".env"
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_dotenv()

HA_URL = os.environ.get("HA_URL", "http://homeassistant.local:8123").rstrip("/")
HA_TOKEN = os.environ.get("HA_TOKEN", "")


def require_token() -> None:
    if not HA_TOKEN:
        print("HA_TOKEN is required. Add it to .env; do not commit it.", file=sys.stderr)
        raise SystemExit(2)


def request_json(method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
    headers = {"Content-Type": "application/json"}
    if HA_TOKEN:
        headers["Authorization"] = f"Bearer {HA_TOKEN}"
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(f"{HA_URL}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = response.read().decode("utf-8")
            return json.loads(body) if body else None
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        print(f"Home Assistant API error {exc.code}: {details}", file=sys.stderr)
        raise SystemExit(1) from exc
    except urllib.error.URLError as exc:
        print(f"Could not reach Home Assistant at {HA_URL}: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    except TimeoutError as exc:
        print(f"Home Assistant API request timed out at {HA_URL}", file=sys.stderr)
        raise SystemExit(1) from exc
    except socket.timeout as exc:
        print(f"Home Assistant API request timed out at {HA_URL}", file=sys.stderr)
        raise SystemExit(1) from exc


def cmd_health() -> int:
    headers = {}
    if HA_TOKEN:
        headers["Authorization"] = f"Bearer {HA_TOKEN}"
    request = urllib.request.Request(f"{HA_URL}/api/", headers=headers, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            body = response.read().decode("utf-8")
            result = json.loads(body) if body else {"status": response.status}
            print(json.dumps(result, indent=2, sort_keys=True))
    except urllib.error.HTTPError as exc:
        if exc.code == 401:
            print(f"Home Assistant is reachable at {HA_URL}, but authenticated API calls need HA_TOKEN.")
            return 0
        details = exc.read().decode("utf-8", errors="replace")
        print(f"Home Assistant API error {exc.code}: {details}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"Could not reach Home Assistant at {HA_URL}: {exc}", file=sys.stderr)
        return 1
    return 0


def cmd_restart_addon(addon: str) -> int:
    require_token()
    request_json("POST", "/api/services/hassio/addon_restart", {"addon": addon})
    print(f"Restart requested for add-on: {addon}")
    return 0


def cmd_inventory_climate() -> int:
    require_token()
    states = request_json("GET", "/api/states")
    services = request_json("GET", "/api/services")

    keywords = ("ecobee", "flair", "homekit", "homekit_controller", "lg", "thinq", "climate", "temperature", "humidity", "thermostat", "vent")
    domains = {"climate", "humidifier", "fan", "sensor", "binary_sensor", "switch", "number", "select"}

    matches = []
    for state in states:
        entity_id = state.get("entity_id", "")
        attributes = state.get("attributes", {})
        haystack = " ".join(
            str(value).lower()
            for value in (
                entity_id,
                attributes.get("friendly_name", ""),
                attributes.get("device_class", ""),
                attributes.get("unit_of_measurement", ""),
                attributes.get("integration", ""),
            )
        )
        if entity_id.split(".", 1)[0] in domains and any(keyword in haystack for keyword in keywords):
            matches.append(state)

    service_domains = {
        item.get("domain"): sorted((item.get("services") or {}).keys())
        for item in services
        if item.get("domain") in {"climate", "fan", "humidifier", "homeassistant", "automation", "script", "scene"}
    }

    INVENTORY_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    json_path = INVENTORY_DIR / f"climate-{stamp}.json"
    md_path = INVENTORY_DIR / "climate-latest.md"

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "ha_url": HA_URL,
        "match_count": len(matches),
        "entities": matches,
        "service_domains": service_domains,
    }
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")

    lines = [
        "# Climate Inventory",
        "",
        f"Generated: {payload['generated_at']}",
        f"Matched entities: {len(matches)}",
        "",
        "## Entities",
        "",
    ]
    for state in matches:
        attrs = state.get("attributes", {})
        lines.append(f"- `{state.get('entity_id')}`: {attrs.get('friendly_name', state.get('state'))}")
    lines.extend(["", "## Service Domains", ""])
    for domain, names in sorted(service_domains.items()):
        lines.append(f"- `{domain}`: {', '.join(names)}")
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Wrote {json_path.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {md_path.relative_to(PROJECT_ROOT)}")
    return 0


RELOAD_SERVICES = {
    "core": ("homeassistant", "reload_core_config"),
    "automations": ("automation", "reload"),
    "automation": ("automation", "reload"),
    "scripts": ("script", "reload"),
    "script": ("script", "reload"),
    "scenes": ("scene", "reload"),
    "scene": ("scene", "reload"),
    "template": ("template", "reload"),
    "groups": ("group", "reload"),
    "group": ("group", "reload"),
    "input_boolean": ("input_boolean", "reload"),
    "input_number": ("input_number", "reload"),
    "input_select": ("input_select", "reload"),
    "input_text": ("input_text", "reload"),
}


def cmd_reload(name: str) -> int:
    require_token()
    if name not in RELOAD_SERVICES:
        print(f"Unsupported reload target: {name}", file=sys.stderr)
        print(f"Supported: {', '.join(sorted(RELOAD_SERVICES))}", file=sys.stderr)
        return 64
    domain, service = RELOAD_SERVICES[name]
    request_json("POST", f"/api/services/{domain}/{service}", {})
    print(f"Reload requested: {domain}.{service}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: ha_api.py <health|inventory-climate|reload|restart-addon> [target]", file=sys.stderr)
        return 64

    command = argv[1]
    if command == "health":
        return cmd_health()
    if command == "inventory-climate":
        return cmd_inventory_climate()
    if command == "reload":
        if len(argv) != 3:
            print("Usage: ha_api.py reload <target>", file=sys.stderr)
            return 64
        return cmd_reload(argv[2])
    if command == "restart-addon":
        if len(argv) != 3:
            print("Usage: ha_api.py restart-addon <addon-slug>", file=sys.stderr)
            return 64
        return cmd_restart_addon(argv[2])

    print(f"Unknown command: {command}", file=sys.stderr)
    return 64


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
