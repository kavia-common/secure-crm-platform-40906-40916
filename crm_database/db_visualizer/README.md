# db_visualizer (Optional Helper)

This is an optional Node-based database viewer. It is NOT part of the database container runtime and is not started by startup.sh or Docker entrypoints.

How to run locally (separate from DB container):
1) cd secure-crm-platform-40906-40916/crm_database/db_visualizer
2) source postgres.env
3) npm ci
4) npm run start

Requirements:
- Node.js v18+ installed on your host or a separate tools container
- Database must already be running and accessible on the configured port

Notes:
- express is pinned to 4.18.2 for compatibility.
- If you see MODULE_NOT_FOUND errors, ensure you ran npm ci in this folder and not inside the database container.
- This tool is optional and not required for the CRM to operate.
