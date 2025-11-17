# crm_database (PostgreSQL) – Secure Setup

This container runs PostgreSQL only. It does not run any Node/Express processes.

Key points:
- PostgreSQL listens on localhost at the configured port (default 5000).
- Authentication is password-based (md5 / scram-sha-256 when supported).
- pg_hba.conf is provided to avoid any trust auth warnings and enforce password auth.
- A convenience file db_connection.txt is generated with a ready-to-use psql connection string.
- The container entrypoint uses startup.sh exclusively to setup and run PostgreSQL.
- Container startup never installs Node modules and never runs npm/node or the db_visualizer.

Environment configuration:
- Optional .env file can be placed in secure-crm-platform-40906-40916/crm_database/.env
- Variables supported:
  - POSTGRES_DB (default: myapp)
  - POSTGRES_USER (default: appuser)
  - POSTGRES_PASSWORD (default: dbuser123)
  - POSTGRES_PORT (default: 5000)
- If any variables are absent, startup.sh sets safe defaults and logs a clear warning. Missing .env files never cause errors.
- See .env.example in this directory for a template.

db_visualizer policy (out-of-scope for container runtime):
- db_visualizer is NEVER started by this container (nor by Dockerfile/compose). It is a manual-only helper.
- db_visualizer has been moved to: secure-crm-platform-40906-40916/tools/db_visualizer
- To run manually on your host:
  1) cd secure-crm-platform-40906-40916/tools/db_visualizer
  2) source postgres.env
  3) export DATABASE_URL="$POSTGRES_URL"
  4) nvm use 18 && npm ci && npm run start

Notes:
- Do not run db_visualizer inside the database container. It is not installed or launched during image build or container startup.
- Build and runtime logs for this container should only show PostgreSQL initialization/readiness; there should be no Node/npm output.
