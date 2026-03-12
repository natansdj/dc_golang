# Error Catalog — Docker Compose Workflows

## `service "X" depends on undefined service`
- Cause: `depends_on` references a service not present in selected compose file.
- Fix: add the missing service or remove/update `depends_on` reference.

## `network dev declared as external, but could not be found`
- Cause: required external Docker network is missing.
- Fix: create it once with `docker network create dev`.

## `Cannot start service ... bind source path does not exist`
- Cause: machine-specific host bind path is invalid.
- Fix: update compose variant to local path or use another machine-specific compose file.

## `No such service: app` in Make targets
- Cause: `Makefile` includes legacy app commands not present in current compose stack.
- Fix: use service-specific compose commands or adjust target for current services.
