# Docker Entrypoint Notes

This database container must use startup.sh as the sole entrypoint/command for PostgreSQL setup and start.

- Do NOT start any Node/Express apps (e.g., db_visualizer) from the Dockerfile or docker-compose.
- Ensure Dockerfile CMD/ENTRYPOINT executes: `./startup.sh`
- Ensure docker-compose `command` does not override with anything that starts db_visualizer.

Validation checklist:
- Container builds without installing Node modules for db_visualizer.
- Container starts and binds PostgreSQL on the configured port (default 5000).
- No Node/Express MODULE_NOT_FOUND or related errors during build/run.
