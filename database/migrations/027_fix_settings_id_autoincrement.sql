-- Fix settings.id to be auto-increment instead of all being 1
ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_id_check;

CREATE SEQUENCE IF NOT EXISTS settings_id_seq;

WITH numbered AS (
  SELECT ctid, ROW_NUMBER() OVER (ORDER BY tenant_id) AS rn
  FROM settings
)
UPDATE settings SET id = numbered.rn
FROM numbered WHERE settings.ctid = numbered.ctid;

SELECT setval('settings_id_seq', COALESCE((SELECT MAX(id) FROM settings), 0));

ALTER TABLE settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq');

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;
