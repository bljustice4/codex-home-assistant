# CodexHomeAssistant

Git-backed Home Assistant workflow for a Home Assistant Core `2026.2.1` instance on Home Assistant OS `17.0`.

The project is intentionally hybrid:

- Git owns review, history, rollback, and branches.
- Home Assistant APIs provide live discovery and reloads.
- SSH/add-on access handles config import, deploy, backups, and authoritative validation.
- Secrets stay local and ignored.

## Quick Start

1. Copy `.env.example` to `.env` and fill in local values.
2. Create a Home Assistant long-lived access token in your HA profile and put it in `HA_TOKEN`.
3. If the Terminal & SSH add-on is exposed on a custom port, set `HA_SSH_PORT`.
4. Run `scripts/bootstrap.sh`.
5. Run `scripts/check_connectivity.sh`.
6. Run `scripts/pull_config.sh` to import the current config into `config/`.
7. Run `.venv/bin/python scripts/validate_yaml.py`.
8. Run `scripts/check_config.sh`.
9. Commit the imported baseline before making workflow changes.

## First Milestone

Climate and dashboards:

- Inventory ecobee, Flair, HomeKit, and LG ThinQ climate-related entities.
- Map rooms, climate devices, sensors, and controls.
- Build climate-first dashboard views.
- Prefer reloadable YAML changes over restart-only changes.

See `docs/CONNECT_HOME_ASSISTANT.md` and `docs/WORKFLOW.md`.

## Branching And CI

Use `main` as the last known good production config. Create short-lived feature branches directly from `main`; CI runs static checks only, and live deploys stay manual and backup-gated.

See `docs/BRANCHING.md`.
