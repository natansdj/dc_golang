# AI Agent Instructions — dc_golang

> Single source of truth for GitHub Copilot, Cursor, Claude Code, and other AI agents.

## Quick Reference

| Resource | Path | Description |
|----------|------|-------------|
| This file | `AGENTS.md` | Primary AI agent instructions |
| Skills | `.agents/skills/` | Domain expertise packages |
| Rules | `.agents/rules/` | Development rules and patterns |

## Repository Structure

- `docker-compose*.yml`: environment variants for local stack bootstrapping.
- `common-services.yml`: reusable Go service base definitions.
- `docker/golang/run.sh`: Go service boot logic, module download, compile, execute.
- `etc/`: env/config overlays for MariaDB and RabbitMQ.
- `scripts/`: safe and quick DB import automation.
- `backup/db/`: SQL dump inventory for local restore/import flows.
- `hooks/`: image build/push automation scripts.

## Critical Conventions

### 1. Expression / Syntax
Use compose `extends` for Go services and keep `GO_SVC` aligned with mount + working directory.

```yaml
✅ Correct
service_name:
  extends:
    file: common-services.yml
    service: go1.22
  environment:
    GO_SVC: "paycloud-be-settlement-module"
  volumes:
    - /host/go/src/paycloud-be-settlement-module:/go/src/paycloud-be-settlement-module
  working_dir: "/go/src/paycloud-be-settlement-module"

❌ Incorrect
service_name:
  environment:
    GO_SVC: "paycloud-be-settlement-module"
  working_dir: "/go/src/other-module"
```

### 2. Security
- Credentials in compose/env files are development defaults only; never mirror this pattern for production secrets.
- Import scripts are dev-only and assume local container/database isolation.
- Keep container names used by scripts stable (notably `pc_mariadb`).

### 3. Configuration
- External Docker network `dev` is required by compose files.
- Many volume paths are machine-specific absolute mounts; choose the correct compose variant before edits.
- `docker/golang/run.sh` requires `GO_SVC` and expects source at `/go/src/${GO_SVC}`.

### 4. Error Handling
- Shell automation should fail fast (`set -e` or `set -euo pipefail`).
- Prefer `scripts/import-db.sh` over quick import for recoverability and preflight checks.
- Keep explicit usage/help output when updating scripts.

### 5. Dependencies
- Go services usually depend on `mariadb`, `redis`, and `rabbit` readiness.
- `run.sh` performs `go mod download` on startup; avoid breaking `gopkg` volume usage.
- KrakenD config relies on mounted external gateway repository paths.

## Skills Reference

| Skill | Path | Use When |
|-------|------|----------|
| docker-compose-workflows | `.agents/skills/docker-compose-workflows/` | Editing compose topology, volumes, networks, or Go service wiring |
| mariadb-import-operations | `.agents/skills/mariadb-import-operations/` | Running/changing SQL import scripts and local DB recovery flow |

## Rules Reference

| Rule | File | Purpose |
|------|------|---------|
| project-context | `.agents/rules/project-context.md` | Architecture and workflow baseline |
| security | `.agents/rules/security.md` | Local security and secret-handling constraints |
| testing-validation | `.agents/rules/testing-validation.md` | Validation commands and regression checks |
| docker-compose-conventions | `.agents/rules/docker-compose-conventions.md` | Compose-specific patterns for this repo |

## Dependency Map

```mermaid
flowchart TD
  compose[docker-compose*.yml] --> infra[Infra services\nMariaDB/Mongo/Redis/Rabbit/KrakenD]
  compose --> go[Go services via common-services.yml]
  common[common-services.yml] --> runsh[docker/golang/run.sh]
  runsh --> svc[/go/src/${GO_SVC}]
  scripts[scripts/import-db.sh\nquick-import.sh] --> mariadb[pc_mariadb]
  scripts --> dumps[backup/db/*.sql]
  compose --> env[etc/environment.yml\netc/mariadb/*\netc/rabbitmq/*]
```

## Agent Compatibility

### GitHub Copilot
- Reads `.github/copilot-instructions.md` → delegates to `AGENTS.md`
- Skills via `.github/skills/` symlink → `.agents/skills/`

### Cursor
- Rules via `.cursor/rules/` symlink → `.agents/rules/`
- Skills via `.cursor/skills/` symlink → `.agents/skills/`

### Claude Code
- Reads `AGENTS.md` directly
- All resources accessible via `.agents/`
