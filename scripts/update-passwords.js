const { Pool } = require("pg");
const bcrypt = require("bcryptjs");

const DATABASE_URL = "postgresql://neondb_owner:npg_lP5dOLiQoAv7@ep-lingering-voice-apv6dy88-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require";

async function main() {
  const pool = new Pool({ connectionString: DATABASE_URL });

  const updates = [
    { username: "admin", password: "CaramelFrappe" },
    { username: "manager_a", password: "ManagerA2026!" },
    { username: "manager_b", password: "ManagerB2026!" },
  ];

  for (const u of updates) {
    const hash = await bcrypt.hash(u.password, 10);
    const result = await pool.query(
      "UPDATE users SET password = $1, updated_at = NOW() WHERE username = $2",
      [hash, u.username]
    );
    if (result.rowCount > 0) {
      console.log(`✓ ${u.username} password updated`);
    } else {
      console.log(`✗ ${u.username} not found`);
    }
  }

  await pool.end();
  console.log("\nDone!");
}

main().catch(console.error);
