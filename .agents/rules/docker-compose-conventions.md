# Docker Compose Conventions

## Service Definition Patterns
- Shared infra services live directly in compose files (`mariadb`, `mongodb`, `redis`, `rabbit`, `krakend`).
- Go services should extend from `common-services.yml` when possible to avoid drift.
- Keep `GO_SVC` explicit and aligned with mounted source directory names.

## Networks and Volumes
- Use the external `dev` network expected by this repository.
- Keep bind-mounted host paths in machine-specific compose files (`docker-compose.*_t490s.yml`, etc.) when they differ.
- Keep persistent state under named volumes for DB/cache services.

## Entrypoint and Runtime Assumptions
- Go service startup depends on `/docker/docker/golang/run.sh` and a valid `/go/src/${GO_SVC}`.
- `ENV` defaults to `dev`; changing defaults requires validating run/build flow.
- Avoid removing `gopkg` mount in `common-services.yml` because module downloads depend on it.

## Dependency Ordering
- Go services should declare `depends_on` for `mariadb`, `redis`, and `rabbit` where required.
- Preserve health/start ordering semantics in compose variants to reduce startup flakiness.
