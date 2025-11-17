# crm_database (PostgreSQL) – Secure Setup

This container runs PostgreSQL only. It does not run any Node/Express processes.

Key points:
- PostgreSQL listens on localhost at the configured port (default 5000).
- Authentication is password-based (md5 / scram-sha-256 when supported).
- pg_hba.conf is provided to avoid any trust auth warnings and enforce password auth.
- A convenience file db_connection.txt is generated with a ready-to-use psql connection string.
- The container entrypoint uses startup.sh exclusively to setup and run PostgreSQL.
- Container startup never installs Node modules and never runs npm/node or the db_visualizer.

Optional helper (NOT part of this container):
- db_visualizer is a lightweight Node tool meant to run separately for quick inspection.
- To use it outside the DB container (manual steps on your host):
  1) cd secure-crm-platform-40906-40916/crm_database/db_visualizer
  2) source postgres.env
  3) npm run start   # Note: a prestart hook will auto-run `npm ci` if node_modules is missing

Notes:
- Do not run db_visualizer inside the database container. It is not installed or launched during image build or container startup.
- The db_visualizer/package.json pins express to 4.18.2. On first start, if node_modules is absent, the prestart hook will run `npm ci` automatically.
- Build and runtime logs for this container should only show PostgreSQL initialization/readiness; there should be no Node/npm output.
