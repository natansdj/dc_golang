# Common Mistakes — Docker Compose Workflows

- Editing `docker-compose.yml` without validating variant files used by teammates.
- Renaming `pc_mariadb` and breaking import scripts that assume this container name.
- Adding Go services without setting `GO_SVC`, causing `docker/golang/run.sh` to exit immediately.
- Changing exposed ports without checking collisions across compose variants.
- Removing `depends_on` for infra services and introducing startup race conditions.
