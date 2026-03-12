---
name: mariadb-import-operations
description: Provides safe procedures for importing SQL dumps into the local MariaDB container and troubleshooting import failures.
applyTo: '**/scripts/*.sh, **/backup/**/*.sql, **/etc/environment*.yml'
tags: [mariadb, scripts, database]
---

# MariaDB Import Operations

## Use This Skill When
- Running or editing `scripts/import-db.sh` or `scripts/quick-import.sh`.
- Updating DB import workflow documentation.
- Troubleshooting SQL import failures in local containers.

## Repo-Specific Expectations
1. Primary container is `pc_mariadb`.
2. SQL inputs are expected under `backup/db/`.
3. Full import flow should prefer `import-db.sh` because it includes environment and health checks.
4. Imports are development-only; avoid production usage.

## Required Checks
- `docker-compose up -d mariadb`
- `docker ps | grep pc_mariadb`
- `./scripts/import-db.sh --help`
