import { beforeEach, describe, expect, it, vi } from "vitest";

const queryMock = vi.fn();
const requireTenantScopeMock = vi.fn();

vi.mock("@/lib/db", () => ({
  db: {
    query: queryMock,
  },
}));

vi.mock("@/lib/tenant-scope", () => ({
  requireTenantScope: requireTenantScopeMock,
}));

describe("settings route tenant scope", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 401 when tenant scope is unavailable", async () => {
    requireTenantScopeMock.mockResolvedValue({
      error: Response.json({ error: "Unauthorized" }, { status: 401 }),
    });

    const { GET } = await import("./route");
    const response = await GET();

    expect(response.status).toBe(401);
    expect(queryMock).not.toHaveBeenCalled();
  });
});
