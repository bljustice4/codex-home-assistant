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
scripts/preflight.sh --live
```

Run `scripts/check_config.sh` separately when SSH is stable and you specifically want HAOS to validate the config currently on the Home Assistant box.

## Deploy

Deploy only after validation passes:

```bash
scripts/deploy_branch.sh automations scripts scenes
```

Prefer targeted reloads. Use a restart only when a change requires it.

## Rollback

```bash
scripts/rollback_main.sh automations scripts scenes
```

Then reload affected domains or restart Home Assistant if required.

## Guardrails

- Do not commit secrets, tokens, databases, logs, or backups.
- Do not hand-edit `.storage` unless explicitly approved.
- Back up before the first deploy and before any risky change.
- Keep live control initially to discovery plus reloads.
