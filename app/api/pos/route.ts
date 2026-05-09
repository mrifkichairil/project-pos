import { NextResponse } from "next/server";
import { db } from "@/lib/db";

type PosOrderItemPayload = {
  menuId?: number;
  name: string;
  variant?: string;
  sugar?: string;
  price: number;
  qty: number;
  note?: string;
};

type PosOrderPayload = {
  orderCode: string;
  customerName: string;
  memberName?: string;
  orderType: string;
  tableNumber: string;
  cashierName: string;
  paymentMethod: "cash" | "qris" | "card" | "midtrans" | "e_wallet" | "transfer";
  paymentStatus: "pending" | "paid";
  provider?: string;
  providerTxId?: string;
  subtotal: number;
  discount: number;
  taxes: number;
  serviceAmount: number;
  total: number;
  items: PosOrderItemPayload[];
};

export async function POST(request: Request) {
  const client = await db.connect();

  try {
    const body = (await request.json()) as PosOrderPayload;

    if (!body.orderCode || !body.customerName || !body.orderType || !body.tableNumber || !body.cashierName) {
      return NextResponse.json({ error: "Invalid order payload" }, { status: 400 });
    }

    if (!Array.isArray(body.items) || body.items.length === 0 || body.total <= 0) {
      return NextResponse.json({ error: "Order items are required" }, { status: 400 });
    }

    await client.query("BEGIN");

    let memberId: number | null = null;
    if (body.memberName) {
      const memberResult = await client.query<{ id: number }>(
        `SELECT id FROM members WHERE name = $1 AND is_active = TRUE ORDER BY id LIMIT 1`,
        [body.memberName]
      );
      memberId = memberResult.rows[0]?.id ?? null;
    }

    const orderStatus = body.paymentStatus === "paid" ? "paid" : "open";

    const orderResult = await client.query<{ id: number }>(
      `
        INSERT INTO sales_orders (
          order_code,
          member_id,
          order_at,
          cashier_name,
          status,
          subtotal,
          discount_amount,
          tax_amount,
          service_amount,
          total_amount,
          notes
        ) VALUES ($1, $2, NOW(), $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id
      `,
      [
        body.orderCode,
        memberId,
        body.cashierName,
        orderStatus,
        body.subtotal,
        body.discount,
        body.taxes,
        body.serviceAmount,
        body.total,
        `order_type=${body.orderType}; table=${body.tableNumber}; customer=${body.customerName}`,
      ]
    );

    const salesOrderId = orderResult.rows[0].id;

    const menuMapResult = await client.query<{ id: number; name: string }>(
      `SELECT id, name FROM menus WHERE is_active = TRUE`
    );
    const menuMap = new Map(menuMapResult.rows.map((row) => [row.name.toLowerCase(), row.id]));

    for (const item of body.items) {
      const resolvedMenuId = item.menuId && item.menuId > 0 ? item.menuId : menuMap.get(item.name.toLowerCase()) || null;
      const lineTotal = item.price * item.qty;

      await client.query(
        `
          INSERT INTO sales_order_items (
            sales_order_id,
            menu_id,
            menu_name_snapshot,
            variant_name,
            sugar_level,
            note,
            qty,
            unit_price,
            line_total
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `,
        [
          salesOrderId,
          resolvedMenuId,
          item.name,
          item.variant || null,
          item.sugar || null,
          item.note || null,
          item.qty,
          item.price,
          lineTotal,
        ]
      );
    }

    const paymentMethod = body.paymentMethod === "midtrans" ? "qris" : body.paymentMethod;
    const paymentProvider = body.paymentMethod === "midtrans" ? "midtrans" : body.provider || null;

    await client.query(
      `
        INSERT INTO order_payments (
          sales_order_id,
          method,
          amount,
          provider,
          provider_tx_id,
          status,
          paid_at,
          raw_payload
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `,
      [
        salesOrderId,
        paymentMethod,
        body.total,
        paymentProvider,
        body.providerTxId || body.orderCode,
        body.paymentStatus,
        body.paymentStatus === "paid" ? new Date().toISOString() : null,
        JSON.stringify({ orderType: body.orderType, tableNumber: body.tableNumber, customerName: body.customerName }),
      ]
    );

    await client.query(
      `
        INSERT INTO order_status_history (
          sales_order_id,
          from_status,
          to_status,
          changed_by,
          note
        ) VALUES ($1, $2, $3, $4, $5)
      `,
      [salesOrderId, null, orderStatus, body.cashierName, "POS checkout"]
    );

    await client.query("COMMIT");

    return NextResponse.json({ success: true, salesOrderId, orderCode: body.orderCode });
  } catch (error) {
    await client.query("ROLLBACK");

    if (error && typeof error === "object" && "code" in error && (error as { code?: string }).code === "23505") {
      return NextResponse.json({ error: "Order code already exists" }, { status: 409 });
    }

    return NextResponse.json({ error: "Failed to save POS order" }, { status: 500 });
  } finally {
    client.release();
  }
}
