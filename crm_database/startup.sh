#!/bin/bash
set -euo pipefail

# Minimal PostgreSQL startup script with secure authentication and no Node/Express
# CRITICAL: This script MUST NEVER install or run npm, yarn, node, or start db_visualizer.
# It only prepares a postgres.env for optional manual use outside the container.

echo "[crm_database] Starting PostgreSQL setup..."

# 1) Safe env loading with conditional sourcing (no globbing, no cat on *.env)
#    - Local .env in container root (optional)
#    - Known helper envs in tools if present (optional)
if [ -f ".env" ]; then
  echo "[crm_database] Loading .env from project root"
  set -a
  . ./.env
  set +a
else
  echo "[crm_database] No .env found in container root (optional; continuing with defaults)"
fi

# Optional: source tools/db_visualizer/postgres.env if exists (for convenience only)
if [ -f "../tools/db_visualizer/postgres.env" ]; then
  echo "[crm_database] Loading tools/db_visualizer/postgres.env (optional)"
  set -a
  . ../tools/db_visualizer/postgres.env
  set +a
fi

# Optional: source in-container stub if exists
if [ -f "./db_visualizer/postgres.env" ]; then
  echo "[crm_database] Loading crm_database/db_visualizer/postgres.env (optional)"
  set -a
  . ./db_visualizer/postgres.env
  set +a
fi

# 2) Required variables with safe defaults + warnings (do not exit non-zero)
DB_NAME="${POSTGRES_DB:-${DB_NAME:-myapp}}"
DB_USER="${POSTGRES_USER:-${DB_USER:-appuser}}"
DB_PASSWORD="${POSTGRES_PASSWORD:-${DB_PASSWORD:-dbuser123}}"
DB_PORT="${POSTGRES_PORT:-${DB_PORT:-5000}}"

# Warn if any were absent and we fell back to defaults
[ -z "${POSTGRES_DB:-}" ] && echo "[crm_database][warn] POSTGRES_DB not set; defaulting to '${DB_NAME}'"
[ -z "${POSTGRES_USER:-}" ] && echo "[crm_database][warn] POSTGRES_USER not set; defaulting to '${DB_USER}'"
[ -z "${POSTGRES_PASSWORD:-}" ] && echo "[crm_database][warn] POSTGRES_PASSWORD not set; defaulting to '${DB_PASSWORD}'"
[ -z "${POSTGRES_PORT:-}" ] && echo "[crm_database][warn] POSTGRES_PORT not set; defaulting to '${DB_PORT}'"

# Find PostgreSQL version and set paths
PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PG_DATA="/var/lib/postgresql/data"
POSTGRESQL_CONF="${PG_DATA}/postgresql.conf"
PG_PIDFILE="${PG_DATA}/postmaster.pid"

echo "[crm_database] Found PostgreSQL version: ${PG_VERSION}"

# Helper: check if any process is listening on DB_PORT (fallback if pg_isready not sufficient)
is_port_in_use() {
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | awk '{print $4}' | grep -q ":${DB_PORT}\$"
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ltn | awk '{print $4}' | grep -q ":${DB_PORT}\$"
  else
    # As a safe fallback, try connecting using pg_isready
    sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} >/dev/null 2>&1
  fi
}

# Initialize PostgreSQL data directory if it doesn't exist
if [ ! -f "${PG_DATA}/PG_VERSION" ]; then
  echo "[crm_database] Initializing PostgreSQL data directory..."
  sudo -u postgres ${PG_BIN}/initdb -D "${PG_DATA}"

  # Set basic configuration
  {
    echo "listen_addresses = 'localhost'"
    echo "port = ${DB_PORT}"
    # Use scram when supported; md5 entries in pg_hba still work with scram-encrypted passwords
    echo "password_encryption = scram-sha-256"
  } >> "${POSTGRESQL_CONF}"

  # Install our pg_hba.conf policy (md5-based rules)
  if [ -f "./pg_hba.conf" ]; then
    cp ./pg_hba.conf "${PG_DATA}/pg_hba.conf"
  else
    cat > "${PG_DATA}/pg_hba.conf" <<HBA
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
HBA
  fi
else
  # Ensure port and listen settings exist
  if ! grep -q "port = ${DB_PORT}" "${POSTGRESQL_CONF}" 2>/dev/null; then
    echo "[crm_database] Enforcing port ${DB_PORT} and localhost listen in postgresql.conf"
    {
      echo "listen_addresses = 'localhost'"
      echo "port = ${DB_PORT}"
    } >> "${POSTGRESQL_CONF}"
  fi
  # Refresh pg_hba.conf from repository config each start to avoid trust auth warnings
  if [ -f "./pg_hba.conf" ]; then
    cp ./pg_hba.conf "${PG_DATA}/pg_hba.conf"
  fi
fi

# Robust lock/port checks: don't start if already running
already_ready=false
if sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} >/dev/null 2>&1; then
  already_ready=true
fi

if [ -f "${PG_PIDFILE}" ] && ps -p "$(head -n1 "${PG_PIDFILE}" 2>/dev/null || echo 0)" >/dev/null 2>&1; then
  echo "[crm_database] Detected running PostgreSQL via pidfile at ${PG_PIDFILE}"
  already_ready=true
fi

if is_port_in_use; then
  echo "[crm_database] Detected an active listener on port ${DB_PORT}. Assuming PostgreSQL is running."
  already_ready=true
fi

if [ "${already_ready}" = true ]; then
  echo "[crm_database] PostgreSQL is already running. Skipping server start."
else
  # Start PostgreSQL server in background
  echo "[crm_database] Starting PostgreSQL server..."
  sudo -u postgres ${PG_BIN}/postgres -D "${PG_DATA}" -p ${DB_PORT} &

  # Wait for PostgreSQL to start
  echo "[crm_database] Waiting for PostgreSQL to start..."
  for i in {1..30}; do
    if sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} > /dev/null 2>&1; then
      echo "[crm_database] PostgreSQL is ready!"
      break
    fi
    echo "  waiting... ($i/30)"
    sleep 1
  done
fi

# Ensure database exists
echo "[crm_database] Ensuring database and user exist..."
# Create database if not exists (idempotent)
sudo -u postgres ${PG_BIN}/createdb -p ${DB_PORT} "${DB_NAME}" 2>/dev/null || true

# Create or update user and grant privileges
sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -d postgres << EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}';
    ELSE
        ALTER ROLE ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
    END IF;
END
\$\$;
EOF

# Schema and default privileges in target DB
sudo -u postgres ${PG_BIN}/psql -p ${DB_PORT} -d ${DB_NAME} << EOF
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${DB_USER};
EOF

# Save connection helper
echo "psql postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}" > db_connection.txt
echo "[crm_database] Connection string saved to db_connection.txt"

# Save environment variables for optional db_visualizer helper tool (NOT started automatically)
mkdir -p db_visualizer
cat > db_visualizer/postgres.env << EOF
export POSTGRES_URL="postgresql://localhost:${DB_PORT}/${DB_NAME}"
export POSTGRES_USER="${DB_USER}"
export POSTGRES_PASSWORD="${DB_PASSWORD}"
export POSTGRES_DB="${DB_NAME}"
export POSTGRES_PORT="${DB_PORT}"
EOF

echo "[crm_database] PostgreSQL setup complete!"
echo "  Database: ${DB_NAME}"
echo "  User:     ${DB_USER}"
echo "  Port:     ${DB_PORT}"
echo ""
echo "Note: db_visualizer is an optional helper. It is NOT started by this container."
echo "To use it outside the DB container (on your host):"
echo "  cd secure-crm-platform-40906-40916/crm_database/db_visualizer"
echo "  source postgres.env"
echo "  export DATABASE_URL=\"\$POSTGRES_URL\""
echo "  npm ci && npm run start"

# Exit with 0 when PostgreSQL is healthy (warn if not)
if sudo -u postgres ${PG_BIN}/pg_isready -p ${DB_PORT} >/dev/null 2>&1; then
  echo "[crm_database] PostgreSQL health check passed."
  exit 0
else
  echo "[crm_database][warn] pg_isready failed after setup; check logs."
  # Exit non-zero only if PostgreSQL is actually not ready; absence of env files never causes failure earlier.
  exit 1
fi
