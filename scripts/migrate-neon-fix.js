const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");

const DATABASE_URL = "postgresql://neondb_owner:npg_lP5dOLiQoAv7@ep-lingering-voice-apv6dy88-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require";

async function main() {
  const pool = new Pool({ connectionString: DATABASE_URL });

  // First, create the users table which is missing from migrations
  console.log("Creating users table...\n");
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id BIGSERIAL PRIMARY KEY,
      fullname VARCHAR(160) NOT NULL,
      username VARCHAR(80) UNIQUE,
      email VARCHAR(160) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      phone VARCHAR(30),
      role VARCHAR(20) NOT NULL DEFAULT 'cashier' CHECK (role IN ('admin', 'manager', 'cashier')),
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      active_tenant_id BIGINT,
      subscription_status VARCHAR(20) DEFAULT 'inactive',
      subscription_start TIMESTAMPTZ,
      subscription_end TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
  console.log("✓ users table created\n");

  // Now run the failed migrations in order
  const failedMigrations = [
    "015_add_users_table.sql",
    "016_add_social_login_support.sql",
    "017_add_multitenant_foundation_expand.sql",
    "018_backfill_multitenant_default_tenant.sql",
    "019_enforce_multitenant_constraints_contract.sql",
    "020_seed_superadmin.sql",
    "024_add_subscription_to_users.sql",
    "025_add_phone_to_users.sql",
    "027_fix_settings_id_autoincrement.sql",
  ];

  const migrationsDir = path.join(__dirname, "..", "database", "migrations");

  for (const file of failedMigrations) {
    const filePath = path.join(migrationsDir, file);
    if (!fs.existsSync(filePath)) {
      console.log(`⊘ ${file} (not found, skipping)`);
      continue;
    }
    const sql = fs.readFileSync(filePath, "utf8");
    try {
      await pool.query(sql);
      console.log(`✓ ${file}`);
    } catch (err) {
      console.error(`✗ ${file}: ${err.message}`);
    }
  }

  await pool.end();
  console.log("\nDone!");
}

main().catch(console.error);
