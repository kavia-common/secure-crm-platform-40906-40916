# Docker Entrypoint Notes

This database container must use startup.sh as the sole entrypoint/command for PostgreSQL setup and start.

- Do NOT start any Node/Express apps (e.g., db_visualizer) from the Dockerfile or docker-compose.
- Ensure Dockerfile CMD/ENTRYPOINT executes: `./startup.sh`
- Ensure docker-compose `command` does not override with anything that starts db_visualizer.
- Dockerfile and docker-compose must not install Node, run npm, or reference db_visualizer.
- db_visualizer has been moved to tools/db_visualizer and is outside the DB image context.

Runtime success criteria:
- startup.sh never invokes npm, yarn, or node, and makes no references to db_visualizer beyond writing postgres.env.
- Container exits 0 from startup.sh when Postgres is healthy, regardless of db_visualizer state.

Validation checklist:
- Container builds without installing Node modules for db_visualizer.
- Container starts and binds PostgreSQL on the configured port (default 5000).
- No Node/Express MODULE_NOT_FOUND or related errors during build/run.
- Startup logs show only PostgreSQL initialization and readiness checks. No "npm", "node", or "express" output.
