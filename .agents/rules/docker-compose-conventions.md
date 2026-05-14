---
description: Compose-specific patterns for dc_golang — service definitions, networks, volumes, and dependency ordering.
applyTo: '**/docker-compose*.yml, **/common-services*.yml'
---

# Docker Compose Conventions

## Service Definition Patterns

- Shared infra services live directly in compose files (`mariadb`, `postgres`, `mongodb`, `redis`, `rabbit`).
- Go services should extend from `common-services.yml` when possible to avoid drift.
- Keep `GO_SVC` explicit and aligned with the mounted source directory name.

## Networks and Volumes

- Use the external `dev` network; create with `make network-dev` before first run.
- Keep host-specific bind-mount paths in machine-scoped compose variants (`docker-compose.pycd.yml`, etc.).
- Keep persistent state under named volumes for DB/cache services.

## Entrypoint and Runtime Assumptions

- Go service startup depends on `docker/golang/run.sh` and a valid `/go/src/${GO_SVC}`.
- `ENV` defaults to `dev`; changing it requires validating the run/build flow.
- Avoid removing the `gopkg` volume mount from `common-services.yml` — module downloads depend on it.

## Dependency Ordering

- Go services should declare `depends_on` for `mariadb`, `redis`, and `rabbit` where required.
- Temporal **requires** postgres with `condition: service_started` — never start temporal without postgres.
- Use health checks for Temporal to avoid early-connect failures from dependent services:

```yaml
temporal:
  depends_on:
    postgres:
      condition: service_started
  healthcheck:
    test: ["CMD-SHELL", "temporal operator cluster health --address $$(hostname -i | awk '{print $$1}'):7233 >/dev/null 2>&1"]
    interval: 10s
    timeout: 5s
    retries: 5
```

## Exposed Ports (already used)

Confirm no conflicts before adding new services:

| Port | Service |
|------|---------|
| 3306 | MariaDB |
| 5432 | PostgreSQL |
| 27017 | MongoDB |
| 5672, 15672 | RabbitMQ |
| 6379 | Redis |
| 7233 | Temporal gRPC frontend |
| 8081 | Temporal UI |
| 80, 8080 | KrakenD (when enabled) |
