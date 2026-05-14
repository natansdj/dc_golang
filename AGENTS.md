# AI Agent Instructions — dc_golang

> Single source of truth for GitHub Copilot, Cursor, Claude Code, and other AI agents.

**Version:** 1.1.0 — **Updated:** 2026-05-14

---

## Quick Reference

| Resource | Path | Description |
|----------|------|-------------|
| **This file** | `AGENTS.md` | Primary AI-agent entry point |
| **Rules** | `.agents/rules/` | Always-or-conditionally loaded rules |
| **Skills** | `.agents/skills/` | Domain-expertise packages |
| **Cursor rules** | `.cursor/rules/` | Symlink → `.agents/rules/` |
| **Cursor skills** | `.cursor/skills/` | Symlink → `.agents/skills/` |
| **Copilot bridge** | `.github/copilot-instructions.md` | Delegates to this file |
| **Copilot skills** | `.github/skills/` | Symlink → `.agents/skills/` |
| **README** | `README.md` | Project overview and getting started |
| **Temporal quick ref** | `QUICK_REFERENCE.md` | Temporal + Docker cheat sheet |

---

## Repository Purpose

`dc_golang` is a **Docker Compose-based local development orchestrator** for PayCloud Go
microservices and their shared infrastructure. It is not a Go service itself — it defines
containers for databases, messaging, caching, workflow engine, and optional API gateway,
plus reusable Go service image definitions.

| Directory | Role |
|-----------|------|
| `docker-compose.yml` | Default stack (MariaDB, Postgres, MongoDB, Redis, RabbitMQ, Temporal, Temporal UI) |
| `docker-compose.pycd.yml` | Machine-specific variant with host-path volumes and KrakenD |
| `common-services.yml` | Reusable Go service template (`go1.22`) |
| `Dockerfile` | `dc_golang:1.22` dev image (Go 1.24, db clients, golangci-lint, air) |
| `docker/golang/run.sh` | Container entrypoint: `go mod download`, cross-compile, run |
| `etc/` | MariaDB config, RabbitMQ plugins, Temporal dynamic config, Postgres init |
| `scripts/` | DB import helpers, `list-db-files.sh`, `verify-temporal-setup.sh` |
| `backup/db/` | SQL dumps for local import |
| `hooks/` | Image build/push helpers |

---

## Stack Services

| Service | Container | Ports (host) | Role |
|---------|-----------|-------------|------|
| mariadb | `pc_mariadb` | 3306 | Primary relational DB for Go services |
| postgres | `pc_postgres` | 5432 | PostgreSQL — Temporal persistence |
| mongodb | `pc_mongodb` | 27017 | Document store |
| redis | `pc_redis` | 6379 | Cache / ephemeral state |
| rabbit | `pc_rabbit` | 5672, 15672 | AMQP + management UI |
| temporal | `pc_temporal` | 7233, 6933–6939, 9090 | Durable workflow engine (requires Postgres) |
| temporal-ui | `pc_temporal_ui` | 8081 | Temporal Web UI |
| krakend | `pc_krakend` | 80, 8080 | API gateway (commented out by default; enable in machine variant) |

Go microservices extend `common-services.yml` by setting `GO_SVC` and adding a bind mount
to the local clone under `/go/src/<module>`.

---

## Critical Conventions

### 1. Go service wiring

Keep `GO_SVC`, bind mount target, and `working_dir` in sync — mismatches are the most
common source of build failures.

```yaml
✅ Correct
service_name:
  extends:
    file: common-services.yml
    service: go1.22
  environment:
    GO_SVC: "paycloud-be-settlement-module"
  volumes:
    - /Users/natan/go/src/paycloud-be-settlement-module:/go/src/paycloud-be-settlement-module
  working_dir: "/go/src/paycloud-be-settlement-module"

❌ Incorrect — working_dir doesn't match GO_SVC mount
service_name:
  environment:
    GO_SVC: "paycloud-be-settlement-module"
  working_dir: "/go/src/other-module"
```

### 2. Network prerequisite

All services use the external Docker network `dev`. Create it once before first run:

```bash
make network-dev   # or: docker network create dev
```

### 3. Temporal requires PostgreSQL

Temporal uses `pc_postgres` as its persistence backend (`DB=postgres12` in compose env).
Always start postgres before or alongside temporal:

```bash
make up-stack    # starts infra + temporal + temporal-ui together
```

### 4. Security

- Credentials in compose/env files are development defaults only — never copy to production.
- Keep `pc_mariadb` and other stable container names intact; scripts depend on them.
- Confirmed exposed ports (see stack table above) before adding new services.

### 5. Configuration

- Machine-specific volume paths (e.g. `/Users/natan/lxc/…`) live in machine-specific compose
  variants; choose the right file before editing.
- `docker/golang/run.sh` requires `GO_SVC` and expects source at `/go/src/${GO_SVC}`.
- `ENV` defaults to `dev`; run.sh builds with `CGO_ENABLED=0 GOOS=linux GOARCH=amd64`.

### 6. Shell scripts

- Use `set -e` / `set -euo pipefail`; scripts must fail fast.
- Prefer `make import-db FILE=x.sql` over quick-import for recoverability and preflight checks.
- Include `--help` / usage output when adding or changing scripts.

---

## Common Commands

```bash
make network-dev              # Create external `dev` network (once per Docker host)
make config                   # Validate active compose file
make up                       # Start all services in COMPOSE_FILE
make start                    # Start MariaDB, Postgres, MongoDB, Redis, RabbitMQ
make up-stack                 # Start infra + Temporal + Temporal UI
make startdb                  # Start only MariaDB and PostgreSQL
make stop                     # Stop core infra services
make down                     # docker compose down for the file
make ps                       # Service status
make logs S=mariadb           # Follow logs for one service (omit S for all)
make shell-mariadb            # mysql client as root in pc_mariadb
make shell-postgres           # psql as postgres in pc_postgres
make shell-redis              # redis-cli in pc_redis
make shell-mongo              # mongosh in pc_mongodb
make import-db FILE=dump.sql  # Safe MariaDB import via scripts/import-db.sh
make list-db                  # List SQL files under backup/db
make verify-temporal          # Run Temporal / Docker layout checks
make debug-up                 # Foreground up with COMPOSE_DEBUG=1

# Override compose file
make up COMPOSE_FILE=docker-compose.pycd.yml
make config COMPOSE_FILE=docker-compose.pycd.yml

# Legacy Compose V1 binary
make ps DOCKER_COMPOSE=docker-compose
```

---

## Dependency Map

```mermaid
flowchart TD
  compose[docker-compose*.yml] --> infra[MariaDB / MongoDB / Redis / RabbitMQ]
  compose --> postgres[PostgreSQL pc_postgres]
  compose --> temporal[Temporal pc_temporal]
  compose --> temporal_ui[Temporal UI pc_temporal_ui]
  postgres --> temporal
  temporal --> temporal_ui
  compose --> go[Go services via common-services.yml]
  common[common-services.yml] --> runsh[docker/golang/run.sh]
  runsh --> svc[/go/src/${GO_SVC}]
  scripts[scripts/import-db.sh\nquick-import.sh] --> mariadb[pc_mariadb]
  scripts --> dumps[backup/db/*.sql]
  compose --> env[etc/environment.yml\netc/mariadb/*\netc/rabbitmq/*\netc/temporal/*\netc/postgresql/init]
```

---

## Rules Reference

| Rule | File | Loaded When |
|------|------|-------------|
| Project Context | [`.agents/rules/project-context.md`](.agents/rules/project-context.md) | Always |
| Compose Conventions | [`.agents/rules/docker-compose-conventions.md`](.agents/rules/docker-compose-conventions.md) | Editing compose files |
| Security | [`.agents/rules/security.md`](.agents/rules/security.md) | Always |
| Testing & Validation | [`.agents/rules/testing-validation.md`](.agents/rules/testing-validation.md) | Validating changes |

## Skills Reference

| Skill | Path | Use When |
|-------|------|----------|
| docker-compose-workflows | [`.agents/skills/docker-compose-workflows/`](.agents/skills/docker-compose-workflows/) | Editing compose topology, volumes, networks, Go service wiring |
| mariadb-import-operations | [`.agents/skills/mariadb-import-operations/`](.agents/skills/mariadb-import-operations/) | Running/changing SQL import scripts, local DB recovery |

---

## Agent Compatibility

### Claude Code

- Reads `AGENTS.md` directly; resources accessible via `.agents/`

### GitHub Copilot

- Entry point: `.github/copilot-instructions.md` → delegates to this file
- Skills via `.github/skills/` symlink → `.agents/skills/`

### Cursor

- Rules via `.cursor/rules/` symlink → `.agents/rules/`
- Skills via `.cursor/skills/` symlink → `.agents/skills/`

---

## Adding a New Rule or Skill

### New rule

1. Create `.agents/rules/<name>.md` with frontmatter
2. Add a row to **Rules Reference** above

### New skill

1. Create `.agents/skills/<name>/SKILL.md` with frontmatter
2. Add a row to **Skills Reference** above
