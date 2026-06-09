const { Pool } = require("pg");
const DATABASE_URL = "postgresql://neondb_owner:npg_lP5dOLiQoAv7@ep-lingering-voice-apv6dy88-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require";
const pool = new Pool({ connectionString: DATABASE_URL });
pool.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename")
  .then(r => { console.log("Tables:\n" + r.rows.map(x => "  - " + x.tablename).join("\n")); pool.end(); })
  .catch(e => { console.error(e.message); pool.end(); });
