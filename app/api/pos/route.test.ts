import { beforeEach, describe, expect, it, vi } from "vitest";

const connectMock = vi.fn();
const requireTenantScopeMock = vi.fn();

vi.mock("@/lib/db", () => ({
  db: {
    connect: connectMock,
  },
}));

vi.mock("@/lib/tenant-scope", () => ({
  requireTenantScope: requireTenantScopeMock,
}));

describe("POS route tenant scope", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 401 when tenant scope is unavailable", async () => {
    requireTenantScopeMock.mockResolvedValue({
      error: Response.json({ error: "Unauthorized" }, { status: 401 }),
    });

    const { GET } = await import("./route");
    const response = await GET(new Request("http://localhost/api/pos"));

    expect(response.status).toBe(401);
  });
});

describe("PATCH /api/pos payment update", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    requireTenantScopeMock.mockResolvedValue({
      context: { tenantId: 1, userId: 1, role: "admin", isFallback: false },
    });
  });

  it("updates payment to paid without reusing $1 across mixed SQL contexts", async () => {
    const queryMock = vi.fn(async (sql: string, params?: unknown[]) => {
      if (sql === "BEGIN" || sql === "COMMIT" || sql === "ROLLBACK") {
        return { rows: [] };
      }

      if (sql.includes("SELECT id, status, member_id, total_amount::text, order_code FROM sales_orders")) {
        expect(params).toEqual(["ORD-0001", 1]);
        return { rows: [{ id: 101, status: "open", member_id: null, total_amount: "10000", order_code: "ORD-0001" }] };
      }

      if (sql.includes("UPDATE order_payments")) {
        if (sql.includes("CASE WHEN $1")) {
          throw new Error("inconsistent types deduced for parameter $1");
        }

        expect(params).toEqual([101, "paid"]);
        return { rows: [] };
      }

      if (sql.includes("UPDATE sales_orders SET status = $1")) {
        expect(params).toEqual(["paid", 101]);
        return { rows: [] };
      }

      if (sql.includes("INSERT INTO order_status_history")) {
        return { rows: [] };
      }

      return { rows: [] };
    });

    connectMock.mockResolvedValue({
      query: queryMock,
      release: vi.fn(),
    });

    const { PATCH } = await import("./route");

    const response = await PATCH(
      new Request("http://localhost/api/pos", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          orderCode: "ORD-0001",
          paymentStatus: "paid",
          handledBy: "Kasir",
        }),
      })
    );

    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body).toEqual({ success: true, pointsEarned: 0 });
  });
});
