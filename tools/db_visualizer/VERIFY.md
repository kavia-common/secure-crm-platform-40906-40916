# db_visualizer Verification (Manual)

Prereqs:
- Node 18.x (use nvm)
- Database running locally per crm_database

Steps:
1) cd secure-crm-platform-40906-40916/tools/db_visualizer
2) source postgres.env
3) export DATABASE_URL="$POSTGRES_URL"
4) npm ci
5) npm run start

Expected:
- No MODULE_NOT_FOUND errors
- Server logs: "Database viewer running on http://localhost:3000"
- GET http://localhost:3000/api/databases returns ["postgres"] if Postgres is reachable.
