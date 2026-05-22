BEGIN;

INSERT INTO tenants (slug, name, status)
VALUES ('default', 'Default Tenant', 'active')
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    status = EXCLUDED.status,
    updated_at = NOW();

WITH default_tenant AS (
  SELECT id FROM tenants WHERE slug = 'default' LIMIT 1
)
UPDATE users u
SET active_tenant_id = dt.id
FROM default_tenant dt
WHERE u.active_tenant_id IS NULL;

WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
INSERT INTO user_tenants (user_id, tenant_id, role, is_default)
SELECT u.id, dt.id, u.role, TRUE
FROM users u
CROSS JOIN default_tenant dt
ON CONFLICT (user_id, tenant_id) DO NOTHING;

WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE menus SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE ingredients SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE settings SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE members SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE rewards SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE member_transactions SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE member_point_ledger SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE sales_orders SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE stock_movements SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE dining_tables SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE addons SET tenant_id = dt.id FROM default_tenant dt WHERE tenant_id IS NULL;
DO $$
BEGIN
  IF to_regclass('public.user_social_accounts') IS NOT NULL THEN
    WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
    UPDATE user_social_accounts
    SET tenant_id = dt.id
    FROM default_tenant dt
    WHERE tenant_id IS NULL;
  END IF;
END $$;

WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE menu_addon_assignments maa
SET tenant_id = m.tenant_id
FROM menus m
WHERE maa.menu_id = m.id
  AND maa.tenant_id IS NULL;

COMMIT;
