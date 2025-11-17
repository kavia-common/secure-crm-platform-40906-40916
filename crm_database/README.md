# CRM Database (PostgreSQL)

This container provides a PostgreSQL database for the CRM system. It includes initialization SQL scripts that create core schemas and tables for customers, service requests, complaints, interactions, and audit logs.

Key points:
- No references to any non-existent `db_visualizer` directory are present.
- Initialization scripts are located in `./init/*.sql` and are automatically executed on first run by the official PostgreSQL entrypoint.
- Secrets are never hard-coded. Provide `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` at runtime.

## Build

From this folder:

```bash
docker build -t crm_database:dev .
```

## Run

Provide required environment variables at runtime:

```bash
docker run --rm -d \
  --name crm_database \
  -e POSTGRES_DB=crm \
  -e POSTGRES_USER=crm_admin \
  -e POSTGRES_PASSWORD=change_me_strong \
  -p 5432:5432 \
  crm_database:dev
```

The scripts in `/docker-entrypoint-initdb.d/` run automatically the first time the database is initialized. Subsequent starts will not re-run these scripts.

## Connecting

```bash
# Using psql from host (if installed)
psql "postgresql://crm_admin:change_me_strong@localhost:5432/crm"
```

## Notes

- No `db_visualizer` steps or directories are used or referenced. If you need a DB administration UI, consider running a separate `pgAdmin` container or similar tool.
- Add new SQL files to `./init/` to have them executed on first initialization. Only `.sql`, `.sql.gz`, or executable `.sh` scripts are run by the official entrypoint.
