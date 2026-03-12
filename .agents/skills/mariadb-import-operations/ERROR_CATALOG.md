# Error Catalog — MariaDB Import Operations

## `docker-compose.yml not found`
- Cause: script executed outside project root context.
- Fix: run from repository root or use script path from root (`./scripts/import-db.sh ...`).

## `MariaDB container 'pc_mariadb' is not running`
- Cause: container is stopped or renamed.
- Fix: run `docker-compose up -d mariadb` and keep expected container name.

## `SQL file not found`
- Cause: file missing from `backup/db/` or wrong filename.
- Fix: list files with `ls -la backup/db/*.sql` and retry with correct filename.

## `Cannot connect to MariaDB database`
- Cause: container not ready yet or credential mismatch.
- Fix: wait for container health, check logs (`docker logs pc_mariadb`), verify credentials in env and compose.
