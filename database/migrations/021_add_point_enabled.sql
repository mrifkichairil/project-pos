-- Add point_enabled column to settings table
ALTER TABLE settings ADD COLUMN IF NOT EXISTS point_enabled BOOLEAN NOT NULL DEFAULT TRUE;
