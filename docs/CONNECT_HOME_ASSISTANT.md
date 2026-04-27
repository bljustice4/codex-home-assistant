# Connect Home Assistant

## Local Values

The defaults match the current setup:

- Home Assistant URL: `http://homeassistant.local:8123`
- Install: Home Assistant Core `2026.2.1` on Home Assistant OS `17.0`
- SSH/add-on: official Terminal & SSH add-on
- Remote config directory: `/config`

Copy `.env.example` to `.env` and fill in:

- `HA_TOKEN`: Home Assistant long-lived access token from your HA profile.
- `HA_SSH_TARGET`: SSH target, usually `homeassistant.local`.
- `HA_SSH_PORT`: SSH port exposed by the Terminal & SSH add-on.

Do not paste tokens into chat and do not commit `.env`.

## Connectivity Checks

Run:

```bash
scripts/check_connectivity.sh
```

The script checks:

- HTTP reachability for `HA_URL`.
- Authenticated REST access if `HA_TOKEN` is set.
- SSH reachability if the add-on is exposed.

Port `8123` is reachable from this machine. Initial SSH probing found port `22` refused, so set the actual add-on port in `.env` if different.

## MCP

Enable the official Home Assistant MCP Server integration when ready. It exposes `/api/mcp` and requires authentication. For this project, MCP starts as live context and controlled actions; config edits still flow through Git and validation.
