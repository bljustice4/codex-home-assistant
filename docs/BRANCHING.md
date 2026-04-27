# Branching And Deployment

## Branch Model

Use `main` as the last known good production Home Assistant config. Do not keep a long-lived `development` branch while there is only one real HA instance.

Create short-lived branches directly from `main`:

```bash
git switch main
git pull --ff-only
git switch -c codex/climate-dashboard
```

Recommended branch prefixes:

- `codex/` for Codex-authored changes.
- `feature/` for user-authored features.
- `fix/` for small repairs.

## CI

GitHub Actions runs static checks only:

- shell syntax for project scripts,
- Python helper compilation,
- YAML syntax for tracked HA YAML,
- sensitive-file path checks.

CI intentionally does not connect to the live Home Assistant instance and does not deploy.

## Local Live Gate

Before testing a branch on the real instance:

```bash
scripts/preflight.sh --live
```

This runs the static checks and verifies REST/SSH connectivity.

Run Home Assistant's own live config check separately when the SSH add-on is stable:

```bash
scripts/check_config.sh
```

Note: `ha core check` validates the config currently on the Home Assistant box. It does not validate an undeployed local branch. On this HAOS setup it can also cause the SSH add-on to close the session, so it is intentionally not part of the default deploy script.

## Deploy A Branch

Deploy only a clean working tree:

```bash
scripts/deploy_branch.sh automations scripts scenes
```

The script verifies the current branch, runs live preflight, creates a backup, deploys the local config, and reloads any domains passed as arguments.
Set `HA_DEPLOY_RUN_CHECK_CONFIG=1` to run `scripts/check_config.sh` after deploy and before reloads.

Prefer reload targets over restart. Use a restart only for changes that require it.

## Rollback

Rollback means redeploying `main`, not trying to reverse-edit the live instance:

```bash
scripts/rollback_main.sh automations scripts scenes
```

The script switches to `main`, fast-forwards from `origin/main`, runs live preflight, creates a backup, deploys `main`, and reloads any provided domains.

## Future Sandbox

A second Home Assistant instance can be useful later as a no-device sandbox for dashboards, templates, and structural checks. Do not connect a sandbox to real radios, HomeKit pairings, or cloud integrations unless the integration is known to tolerate multiple controllers safely.
