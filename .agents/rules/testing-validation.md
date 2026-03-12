# Testing and Validation

## Compose Validation
Before committing compose changes:
1. Validate syntax and interpolation:
   - `docker-compose -f docker-compose.yml config -q`
   - For variant edits, validate the edited file similarly.
2. Verify service graph:
   - `docker-compose -f <compose-file> ps`
3. Check targeted logs after startup:
   - `docker-compose -f <compose-file> logs --tail=100 <service>`

## Script Validation
For changes under `scripts/` or `docker/`:
- Run help and argument checks:
  - `./scripts/import-db.sh --help`
  - `./scripts/quick-import.sh` (expect usage output)
- Validate happy path prerequisites before import tests:
  - `docker-compose up -d mariadb`
  - `docker ps | grep pc_mariadb`

## Regression Guardrails
- Keep container names stable when referenced by scripts (`pc_mariadb`, etc.).
- If changing env variable names in compose, update scripts/docs that depend on them.
- When adding new automation scripts, include `--help` usage output and explicit failure messages.

## Documentation Updates
Update these docs when workflows change:
- `AGENTS.md`
- `.agents/rules/project-context.md`
- `scripts/README.md` when import behavior changes
