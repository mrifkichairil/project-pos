import { beforeEach, describe, expect, it, vi } from "vitest";

const queryMock = vi.fn();
const cookiesGetMock = vi.fn();

vi.mock("@/lib/db", () => ({
  db: {
    query: queryMock,
  },
}));

vi.mock("next/headers", () => ({
  cookies: async () => ({
    get: cookiesGetMock,
  }),
}));

describe("tenant context", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("uses auth session tenant when app_session cookie is valid", async () => {
    cookiesGetMock.mockReturnValue({ value: "token-123" });
    queryMock.mockResolvedValueOnce({
      rows: [
        {
          tenant_id: 10,
          user_id: 2,
          role: "manager",
        },
      ],
    });

    const { resolveTenantContext } = await import("./tenant-context");
    const ctx = await resolveTenantContext();

    expect(ctx).toEqual({ tenantId: 10, userId: 2, role: "manager", isFallback: false });
  });

  it("falls back to default tenant when session cookie is missing", async () => {
    cookiesGetMock.mockReturnValue(undefined);
    queryMock.mockResolvedValueOnce({ rows: [{ id: 1 }] });

    const { resolveTenantContext } = await import("./tenant-context");
    const ctx = await resolveTenantContext();

    expect(ctx).toEqual({ tenantId: 1, userId: null, role: "admin", isFallback: true });
  });
});
