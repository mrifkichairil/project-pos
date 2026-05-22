import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { requireTenantScope } from "@/lib/tenant-scope";

type SettingsRow = {
  store_name: string;
  address: string;
  wifi_password: string;
  pb1_enabled: boolean;
  pb1_rate: string;
  service_enabled: boolean;
  service_rate: string;
  ppn_enabled: boolean;
  ppn_rate: string;
  qris_image_url: string;
  inventory_policy: string;
  point_value: string;
  point_per_rupiah: string;
};

type UpdatePayload = {
  storeName?: string;
  address?: string;
  wifiPassword?: string;
  pb1Enabled?: boolean;
  pb1Rate?: number | string;
  serviceEnabled?: boolean;
  serviceRate?: number | string;
  ppnEnabled?: boolean;
  ppnRate?: number | string;
  qrisImageUrl?: string;
  inventoryPolicy?: string;
  pointValue?: number | string;
  pointPerRupiah?: number | string;
};

export async function GET() {
  const tenant = await requireTenantScope();
  if ("error" in tenant) return tenant.error;

  try {
    const result = await db.query<SettingsRow>(
      `SELECT store_name, address, wifi_password, pb1_enabled, pb1_rate, service_enabled, service_rate, ppn_enabled, ppn_rate, qris_image_url, inventory_policy, point_value, point_per_rupiah FROM settings WHERE tenant_id = $1`,
      [tenant.context.tenantId]
    );

    if (result.rows.length === 0) {
      return NextResponse.json({
        storeName: "Warung Kita",
        address: "",
        wifiPassword: "",
        pb1Enabled: true,
        pb1Rate: 10,
        serviceEnabled: true,
        serviceRate: 5,
        ppnEnabled: false,
        ppnRate: 11,
        qrisImageUrl: "",
        inventoryPolicy: "medium",
        pointValue: 1,
        pointPerRupiah: 1000,
      });
    }

    const row = result.rows[0];
    return NextResponse.json({
      storeName: row.store_name,
      address: row.address,
      wifiPassword: row.wifi_password,
      pb1Enabled: row.pb1_enabled,
      pb1Rate: Number(row.pb1_rate),
      serviceEnabled: row.service_enabled,
      serviceRate: Number(row.service_rate),
      ppnEnabled: row.ppn_enabled,
      ppnRate: Number(row.ppn_rate),
      qrisImageUrl: row.qris_image_url,
      inventoryPolicy: row.inventory_policy,
      pointValue: Number(row.point_value),
      pointPerRupiah: Number(row.point_per_rupiah),
    });
  } catch {
    return NextResponse.json({ error: "Failed to load settings" }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  const tenant = await requireTenantScope();
  if ("error" in tenant) return tenant.error;

  try {
    const body = (await request.json()) as UpdatePayload;

    const storeName = body.storeName?.trim() ?? "Warung Kita";
    const address = body.address?.trim() ?? "";
    const wifiPassword = body.wifiPassword ?? "";
    const pb1Enabled = body.pb1Enabled ?? true;
    const pb1Rate = Number(body.pb1Rate) || 0;
    const serviceEnabled = body.serviceEnabled ?? true;
    const serviceRate = Number(body.serviceRate) || 0;
    const ppnEnabled = body.ppnEnabled ?? false;
    const ppnRate = Number(body.ppnRate) || 0;
    const qrisImageUrl = body.qrisImageUrl ?? "";
    const inventoryPolicy = ["strict", "medium", "off"].includes(body.inventoryPolicy || "") ? body.inventoryPolicy : "medium";
    const pointValue = Number(body.pointValue) || 1;
    const pointPerRupiah = Number(body.pointPerRupiah) || 1000;

    await db.query(
      `
        INSERT INTO settings (
          tenant_id,
          store_name,
          address,
          wifi_password,
          pb1_enabled,
          pb1_rate,
          service_enabled,
          service_rate,
          ppn_enabled,
          ppn_rate,
          qris_image_url,
          inventory_policy,
          point_value,
          point_per_rupiah
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
        ON CONFLICT (tenant_id) DO UPDATE SET
          store_name = EXCLUDED.store_name,
          address = EXCLUDED.address,
          wifi_password = EXCLUDED.wifi_password,
          pb1_enabled = EXCLUDED.pb1_enabled,
          pb1_rate = EXCLUDED.pb1_rate,
          service_enabled = EXCLUDED.service_enabled,
          service_rate = EXCLUDED.service_rate,
          ppn_enabled = EXCLUDED.ppn_enabled,
          ppn_rate = EXCLUDED.ppn_rate,
          qris_image_url = EXCLUDED.qris_image_url,
          inventory_policy = EXCLUDED.inventory_policy,
          point_value = EXCLUDED.point_value,
          point_per_rupiah = EXCLUDED.point_per_rupiah,
          updated_at = NOW()
      `,
      [tenant.context.tenantId, storeName, address, wifiPassword, pb1Enabled, pb1Rate, serviceEnabled, serviceRate, ppnEnabled, ppnRate, qrisImageUrl, inventoryPolicy, pointValue, pointPerRupiah]
    );

    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json({ error: "Failed to save settings" }, { status: 500 });
  }
}
