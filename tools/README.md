# tools/

This directory contains optional developer tools that must not be built into or started by containers.
- db_visualizer: Manual-only Node.js helper to browse the PostgreSQL database.

Policy:
- Do NOT reference this directory from Dockerfiles or docker-compose services intended for runtime images.
- Run tools locally on your host machine only.
