-- Core CRM schema and tables.
-- Executed automatically on first DB initialization.

BEGIN;

-- Use a dedicated schema for the CRM
CREATE SCHEMA IF NOT EXISTS crm;

-- Ensure search path uses crm first
SET search_path TO crm, public;

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id      varchar(64),
  first_name       varchar(100) NOT NULL,
  last_name        varchar(100) NOT NULL,
  email            varchar(255),
  phone            varchar(50),
  segment          varchar(50),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers (email);
CREATE INDEX IF NOT EXISTS idx_customers_external_id ON customers (external_id);

-- Service Requests
CREATE TABLE IF NOT EXISTS service_requests (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id      uuid REFERENCES customers(id) ON DELETE SET NULL,
  request_type     varchar(100) NOT NULL,
  status           varchar(32) NOT NULL DEFAULT 'new',  -- new, in_progress, resolved, closed
  priority         varchar(16) NOT NULL DEFAULT 'normal', -- low, normal, high, urgent
  subject          varchar(255),
  description      text,
  assigned_to      varchar(100),
  created_by       varchar(100),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT service_requests_status_chk CHECK (status IN ('new','in_progress','resolved','closed')),
  CONSTRAINT service_requests_priority_chk CHECK (priority IN ('low','normal','high','urgent'))
);

CREATE INDEX IF NOT EXISTS idx_service_requests_customer ON service_requests (customer_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_status ON service_requests (status);

-- Complaints (can be linked to a service request)
CREATE TABLE IF NOT EXISTS complaints (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id        uuid REFERENCES customers(id) ON DELETE SET NULL,
  service_request_id uuid REFERENCES service_requests(id) ON DELETE SET NULL,
  category           varchar(100),
  severity           varchar(16) NOT NULL DEFAULT 'medium', -- low, medium, high, critical
  description        text,
  status             varchar(32) NOT NULL DEFAULT 'open',   -- open, investigating, resolved, closed
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT complaints_severity_chk CHECK (severity IN ('low','medium','high','critical')),
  CONSTRAINT complaints_status_chk CHECK (status IN ('open','investigating','resolved','closed'))
);

CREATE INDEX IF NOT EXISTS idx_complaints_customer ON complaints (customer_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints (status);

-- Omni-channel interactions (email, chat, voice, social, etc.)
CREATE TABLE IF NOT EXISTS interactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id      uuid REFERENCES customers(id) ON DELETE SET NULL,
  service_request_id uuid REFERENCES service_requests(id) ON DELETE SET NULL,
  channel          varchar(32) NOT NULL, -- email, chat, voice, social, sms, web, mobile
  direction        varchar(16) NOT NULL DEFAULT 'inbound', -- inbound, outbound
  subject          varchar(255),
  content          text,
  metadata         jsonb DEFAULT '{}'::jsonb,
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_interactions_customer ON interactions (customer_id);
CREATE INDEX IF NOT EXISTS idx_interactions_channel ON interactions (channel);
CREATE INDEX IF NOT EXISTS idx_interactions_occurred_at ON interactions (occurred_at);

-- Audit logs for compliance and traceability
CREATE TABLE IF NOT EXISTS audit_logs (
  id              bigserial PRIMARY KEY,
  entity_type     varchar(64) NOT NULL,
  entity_id       uuid,
  action          varchar(64) NOT NULL, -- create, update, delete, status_change, etc.
  changed_by      varchar(100),
  changes         jsonb DEFAULT '{}'::jsonb,
  occurred_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_occurred_at ON audit_logs (occurred_at);

-- Workflow (simplified)
CREATE TABLE IF NOT EXISTS workflow_states (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           varchar(64) NOT NULL UNIQUE,
  description    text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS workflow_transitions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_state_id  uuid REFERENCES workflow_states(id) ON DELETE CASCADE,
  to_state_id    uuid REFERENCES workflow_states(id) ON DELETE CASCADE,
  role_required  varchar(64),
  condition      jsonb DEFAULT '{}'::jsonb
);

-- Basic updated_at trigger (optional, lightweight)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to applicable tables
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT tablename
    FROM pg_catalog.pg_tables
    WHERE schemaname = 'crm' AND tablename IN ('customers','service_requests','complaints')
  LOOP
    EXECUTE format('
      DO $do$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_trigger
          WHERE tgname = %L AND tgrelid = %s::regclass
        ) THEN
          CREATE TRIGGER %I
          BEFORE UPDATE ON %I
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        END IF;
      END
      $do$;
    ', rec.tablename || '_set_updated_at', 'crm.' || rec.tablename, rec.tablename || '_set_updated_at', rec.tablename);
  END LOOP;
END;
$$;

COMMIT;
