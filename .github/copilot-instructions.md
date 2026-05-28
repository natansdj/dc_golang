# dc_golang — GitHub Copilot Instructions

> **Primary instructions:** see [`AGENTS.md`](../AGENTS.md) for the full AI agent guide.
>
> This file is the Copilot bridge. All agents share the same source of truth in `AGENTS.md`.

**Version:** 1.2.0 — **Updated:** 2026-05-27

---

## Quick Reference

| Resource | Path |
|----------|------|
| **Primary instructions** | [`AGENTS.md`](../AGENTS.md) |
| Rules | `.agents/rules/` (symlinked at `.cursor/rules/`) |
| Skills | `.agents/skills/` (symlinked at `.github/skills/`, `.cursor/skills/`) |
| Prompts (shared) | `.agents/prompts/` |
| Prompts (Copilot-only) | `.github/prompts/` |
| Temporal quick ref | `QUICK_REFERENCE.md` |

---

## Stack Overview

`dc_golang` orchestrates local PayCloud infrastructure: MariaDB, PostgreSQL, MongoDB, Redis,
RabbitMQ, Temporal (workflow engine, backed by PostgreSQL), and optional KrakenD gateway.
Go microservices extend `common-services.yml` with a bind mount and `GO_SVC` variable.

## Most-Used Commands

```bash
make network-dev              # Create external `dev` network (once per host)
make config                   # Validate compose file
make start                    # Start MariaDB, Postgres, MongoDB, Redis, RabbitMQ
make up-stack                 # Start infra + Temporal + Temporal UI
make startdb                  # Start only MariaDB and PostgreSQL
make ps                       # Service status
make logs S=mariadb           # Follow logs for one service
make shell-mariadb            # MariaDB client (root/root)
make shell-postgres           # psql as postgres
make import-db FILE=dump.sql  # Safe MariaDB import
make verify-temporal          # Temporal / Docker layout checks
```

## Key Conventions

- Preserve stable container names (`pc_mariadb`, `pc_postgres`, etc.) — scripts depend on them.
- Temporal requires `pc_postgres`; always use `make up-stack` to start both together.
- Validate compose changes with `make config` before committing.
- Credentials in this repo are development defaults only — never copy to production.
- Machine-specific volume paths live in machine-scoped compose variants (`docker-compose.pycd.yml`).

## Architecture Reference

See `.agents/rules/` for:
- `project-context.md` — service topology and workflow commands
- `docker-compose-conventions.md` — dependency ordering, health checks, port reference
- `security.md` — secret handling and import safety
- `testing-validation.md` — validation checklist for compose and script changes
