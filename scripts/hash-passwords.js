const { Pool } = require("pg");
const bcrypt = require("bcryptjs");

const DATABASE_URL = "postgresql://neondb_owner:npg_lP5dOLiQoAv7@ep-lingering-voice-apv6dy88-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require";

async function main() {
  const pool = new Pool({ connectionString: DATABASE_URL });

  // Get all users with unhashed passwords (bcrypt hashes start with $2a$ or $2b$)
  const result = await pool.query(
    "SELECT id, username, password FROM users WHERE password NOT LIKE '$2a$%' AND password NOT LIKE '$2b$%'"
  );

  console.log(`Found ${result.rows.length} users with unhashed passwords\n`);

  for (const user of result.rows) {
    const hash = await bcrypt.hash(user.password, 10);
    await pool.query("UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2", [hash, user.id]);
    console.log(`✓ ${user.username} — hashed`);
  }

  await pool.end();
  console.log("\nDone!");
}

main().catch(console.error);
