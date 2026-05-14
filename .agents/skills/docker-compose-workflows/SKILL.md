---
name: docker-compose-workflows
description: Guides editing and validating docker-compose service topology, dependencies, and runtime conventions in this repository.
applyTo: '**/docker-compose*.yml, **/common-services*.yml, **/docker/**/*.sh'
tags: [docker, compose, infrastructure]
---

# Docker Compose Workflows

## Use This Skill When

- Modifying any `docker-compose*.yml` or `common-services.yml` file.
- Adding/changing Go service definitions that use the `go1.22` template.
- Updating container names, ports, networks, volumes, or bind mounts.
- Adding or configuring Temporal, PostgreSQL, or other new services.

## Repo-Specific Expectations

1. Preserve script-dependent container names unless intentionally coordinated (e.g. `pc_mariadb`, `pc_postgres`).
2. Keep the external network `dev` assumption valid; create with `make network-dev`.
3. For Go services, ensure `GO_SVC` matches the mounted source path under `/go/src/<service>`.
4. Temporal requires `pc_postgres` with `condition: service_started` — never separate them.
5. Validate compose configuration with `make config` before handoff.

## Required Checks

```bash
make config                          # Validate active compose file
make config COMPOSE_FILE=<variant>   # Validate a specific variant
make ps                              # Verify service graph after changes
make logs S=<service>                # Check logs for affected services
```

## Common Mistakes

See [`COMMON_MISTAKES.md`](./COMMON_MISTAKES.md) and [`ERROR_CATALOG.md`](./ERROR_CATALOG.md).
