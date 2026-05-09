import { Pool } from "pg";

const globalForDb = globalThis as unknown as { dbPool?: Pool };

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not configured");
}

export const db =
  globalForDb.dbPool ??
  new Pool({
    connectionString: process.env.DATABASE_URL,
  });

if (process.env.NODE_ENV !== "production") {
  globalForDb.dbPool = db;
}
