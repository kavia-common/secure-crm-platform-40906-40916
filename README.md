# secure-crm-platform-40906-40916

Developer notes:
- The PostgreSQL database container (crm_database) must not install or run Node/npm at build or runtime.
- The optional db_visualizer helper has been relocated to tools/db_visualizer and is manual-only.
- To use it:
  1) cd secure-crm-platform-40906-40916/tools/db_visualizer
  2) source postgres.env
  3) export DATABASE_URL="$POSTGRES_URL"
  4) nvm use 18 && npm ci && npm run start