-- Initialize required extensions for the CRM database.
-- Executed automatically by the official PostgreSQL entrypoint on first initialization.

BEGIN;

-- Provides gen_random_uuid() and crypto utilities
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Provides uuid_generate_v4() and related functions (optional)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

COMMIT;
