# Security Rules

## Scope
These rules apply to local development automation in this repository.

## Credentials and Secrets
- Treat credentials in compose/env files as development-only defaults; do not copy them into production repositories.
- Never introduce new plaintext production secrets in tracked files.
- Keep `SSH_AUTH_KEY` and similar secret fields empty or environment-injected for local work.

## Database Safety
- Use `scripts/import-db.sh` for imports when possible; it validates environment, container health, and SQL file presence.
- Run import scripts only from this repo root and only against development containers.
- Do not run destructive SQL imports against unknown or shared databases.

## Compose and Host Exposure
- Confirm exposed ports before adding new services (`3306`, `27017`, `5672`, `15672`, `6379`, `8080`, `80` are already used in variants).
- Keep `extra_hosts` and host bind mounts machine-scoped; avoid introducing broad host mappings.
- Preserve explicit container names used by helper scripts (for example `pc_mariadb`) unless all dependent scripts are updated.

## Image and Runtime Hygiene
- Pin image tags explicitly (already used in compose files) rather than floating latest tags.
- Preserve `set -e` / `set -euo pipefail` in shell scripts and fail fast on unsafe states.
