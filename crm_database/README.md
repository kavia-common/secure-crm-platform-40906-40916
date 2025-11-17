# crm_database (PostgreSQL) – Secure Setup

This container runs PostgreSQL only. It does not run any Node/Express processes.

Key points:
- PostgreSQL listens on localhost at the configured port (default 5000).
- Authentication is password-based (md5 / scram-sha-256 when supported).
- pg_hba.conf is provided to avoid any trust auth warnings and enforce password auth.
- A convenience file db_connection.txt is generated with a ready-to-use psql connection string.
- The container entrypoint uses startup.sh exclusively to setup and run PostgreSQL.
- Container startup never installs Node modules and never runs npm/node or the db_visualizer.

db_visualizer policy (out-of-scope for container runtime):
- db_visualizer is NEVER started by this container (nor by Dockerfile/compose). It is a manual-only helper.
- To run manually on your host:
  1) cd secure-crm-platform-40906-40916/crm_database/db_visualizer
  2) source postgres.env
  3) export DATABASE_URL="$POSTGRES_URL"
  4) npm ci && npm run start

Notes:
- Do not run db_visualizer inside the database container. It is not installed or launched during image build or container startup.
- express is declared as a dependency and pinned to 4.18.2. The prestart script runs `node -v && npm ci || npm install` to self-heal dependencies.
- Build and runtime logs for this container should only show PostgreSQL initialization/readiness; there should be no Node/npm output.
