# crm_database (PostgreSQL) – Secure Setup

This container runs PostgreSQL only. It does not run any Node/Express processes.

Key points:
- PostgreSQL listens on localhost at the configured port (default 5000).
- Authentication is password-based (md5 / scram-sha-256 when supported).
- pg_hba.conf is provided to avoid any trust auth warnings and enforce password auth.
- A convenience file db_connection.txt is generated with a ready-to-use psql connection string.
- The container entrypoint uses startup.sh exclusively to setup and run PostgreSQL.

Optional helper (NOT part of this container):
- db_visualizer is a lightweight Node tool meant to run separately for quick inspection.
- To use it outside the DB container:
  1) cd secure-crm-platform-40906-40916/crm_database/db_visualizer
  2) source postgres.env
  3) npm ci
  4) npm run start

Do not run db_visualizer inside the database container. It is not installed or launched during image build or container startup.
