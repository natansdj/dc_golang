---
description: Architecture and workflow baseline for dc_golang — always loaded.
alwaysApply: true
---

# Project Context

## Purpose

`dc_golang` is a Docker Compose-based local development orchestrator for PayCloud Go services
and their shared infrastructure (databases, messaging, caching, workflow engine, API gateway).

## Key Directories

- `docker-compose.yml`, `docker-compose.*.yml`: environment-specific service orchestration.
- `common-services.yml`: reusable Go service template (`go1.22`).
- `docker/golang/run.sh`: Go container entrypoint; compiles/runs service from `GO_SVC`.
- `scripts/`: database import helpers and verification scripts.
- `etc/`: runtime config — MariaDB tuning, RabbitMQ plugins, Temporal dynamic config, Postgres init.
- `backup/db/`: SQL dumps consumed by import scripts.

## Default Service Topology

Main stack from `docker-compose.yml`:

| Service | Container | Ports | Notes |
|---------|-----------|-------|-------|
| mariadb | `pc_mariadb` | 3306 | Primary relational DB |
| postgres | `pc_postgres` | 5432 | PostgreSQL (required by Temporal) |
| mongodb | `pc_mongodb` | 27017 | Document store |
| redis | `pc_redis` | 6379 | Cache |
| rabbit | `pc_rabbit` | 5672, 15672 | AMQP + management UI |
| temporal | `pc_temporal` | 7233 | Workflow engine (depends on postgres) |
| temporal-ui | `pc_temporal_ui` | 8081 | Temporal Web UI |
| krakend | `pc_krakend` | 80, 8080 | API gateway (commented out by default) |

Go microservices are added by extending `common-services.yml` and setting `GO_SVC` plus a
bind mount to the local service repository.

## Core Workflows

```bash
make network-dev              # Create external `dev` network (once per Docker host)
make config                   # Validate active compose file
make start                    # Start MariaDB, Postgres, MongoDB, Redis, RabbitMQ
make up-stack                 # Start infra + Temporal + Temporal UI
make startdb                  # Start only MariaDB and PostgreSQL
make up                       # Start all services in COMPOSE_FILE
make stop                     # Stop core infra services
make down                     # docker compose down
make ps                       # Container status
make logs S=<service>         # Follow logs for a service
make shell-mariadb            # MariaDB client (root/root)
make shell-postgres           # psql as postgres
make shell-redis              # redis-cli
make shell-mongo              # mongosh (root/root)
make import-db FILE=dump.sql  # Safe MariaDB import
make list-db                  # List SQL files under backup/db
make verify-temporal          # Temporal / Docker layout checks
```

## Operational Notes

- Compose uses external network `dev`; run `make network-dev` before first use.
- Several volume mounts are host-specific absolute paths; adapt via machine-specific compose variants.
- `docker/golang/run.sh` runs `go mod download` and builds with `CGO_ENABLED=0 GOOS=linux GOARCH=amd64`.
- Temporal depends on `pc_postgres` (`DB=postgres12`); always start postgres first or use `make up-stack`.
- The `docker compose` V2 plugin is the default; override with `DOCKER_COMPOSE=docker-compose` for legacy.
