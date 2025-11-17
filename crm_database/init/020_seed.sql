-- Optional seed data for local development and quick verification.
-- Safe to remove in production images if not needed.

BEGIN;
SET search_path TO crm, public;

INSERT INTO customers (first_name, last_name, email, phone, segment)
VALUES
  ('Asha', 'Patel', 'asha.patel@example.com', '+1-555-123-0001', 'Retail'),
  ('Rahul', 'Mehta', 'rahul.mehta@example.com', '+1-555-123-0002', 'SMB')
ON CONFLICT DO NOTHING;

-- Link a sample service request
INSERT INTO service_requests (customer_id, request_type, status, priority, subject, description, created_by)
SELECT id, 'support', 'new', 'normal', 'Onboarding assistance', 'Need help configuring initial settings', 'system'
FROM customers
WHERE email = 'asha.patel@example.com'
ON CONFLICT DO NOTHING;

-- Add a sample interaction
INSERT INTO interactions (customer_id, channel, direction, subject, content)
SELECT id, 'email', 'inbound', 'Welcome email', 'Customer replied to welcome email.'
FROM customers
WHERE email = 'asha.patel@example.com'
ON CONFLICT DO NOTHING;

COMMIT;
