import { cookies } from "next/headers";
import { db } from "@/lib/db";

export type TenantRole = "admin" | "manager" | "cashier";

export type TenantContext = {
  tenantId: number;
  userId: number | null;
  role: TenantRole;
  isFallback: boolean;
};

export async function resolveTenantContext(): Promise<TenantContext | null> {
  const cookieStore = await cookies();
  const sessionToken = cookieStore.get("app_session")?.value;

  if (sessionToken) {
    const sessionResult = await db.query<{
      tenant_id: number;
      user_id: number;
      role: TenantRole;
    }>(
      `
        SELECT s.active_tenant_id AS tenant_id, s.user_id, ut.role
        FROM auth_sessions s
        JOIN user_tenants ut
          ON ut.user_id = s.user_id
         AND ut.tenant_id = s.active_tenant_id
        JOIN users u ON u.id = s.user_id
        WHERE s.session_token = $1
          AND s.expires_at > NOW()
          AND u.is_active = TRUE
        LIMIT 1
      `,
      [sessionToken]
    );

    const session = sessionResult.rows[0];
    if (session) {
      return {
        tenantId: session.tenant_id,
        userId: session.user_id,
        role: session.role,
        isFallback: false,
      };
    }
  }

  const defaultTenantResult = await db.query<{ id: number }>(
    `SELECT id FROM tenants WHERE slug = 'default' LIMIT 1`
  );

  const defaultTenant = defaultTenantResult.rows[0];
  if (!defaultTenant) {
    return null;
  }

  return {
    tenantId: defaultTenant.id,
    userId: null,
    role: "admin",
    isFallback: true,
  };
}
