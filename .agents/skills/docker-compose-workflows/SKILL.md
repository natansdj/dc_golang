---
name: docker-compose-workflows
description: Guides editing and validating docker-compose service topology, dependencies, and runtime conventions in this repository.
applyTo: '**/docker-compose*.yml, **/common-services*.yml, **/docker/**/*.sh'
tags: [docker, compose, infrastructure]
---

# Docker Compose Workflows

## Use This Skill When
- Modifying any `docker-compose*.yml` file.
- Adding/changing Go service definitions that use `common-services.yml`.
- Updating container names, ports, networks, or bind mounts.

## Repo-Specific Expectations
1. Preserve script-dependent container names unless intentionally coordinated (for example `pc_mariadb`).
2. Keep the external network `dev` assumption valid.
3. For Go services, ensure `GO_SVC` matches mounted source path under `/go/src/<service>`.
4. Validate compose configuration with `docker-compose -f <file> config -q` before handoff.

## Required Checks
- `docker-compose -f <compose-file> config -q`
- `docker-compose -f <compose-file> ps`
- Service-level log check for changed services.
