# db_visualizer (Optional Helper)

This is an optional Node-based database viewer. It is NOT part of the database container runtime and is never started by startup.sh, Dockerfile, or docker-compose.

How to run manually (separate from DB container):
1) cd secure-crm-platform-40906-40916/crm_database/db_visualizer
2) source postgres.env
3) export DATABASE_URL="$POSTGRES_URL"   # server requires DATABASE_URL
4) npm ci && npm run start

Requirements:
- Node.js v18 (use nvm with the included .nvmrc for consistency)
- Database must already be running and accessible on the configured port

Notes:
- express is pinned to 4.18.2 for compatibility, with related transitive packages pinned to avoid lock mismatches.
- If you see MODULE_NOT_FOUND errors, ensure you are running this outside the database container.
- This tool is optional and not required for the CRM to operate.
- Do NOT attempt to run inside the database container. The DB image does not include Node/npm and will not start this tool.
- The server will exit with an error if DATABASE_URL is not set; source postgres.env and export DATABASE_URL first.
