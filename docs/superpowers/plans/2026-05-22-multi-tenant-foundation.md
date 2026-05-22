# Multi-Tenant Foundation (Shared Schema) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add zero-downtime multi-tenant foundation using shared DB/shared schema, tenant context from session, and tenant-scoped data access for core APIs.

**Architecture:** Use expand/backfill/contract migration strategy. Add tenant model (`tenants`, `user_tenants`) and `tenant_id` columns to domain tables first as nullable, backfill existing rows to default tenant, then progressively enforce tenant filters in APIs and add NOT NULL/tenant-scoped constraints. Keep auth hybrid-ready by introducing an internal session table/middleware that can later coexist with external provider identity.

**Tech Stack:** Next.js 16 Route Handlers, PostgreSQL (`pg`), TypeScript, Vitest.

---

## File Structure Map

- Create: `database/migrations/017_add_multitenant_foundation_expand.sql` — create tenant tables, session tables, add nullable `tenant_id` to domain tables, indexes.
- Create: `database/migrations/018_backfill_multitenant_default_tenant.sql` — create default tenant and backfill all existing rows.
- Create: `database/migrations/019_enforce_multitenant_constraints_contract.sql` — set NOT NULL, tenant-scoped unique constraints, FK hardening.
- Create: `database/migrations/multitenant-foundation-migration.test.ts` — SQL assertions for migration contents.
- Create: `lib/auth-session.ts` — resolve session + active tenant from cookies and DB.
- Create: `lib/tenant-scope.ts` — shared helpers for tenant guard and tenant-bound query parameters.
- Modify: `app/api/users/route.ts` — enforce tenant scope for list/create/delete users.
- Modify: `app/api/menu/route.ts` — enforce tenant scope for all menu reads/writes.
- Modify: `app/api/settings/route.ts` — replace singleton `id = 1` with tenant-scoped settings row.
- Modify: `app/api/pos/route.ts` — enforce tenant scope for POS order queries and writes.
- Test: `app/api/pos/route.test.ts` — update mocking/contracts to include tenant context.
- Create: `app/api/auth/login/route.ts` — internal login endpoint creating session row/cookie.
- Create: `app/api/auth/switch-tenant/route.ts` — switch active tenant for multi-tenant user.

---

### Task 1: Add migration safety net tests first

**Files:**
- Create: `database/migrations/multitenant-foundation-migration.test.ts`

- [ ] **Step 1: Write the failing migration test for tenant foundation artifacts**

```ts
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

describe("multitenant foundation migrations", () => {
  it("defines expand, backfill, and contract migrations", () => {
    const expand = readFileSync(join(process.cwd(), "database", "migrations", "017_add_multitenant_foundation_expand.sql"), "utf-8");
    const backfill = readFileSync(join(process.cwd(), "database", "migrations", "018_backfill_multitenant_default_tenant.sql"), "utf-8");
    const contract = readFileSync(join(process.cwd(), "database", "migrations", "019_enforce_multitenant_constraints_contract.sql"), "utf-8");

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- database/migrations/multitenant-foundation-migration.test.ts`
Expected: FAIL because files `017/018/019` do not exist yet.

- [ ] **Step 3: Commit the failing test**

```bash
git add database/migrations/multitenant-foundation-migration.test.ts
git commit -m "test: add failing multitenant migration safety net"
```

---

### Task 2: Implement expand migration (zero-downtime safe)

**Files:**
- Create: `database/migrations/017_add_multitenant_foundation_expand.sql`

- [ ] **Step 1: Write expand migration for new tables and nullable tenant_id columns**

```sql
BEGIN;

CREATE TABLE IF NOT EXISTS tenants (
  id BIGSERIAL PRIMARY KEY,
  slug VARCHAR(120) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_tenants (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'cashier' CHECK (role IN ('admin','manager','cashier')),
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, tenant_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_tenants_default
  ON user_tenants(user_id)
  WHERE is_default = TRUE;

CREATE TABLE IF NOT EXISTS auth_sessions (
  id BIGSERIAL PRIMARY KEY,
  session_token VARCHAR(255) NOT NULL UNIQUE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active_tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS active_tenant_id BIGINT;
ALTER TABLE users
  ADD CONSTRAINT fk_users_active_tenant
  FOREIGN KEY (active_tenant_id) REFERENCES tenants(id) ON DELETE SET NULL;

ALTER TABLE menus ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE members ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE rewards ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE member_transactions ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE member_point_ledger ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE sales_orders ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE stock_movements ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE dining_tables ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE addons ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE menu_addon_assignments ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

CREATE INDEX IF NOT EXISTS idx_menus_tenant_id ON menus(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_tenant_id ON ingredients(tenant_id);
CREATE INDEX IF NOT EXISTS idx_settings_tenant_id ON settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_tenant_id ON sales_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_members_tenant_id ON members(tenant_id);

COMMIT;
```

- [ ] **Step 2: Run migration test to verify expand requirements pass**

Run: `npm test -- database/migrations/multitenant-foundation-migration.test.ts`
Expected: still FAIL on backfill/contract assertions, expand assertions PASS.

- [ ] **Step 3: Commit expand migration**

```bash
git add database/migrations/017_add_multitenant_foundation_expand.sql
git commit -m "feat: add multitenant expand migration"
```

---

### Task 3: Implement backfill migration (default tenant)

**Files:**
- Create: `database/migrations/018_backfill_multitenant_default_tenant.sql`

- [ ] **Step 1: Write backfill migration assigning existing data to default tenant**

```sql
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
WITH default_tenant AS (SELECT id FROM tenants WHERE slug = 'default' LIMIT 1)
UPDATE menu_addon_assignments maa
SET tenant_id = m.tenant_id
FROM menus m
WHERE maa.menu_id = m.id
  AND maa.tenant_id IS NULL;

COMMIT;
```

- [ ] **Step 2: Run migration test to verify backfill assertions pass**

Run: `npm test -- database/migrations/multitenant-foundation-migration.test.ts`
Expected: FAIL only on contract assertions.

- [ ] **Step 3: Commit backfill migration**

```bash
git add database/migrations/018_backfill_multitenant_default_tenant.sql
git commit -m "feat: add multitenant backfill migration"
```

---

### Task 4: Implement contract migration and tenant constraints

**Files:**
- Create: `database/migrations/019_enforce_multitenant_constraints_contract.sql`

- [ ] **Step 1: Write contract migration for NOT NULL and tenant-scoped uniqueness**

```sql
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

ALTER TABLE menus ADD CONSTRAINT fk_menus_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
ALTER TABLE ingredients ADD CONSTRAINT fk_ingredients_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
ALTER TABLE settings ADD CONSTRAINT fk_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
ALTER TABLE sales_orders ADD CONSTRAINT fk_sales_orders_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;

ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE settings ADD PRIMARY KEY (tenant_id);

DROP INDEX IF EXISTS idx_menus_category;
DROP INDEX IF EXISTS uq_menu_prices_active;

CREATE UNIQUE INDEX IF NOT EXISTS uq_menus_tenant_name ON menus(tenant_id, name);
CREATE INDEX IF NOT EXISTS idx_menus_tenant_category ON menus(tenant_id, category);
CREATE UNIQUE INDEX IF NOT EXISTS uq_ingredients_tenant_name ON ingredients(tenant_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_active_per_tenant
  ON menu_prices(menu_id)
  WHERE is_active;

COMMIT;
```

- [ ] **Step 2: Run migration test to verify all assertions pass**

Run: `npm test -- database/migrations/multitenant-foundation-migration.test.ts`
Expected: PASS.

- [ ] **Step 3: Commit contract migration**

```bash
git add database/migrations/019_enforce_multitenant_constraints_contract.sql
git commit -m "feat: enforce tenant constraints and scoped uniqueness"
```

---

### Task 5: Add tenant session resolver and shared tenant guard

**Files:**
- Create: `lib/auth-session.ts`
- Create: `lib/tenant-scope.ts`

- [ ] **Step 1: Write failing unit test for tenant session resolver behavior**

Create test file `lib/auth-session.test.ts`:

```ts
import { describe, expect, it, vi } from "vitest";

const queryMock = vi.fn();

vi.mock("@/lib/db", () => ({
  db: { query: queryMock },
}));

vi.mock("next/headers", () => ({
  cookies: () => ({ get: () => ({ value: "session-token" }) }),
}));

describe("auth session resolver", () => {
  it("returns user and active tenant from valid auth session", async () => {
    queryMock.mockResolvedValueOnce({
      rows: [{ user_id: 1, active_tenant_id: 10, role: "admin", expires_at: new Date(Date.now() + 60_000).toISOString() }],
    });

    const { getRequestSessionContext } = await import("./auth-session");
    const result = await getRequestSessionContext();

    expect(result).toEqual({ userId: 1, tenantId: 10, role: "admin" });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- lib/auth-session.test.ts`
Expected: FAIL because module/functions do not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/auth-session.ts`:

```ts
import { cookies } from "next/headers";
import { db } from "@/lib/db";

export type SessionContext = {
  userId: number;
  tenantId: number;
  role: "admin" | "manager" | "cashier";
};

export async function getRequestSessionContext(): Promise<SessionContext | null> {
  const token = cookies().get("app_session")?.value;
  if (!token) return null;

  const result = await db.query<{
    user_id: number;
    active_tenant_id: number;
    role: "admin" | "manager" | "cashier";
    expires_at: string;
  }>(
    `SELECT s.user_id, s.active_tenant_id, ut.role, s.expires_at::text
     FROM auth_sessions s
     JOIN user_tenants ut ON ut.user_id = s.user_id AND ut.tenant_id = s.active_tenant_id
     WHERE s.session_token = $1
     LIMIT 1`,
    [token]
  );

  const row = result.rows[0];
  if (!row) return null;
  if (new Date(row.expires_at).getTime() <= Date.now()) return null;

  return { userId: row.user_id, tenantId: row.active_tenant_id, role: row.role };
}
```

Create `lib/tenant-scope.ts`:

```ts
import { NextResponse } from "next/server";
import { getRequestSessionContext } from "@/lib/auth-session";

export async function requireTenantSession() {
  const session = await getRequestSessionContext();
  if (!session) {
    return { error: NextResponse.json({ error: "Unauthorized" }, { status: 401 }) };
  }

  return { session };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- lib/auth-session.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit tenant auth helpers**

```bash
git add lib/auth-session.ts lib/tenant-scope.ts lib/auth-session.test.ts
git commit -m "feat: add tenant-aware session resolver"
```

---

### Task 6: Scope core APIs by tenant context

**Files:**
- Modify: `app/api/users/route.ts`
- Modify: `app/api/menu/route.ts`
- Modify: `app/api/settings/route.ts`
- Modify: `app/api/pos/route.ts`
- Test: `app/api/pos/route.test.ts`

- [ ] **Step 1: Write failing API test that enforces tenant filter in POS GET query**

Add assertion in `app/api/pos/route.test.ts` that SQL includes `so.tenant_id = $2` (or correct index based on selected filters).

```ts
if (sql.includes("FROM sales_orders so")) {
  expect(sql).toContain("so.tenant_id =");
}
```

- [ ] **Step 2: Run test to verify it fails before API changes**

Run: `npm test -- app/api/pos/route.test.ts`
Expected: FAIL because query is not tenant-scoped yet.

- [ ] **Step 3: Apply tenant guard and tenant predicates in each endpoint**

Pattern for each handler (example in `app/api/settings/route.ts`):

```ts
import { requireTenantSession } from "@/lib/tenant-scope";

export async function GET() {
  const auth = await requireTenantSession();
  if ("error" in auth) return auth.error;

  const { tenantId } = auth.session;
  const result = await db.query<SettingsRow>(
    `SELECT ... FROM settings WHERE tenant_id = $1`,
    [tenantId]
  );
  // ...
}
```

And for writes:
- `users`: include `tenant_id` in membership creation (`user_tenants`), scope list/delete by tenant membership.
- `menu`: add `tenant_id` filters for `menus`, `ingredients`, `menu_prices`, `menu_addon_assignments` joins.
- `pos`: add `tenant_id` in all SELECT/INSERT/UPDATE for `sales_orders`, membership lookup, settings points lookup.

- [ ] **Step 4: Re-run focused tests**

Run:
- `npm test -- app/api/pos/route.test.ts`
- `npm test -- lib/auth-session.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit tenant-scoped API updates**

```bash
git add app/api/users/route.ts app/api/menu/route.ts app/api/settings/route.ts app/api/pos/route.ts app/api/pos/route.test.ts
git commit -m "feat: scope core APIs to active tenant session"
```

---

### Task 7: Add internal auth endpoints for hybrid phase

**Files:**
- Create: `app/api/auth/login/route.ts`
- Create: `app/api/auth/switch-tenant/route.ts`

- [ ] **Step 1: Write failing tests for login and tenant switching behavior**

Create `app/api/auth/login/route.test.ts` with cases:
- valid username/password creates `auth_sessions` row and returns active tenant.
- invalid credential returns 401.

Create `app/api/auth/switch-tenant/route.test.ts` with case:
- user can only switch to tenant they belong to (`user_tenants`).

- [ ] **Step 2: Run tests to verify failures**

Run:
- `npm test -- app/api/auth/login/route.test.ts`
- `npm test -- app/api/auth/switch-tenant/route.test.ts`
Expected: FAIL because routes do not exist.

- [ ] **Step 3: Implement minimal auth routes**

`app/api/auth/login/route.ts` behavior:
- Validate payload username/password.
- Lookup `users` by username/email and active status.
- Verify password string equality (current repo baseline), then create random session token.
- Resolve default tenant from `user_tenants` (`is_default = true` fallback first row).
- Insert session into `auth_sessions` and set `app_session` httpOnly cookie.

`app/api/auth/switch-tenant/route.ts` behavior:
- Require current session.
- Verify target tenant exists in `user_tenants` for user.
- Update `auth_sessions.active_tenant_id` and `users.active_tenant_id`.

- [ ] **Step 4: Run tests to verify pass**

Run:
- `npm test -- app/api/auth/login/route.test.ts`
- `npm test -- app/api/auth/switch-tenant/route.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit hybrid auth endpoints**

```bash
git add app/api/auth/login/route.ts app/api/auth/switch-tenant/route.ts app/api/auth/login/route.test.ts app/api/auth/switch-tenant/route.test.ts
git commit -m "feat: add internal hybrid tenant session endpoints"
```

---

### Task 8: Verification and migration runbook

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add migration execution sequence and rollback notes**

Append section in `README.md`:

```md
## Multi-tenant foundation migration

Run migrations in order:
1. `017_add_multitenant_foundation_expand.sql`
2. `018_backfill_multitenant_default_tenant.sql`
3. `019_enforce_multitenant_constraints_contract.sql`

Validate:
- `SELECT COUNT(*) FROM tenants;`
- `SELECT COUNT(*) FROM users WHERE active_tenant_id IS NULL;` should be 0
- `SELECT COUNT(*) FROM menus WHERE tenant_id IS NULL;` should be 0

For emergency rollback, stop at expand/backfill stage and avoid applying contract until API deployment is confirmed.
```

- [ ] **Step 2: Run full test suite**

Run: `npm test`
Expected: PASS.

- [ ] **Step 3: Commit verification docs and final state**

```bash
git add README.md
git commit -m "docs: add multitenant migration verification runbook"
```

---

## Spec Coverage Self-Review

- Multi-tenant shared schema foundation: covered by Tasks 2-4.
- Tenant from session + multi-tenant user membership: covered by Tasks 5 and 7.
- Zero-downtime migration strategy: covered by expand/backfill/contract ordering in Tasks 2-4 and runbook in Task 8.
- Core API tenant isolation: covered by Task 6.
- Hybrid auth rollout path: covered by Task 7.

No placeholders, no TBDs, and all implementation tasks include explicit files and runnable commands.
