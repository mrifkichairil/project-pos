BEGIN;

ALTER TABLE menus ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE ingredients ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE settings ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE members ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE rewards ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE member_transactions ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE member_point_ledger ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE sales_orders ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE stock_movements ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE dining_tables ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE addons ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE menu_addon_assignments ALTER COLUMN tenant_id SET NOT NULL;
DO $$
BEGIN
  IF to_regclass('public.user_social_accounts') IS NOT NULL THEN
    ALTER TABLE user_social_accounts ALTER COLUMN tenant_id SET NOT NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_menus_tenant') THEN
    ALTER TABLE menus ADD CONSTRAINT fk_menus_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ingredients_tenant') THEN
    ALTER TABLE ingredients ADD CONSTRAINT fk_ingredients_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_settings_tenant') THEN
    ALTER TABLE settings ADD CONSTRAINT fk_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sales_orders_tenant') THEN
    ALTER TABLE sales_orders ADD CONSTRAINT fk_sales_orders_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
  END IF;
END $$;

ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE settings ADD PRIMARY KEY (tenant_id);

DROP INDEX IF EXISTS idx_menus_category;
DROP INDEX IF EXISTS uq_menu_prices_active;
DROP INDEX IF EXISTS uq_menu_prices_menu_start_date;

CREATE UNIQUE INDEX IF NOT EXISTS uq_menus_tenant_name ON menus(tenant_id, name);
CREATE INDEX IF NOT EXISTS idx_menus_tenant_category ON menus(tenant_id, category);
CREATE UNIQUE INDEX IF NOT EXISTS uq_ingredients_tenant_name ON ingredients(tenant_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_active_per_tenant
  ON menu_prices(menu_id)
  WHERE is_active;
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_menu_start_date_per_tenant
  ON menu_prices(menu_id, start_date);

COMMIT;
