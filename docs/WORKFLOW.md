# Workflow

## Import Baseline

```bash
scripts/bootstrap.sh
scripts/pull_config.sh
.venv/bin/python scripts/validate_yaml.py
scripts/check_config.sh
git add .
git commit -m "Import Home Assistant config baseline"
```

## Make a Change

```bash
git switch -c codex/climate-dashboard
scripts/inventory_climate.sh
```

Edit YAML or dashboard files in `config/`, then run:

```bash
.venv/bin/python scripts/validate_yaml.py
scripts/check_config.sh
```

## Deploy

Deploy only after validation passes:

```bash
scripts/backup_ha.sh
scripts/deploy_config.sh
scripts/reload_ha.sh automations
scripts/reload_ha.sh scripts
scripts/reload_ha.sh scenes
```

Prefer targeted reloads. Use a restart only when a change requires it.

## Rollback

```bash
git switch main
.venv/bin/python scripts/validate_yaml.py
scripts/check_config.sh
scripts/backup_ha.sh
scripts/deploy_config.sh
```

Then reload affected domains or restart Home Assistant if required.

## Guardrails

- Do not commit secrets, tokens, databases, logs, or backups.
- Do not hand-edit `.storage` unless explicitly approved.
- Back up before the first deploy and before any risky change.
- Keep live control initially to discovery plus reloads.
