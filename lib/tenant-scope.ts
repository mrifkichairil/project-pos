import { NextResponse } from "next/server";
import { resolveTenantContext, type TenantContext } from "@/lib/tenant-context";

export async function requireTenantScope(): Promise<{ context: TenantContext } | { error: NextResponse }> {
  const context = await resolveTenantContext();
  if (!context) {
    return {
      error: NextResponse.json({ error: "Tenant context is unavailable" }, { status: 401 }),
    };
  }

  return { context };
}
