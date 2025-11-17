# db_visualizer moved

db_visualizer has been moved out of the database container context to prevent any npm/node activity during image build or runtime.

New location:
../tools/db_visualizer

Run manually from the host:
1) cd secure-crm-platform-40906-40916/tools/db_visualizer
2) source postgres.env
3) export DATABASE_URL="$POSTGRES_URL"
4) nvm use 18 && npm ci && npm run start

Note:
- This folder exists as a stub only and is not used by the DB container.
- Do not place any Node project files here.
