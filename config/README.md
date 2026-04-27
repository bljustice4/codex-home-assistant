# Home Assistant Config Mirror

This directory is the local Git mirror of the Home Assistant `/config` directory.

Run `../scripts/pull_config.sh` from the project root to import the current live config. Runtime state, secrets, databases, logs, backups, and `.storage` are excluded by default.
