BEGIN;

CREATE TABLE IF NOT EXISTS settings (
  id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  store_name VARCHAR(150) NOT NULL DEFAULT 'BingGo',
  address TEXT NOT NULL DEFAULT '',
  wifi_password VARCHAR(255) NOT NULL DEFAULT '',
  tax_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  tax_rate NUMERIC(5,2) NOT NULL DEFAULT 10 CHECK (tax_rate >= 0 AND tax_rate <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO settings (id, store_name, address, wifi_password, tax_enabled, tax_rate)
VALUES (1, 'BingGo', '', '', FALSE, 10)
ON CONFLICT (id) DO NOTHING;

COMMIT;
