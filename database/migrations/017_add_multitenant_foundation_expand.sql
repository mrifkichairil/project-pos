BEGIN;

CREATE TABLE IF NOT EXISTS tenants (
  id BIGSERIAL PRIMARY KEY,
  slug VARCHAR(120) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_tenants (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'cashier' CHECK (role IN ('admin', 'manager', 'cashier')),
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, tenant_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_tenants_default
  ON user_tenants(user_id)
  WHERE is_default = TRUE;

CREATE TABLE IF NOT EXISTS auth_sessions (
  id BIGSERIAL PRIMARY KEY,
  session_token VARCHAR(255) NOT NULL UNIQUE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active_tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS active_tenant_id BIGINT;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_users_active_tenant'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT fk_users_active_tenant
      FOREIGN KEY (active_tenant_id) REFERENCES tenants(id) ON DELETE SET NULL;
  END IF;
END $$;

ALTER TABLE menus ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE members ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE rewards ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE member_transactions ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE member_point_ledger ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE sales_orders ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE stock_movements ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE dining_tables ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE addons ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE menu_addon_assignments ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
DO $$
BEGIN
  IF to_regclass('public.user_social_accounts') IS NOT NULL THEN
    ALTER TABLE user_social_accounts ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_menus_tenant_id ON menus(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_tenant_id ON ingredients(tenant_id);
CREATE INDEX IF NOT EXISTS idx_settings_tenant_id ON settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_members_tenant_id ON members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_tenant_id ON sales_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_addons_tenant_id ON addons(tenant_id);
DO $$
BEGIN
  IF to_regclass('public.user_social_accounts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_user_social_accounts_tenant_id ON user_social_accounts(tenant_id);
  END IF;
END $$;

COMMIT;
