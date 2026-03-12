# dc_golang — AI Agent Guidelines

> **Primary instructions**: See [AGENTS.md](../AGENTS.md) for complete AI agent guidelines.
>
> This file provides GitHub Copilot-specific context.
> All agents share the same source of truth in `AGENTS.md`.

## Copilot Quick Reference

- Use `docker-compose*.yml` plus `common-services.yml` as the service topology source.
- Prefer `scripts/import-db.sh` for database imports; use quick script only for low-risk local tasks.
- Preserve `pc_mariadb` naming unless you also update dependent scripts.
- Validate compose changes with `docker-compose -f <file> config -q`.
- Treat credentials in this repo as development-only defaults.
