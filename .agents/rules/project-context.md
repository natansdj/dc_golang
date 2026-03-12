# Project Context

## Purpose
`dc_golang` is a Docker-based local development orchestrator for Go services and shared dependencies (MariaDB, MongoDB, Redis, RabbitMQ, KrakenD).

## Key Directories
- `docker-compose.yml`, `docker-compose.*.yml`: environment-specific service orchestration.
- `common-services.yml`: reusable Go service templates (`go1.22`).
- `docker/golang/run.sh`: Go service container entrypoint; compiles/runs service from `GO_SVC`.
- `scripts/`: database import helpers (`import-db.sh`, `quick-import.sh`).
- `etc/`: runtime configuration (`environment.yml`, MariaDB/RabbitMQ config snippets).
- `backup/db/`: SQL dumps consumed by import scripts.

## Default Service Topology
Main stack from `docker-compose.yml`:
- `mariadb` (`pc_mariadb`)
- `mongodb` (`pc_mongodb`)
- `redis` (`pc_redis`)
- `rabbit` (`pc_rabbit`)
- `krakend` (`pc_krakend`)

Go services are commonly added by extending `common-services.yml` and setting `GO_SVC` + bind mounts to local service repos.

## Core Workflows
- Start infra only: `make start` (or `docker-compose up -d mariadb mongodb redis rabbit`)
- Start DB only: `make startdb`
- Stop infra: `make stop`
- Status: `make state`
- List make targets: `make list`
- Import DB dump (safe mode): `./scripts/import-db.sh <file.sql>`
- Import DB dump (quick mode): `./scripts/quick-import.sh <file.sql> [db]`

## Operational Notes
- Compose uses external network `dev`; it must exist before running stack.
- Several volume mounts are host-specific absolute paths (for example `/Users/natan/...`); adapt for machine-specific compose variants.
- `docker/golang/run.sh` runs `go mod download` and builds with `CGO_ENABLED=0 GOOS=linux GOARCH=amd64` for `ENV=local|dev|staging`.
