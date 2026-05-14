---
description: Validation commands and regression checks for dc_golang compose and script changes.
applyTo: '**/docker-compose*.yml, **/scripts/*.sh, **/docker/**/*.sh'
---

# Testing and Validation

## Compose Validation

Before committing compose changes:

1. Validate syntax and interpolation:
   - `make config` (uses active `COMPOSE_FILE`)
   - `make config COMPOSE_FILE=docker-compose.pycd.yml` for variant edits
2. Verify service graph:
   - `make ps`
3. Check targeted logs after startup:
   - `make logs S=<service>`

## Script Validation

For changes under `scripts/` or `docker/`:

- Run help and argument checks:
  - `./scripts/import-db.sh --help`
  - `./scripts/quick-import.sh` (expect usage output)
  - `./scripts/list-db-files.sh` (expect SQL file listing)
- Validate happy-path prerequisites before import tests:
  - `make startdb`
  - `docker ps | grep pc_mariadb`

## Temporal Validation

After changes that affect Temporal or PostgreSQL:

```bash
make verify-temporal          # Layout and connection checks
make up-stack                 # Bring up Temporal + deps; watch logs
make logs S=temporal          # Confirm no startup errors
make logs S=temporal-ui       # Confirm UI is reachable
```

Access Temporal UI at: `http://localhost:8081`

## Regression Guardrails

- Keep container names stable when referenced by scripts (`pc_mariadb`, `pc_postgres`, etc.).
- If changing env variable names in compose, update scripts and docs that depend on them.
- When adding new scripts, include `--help` usage output and explicit failure messages.

## Documentation Updates

Update these docs when workflows change:

- `AGENTS.md`
- `.agents/rules/project-context.md`
- `scripts/README.md` when import behaviour changes
- `QUICK_REFERENCE.md` when Temporal setup changes
