# syntax=docker/dockerfile:1.6
# CRM Database container based on official PostgreSQL image.
# Purpose: Provide a clean, secure PostgreSQL setup for the CRM system with init scripts.
# Note: No references to any 'db_visualizer' directory are present.

FROM postgres:16-alpine

LABEL org.opencontainers.image.source="secure-crm-platform-40906-40916/crm_database" \
      org.opencontainers.image.title="CRM Database (PostgreSQL)" \
      org.opencontainers.image.description="PostgreSQL database for the CRM system with schema initialization scripts." \
      org.opencontainers.image.version="0.1.0"

# Copy initialization scripts. These are executed on first container start when PGDATA is empty.
# We copy the entire init directory to avoid wildcard COPY failures if no files match.
COPY ./init/ /docker-entrypoint-initdb.d/

# Expose default PostgreSQL port
EXPOSE 5432

# Healthcheck to ensure the server is ready to accept connections.
# Uses POSTGRES_USER if provided, defaults to 'postgres' user.
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=10 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} || exit 1

# The official image provides the entrypoint and CMD. No custom entrypoint required.
# ENV variables must be provided at runtime (do not hardcode secrets here):
#   - POSTGRES_DB
#   - POSTGRES_USER
#   - POSTGRES_PASSWORD
