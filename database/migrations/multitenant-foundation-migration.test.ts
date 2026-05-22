import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

describe("multitenant foundation migrations", () => {
  it("defines expand, backfill, and contract migrations", () => {
    const expand = readFileSync(
      join(process.cwd(), "database", "migrations", "017_add_multitenant_foundation_expand.sql"),
      "utf-8"
    );
    const backfill = readFileSync(
      join(process.cwd(), "database", "migrations", "018_backfill_multitenant_default_tenant.sql"),
      "utf-8"
    );
    const contract = readFileSync(
      join(process.cwd(), "database", "migrations", "019_enforce_multitenant_constraints_contract.sql"),
      "utf-8"
    );

    expect(expand).toContain("CREATE TABLE IF NOT EXISTS tenants");
    expect(expand).toContain("CREATE TABLE IF NOT EXISTS user_tenants");
    expect(expand).toContain("CREATE TABLE IF NOT EXISTS auth_sessions");
    expect(expand).toContain("ALTER TABLE menus ADD COLUMN IF NOT EXISTS tenant_id");

    expect(backfill).toContain("INSERT INTO tenants");
    expect(backfill).toContain("UPDATE menus SET tenant_id");
    expect(backfill).toContain("UPDATE settings SET tenant_id");

    expect(contract).toContain("ALTER TABLE menus ALTER COLUMN tenant_id SET NOT NULL");
    expect(contract).toContain("DROP INDEX IF EXISTS uq_menu_prices_active");
    expect(contract).toContain("CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_active_per_tenant");
  });
});
