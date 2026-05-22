import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { requireTenantScope } from "@/lib/tenant-scope";

type UserRow = {
  id: number;
  fullname: string;
  username: string;
  email: string;
  phone: string | null;
  role: string;
  is_active: boolean;
  created_at: string;
};

export async function GET() {
  const tenant = await requireTenantScope();
  if ("error" in tenant) return tenant.error;

  try {
    const result = await db.query<UserRow>(
      `
        SELECT u.id, u.fullname, u.username, u.email, u.phone, u.role, u.is_active, u.created_at::text
        FROM users u
        JOIN user_tenants ut ON ut.user_id = u.id
        WHERE ut.tenant_id = $1
          AND u.is_active = TRUE
        ORDER BY u.id
      `,
      [tenant.context.tenantId]
    );

    return NextResponse.json({
      users: result.rows.map((row) => ({
        id: row.id,
        name: row.fullname,
        username: row.username,
        email: row.email,
        phone: row.phone || "-",
        role: row.role,
        createdAt: new Date(row.created_at).toLocaleDateString("id-ID"),
      })),
    });
  } catch {
    return NextResponse.json({ error: "Failed to load users" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  const tenant = await requireTenantScope();
  if ("error" in tenant) return tenant.error;

  const client = await db.connect();

  try {
    const body = (await request.json()) as {
      name?: string;
      username?: string;
      email?: string;
      phone?: string;
      password?: string;
      role?: string;
    };

    const name = body.name?.trim();
    const username = body.username?.trim();
    const email = body.email?.trim();
    const phone = body.phone?.trim() || null;
    const password = body.password || "";
    const role = ["admin", "manager", "cashier"].includes(body.role || "") ? body.role : "cashier";

    if (!name || !username || !email || !password) {
      return NextResponse.json({ error: "Semua field wajib diisi" }, { status: 400 });
    }

    await client.query("BEGIN");

    const result = await client.query<{ id: number }>(
      `INSERT INTO users (fullname, username, email, phone, password, role, active_tenant_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [name, username, email, phone, password, role, tenant.context.tenantId]
    );

    await client.query(
      `INSERT INTO user_tenants (user_id, tenant_id, role, is_default) VALUES ($1, $2, $3, TRUE) ON CONFLICT (user_id, tenant_id) DO NOTHING`,
      [result.rows[0].id, tenant.context.tenantId, role]
    );

    await client.query("COMMIT");

    return NextResponse.json({ success: true, id: result.rows[0].id }, { status: 201 });
  } catch (err) {
    try { await client.query("ROLLBACK"); } catch {}
    const pgErr = err as { code?: string };
    if (pgErr.code === "23505") {
      return NextResponse.json({ error: "Email atau username sudah terdaftar" }, { status: 409 });
    }
    return NextResponse.json({ error: "Failed to create user" }, { status: 500 });
  } finally {
    client.release();
  }
}

export async function DELETE(request: Request) {
  const tenant = await requireTenantScope();
  if ("error" in tenant) return tenant.error;

  try {
    const { searchParams } = new URL(request.url);
    const id = Number(searchParams.get("id"));
    if (!id) return NextResponse.json({ error: "ID required" }, { status: 400 });

    await db.query(
      `
        UPDATE users u
        SET is_active = FALSE, updated_at = NOW()
        WHERE u.id = $1
          AND EXISTS (
            SELECT 1
            FROM user_tenants ut
            WHERE ut.user_id = u.id
              AND ut.tenant_id = $2
          )
      `,
      [id, tenant.context.tenantId]
    );
    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json({ error: "Failed to delete user" }, { status: 500 });
  }
}
