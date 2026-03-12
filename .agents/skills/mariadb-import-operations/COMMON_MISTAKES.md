# Common Mistakes — MariaDB Import Operations

- Using `quick-import.sh` for risky imports where safety checks are needed.
- Running import scripts before MariaDB is fully started.
- Assuming database name auto-detection always succeeds; some dumps require manual DB name input.
- Editing script defaults (`CONTAINER_NAME`, credentials) without matching compose/env updates.
- Importing large dumps without backup when target DB already has data.
