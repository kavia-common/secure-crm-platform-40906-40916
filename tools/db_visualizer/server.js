const express = require('express');
const path = require('path');
const fs = require('fs');

// Guard: Require DATABASE_URL for primary connection context
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set.');
  console.error('To run locally, execute:');
  console.error('  cd secure-crm-platform-40906-40916/tools/db_visualizer');
  console.error('  source postgres.env');
  console.error('  export DATABASE_URL="$POSTGRES_URL"');
  console.error('  nvm use 18 && npm ci && npm run start');
  process.exit(1);
}

// Database client (PostgreSQL only)
const { Pool } = require('pg');

const app = express();
app.use((req, res, next) => {
  // Set headers to allow embedding in iframes
  res.setHeader('X-Frame-Options', 'ALLOWALL');
  res.setHeader('Content-Security-Policy', "frame-ancestors *;");

  // CORS headers
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,PATCH,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }
  next();
});
app.use(express.static(path.join(__dirname, 'public')));

// Load environment variables from postgres.env (local helper)
function loadPostgresEnv() {
  const filePath = 'postgres.env';
  const loaded = {};
  if (!fs.existsSync(filePath)) return { ...process.env };

  try {
    const content = fs.readFileSync(filePath, 'utf8');
    let varsLoaded = 0;
    content.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && trimmed.startsWith('export ')) {
        const exportLine = trimmed.substring(7);
        const [key, ...valueParts] = exportLine.split('=');
        if (key && valueParts.length > 0) {
          let value = valueParts.join('=');
          if ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'"))) {
            value = value.slice(1, -1);
          }
          loaded[key] = value;
          varsLoaded++;
        }
      }
    });
    console.log(`✓ postgres.env loaded (${varsLoaded} variables)`);
  } catch (e) {
    console.log(`✗ Error loading postgres.env: ${e.message}`);
  }
  return { ...process.env, ...loaded };
}

const env = loadPostgresEnv();

// Build Postgres config from env
const pgConfig = {
  host: 'localhost',
  port: Number(env.POSTGRES_PORT || 5432),
  user: env.POSTGRES_USER || 'postgres',
  password: env.POSTGRES_PASSWORD || '',
  database: env.POSTGRES_DB || 'postgres'
};

// Adapter for Postgres
class PostgresAdapter {
  constructor(config) {
    this.config = config;
  }
  async execute(query) {
    const pool = new Pool(this.config);
    try {
      const result = await pool.query(query);
      return result.rows;
    } finally {
      await pool.end();
    }
  }
  async testConnection() {
    await this.execute('SELECT 1');
  }
  getTables() {
    const q = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'";
    return this.execute(q);
  }
  getData(table, limit) {
    const safeLimit = Number.isFinite(Number(limit)) ? Number(limit) : 50;
    return this.execute(`SELECT * FROM "${table}" LIMIT ${safeLimit}`);
  }
}

const pgAdapter = new PostgresAdapter(pgConfig);

// API Routes
app.get('/api/databases', async (_req, res) => {
  try {
    await pgAdapter.testConnection();
    res.json(['postgres']);
  } catch (e) {
    res.json([]);
  }
});

app.get('/api/postgres/tables', async (_req, res) => {
  try {
    const rows = await pgAdapter.getTables();
    const formatted = rows.map(r => ({ table_name: r.table_name || Object.values(r)[0] }));
    res.json(formatted);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/postgres/tables/:table/data', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const rows = await pgAdapter.getData(req.params.table, limit);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/', (_req, res) => {
  res.send(`
    <html>
      <head><title>PostgreSQL Viewer</title></head>
      <body>
        <h1>PostgreSQL Viewer</h1>
        <p>Use the following endpoints:</p>
        <ul>
          <li>GET /api/databases</li>
          <li>GET /api/postgres/tables</li>
          <li>GET /api/postgres/tables/:table/data?limit=50</li>
        </ul>
      </body>
    </html>
  `);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Database viewer running on http://localhost:${PORT}`);
  console.log('\nEnvironment variables expected:');
  console.log('PostgreSQL: POSTGRES_URL, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_PORT');
});
