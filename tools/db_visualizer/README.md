# db_visualizer (Optional Helper - Manual Only)

This is an optional Node-based PostgreSQL viewer. It is NOT part of the database container runtime and is never started by startup.sh, Dockerfile, or docker-compose.

Manual run (outside any container):
1) cd secure-crm-platform-40906-40916/tools/db_visualizer
2) source postgres.env
3) export DATABASE_URL="$POSTGRES_URL"   # server requires DATABASE_URL
4) nvm use 18
5) npm ci
6) npm run start

Requirements:
- Node.js v18 (use nvm with an .nvmrc if present in your environment)
- Database must already be running and accessible on the configured port

Notes:
- Dependencies are trimmed for a Postgres-only helper (pg + express). No sqlite3 or other native modules that require compilation.
- If you see MODULE_NOT_FOUND errors, ensure you ran npm ci on Node 18 and that you are not inside the database container.
- This tool is optional and not required for the CRM to operate.
- The server will exit with an error if DATABASE_URL is not set; source postgres.env and export DATABASE_URL first.
