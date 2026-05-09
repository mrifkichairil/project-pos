BEGIN;

CREATE TABLE IF NOT EXISTS suppliers (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL UNIQUE,
  contact_phone VARCHAR(30),
  address TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  id BIGSERIAL PRIMARY KEY,
  po_code VARCHAR(40) NOT NULL UNIQUE,
  supplier_id BIGINT NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
  order_date DATE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'received' CHECK (status IN ('draft', 'ordered', 'received', 'cancelled')),
  notes TEXT,
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_order_date ON purchase_orders(order_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id BIGSERIAL PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
  qty NUMERIC(14,2) NOT NULL CHECK (qty > 0),
  unit VARCHAR(20) NOT NULL,
  price_per_unit NUMERIC(14,2) NOT NULL CHECK (price_per_unit >= 0),
  line_total NUMERIC(14,2) NOT NULL CHECK (line_total >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (purchase_order_id, ingredient_id, unit)
);

CREATE INDEX IF NOT EXISTS idx_purchase_order_items_ingredient_id ON purchase_order_items(ingredient_id);

CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGSERIAL PRIMARY KEY,
  movement_code VARCHAR(40) NOT NULL UNIQUE,
  movement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
  movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment')),
  qty NUMERIC(14,2) NOT NULL CHECK (qty > 0),
  unit VARCHAR(20) NOT NULL,
  reference_type VARCHAR(30),
  reference_code VARCHAR(50),
  notes TEXT,
  created_by VARCHAR(100) NOT NULL DEFAULT 'system',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_ingredient_date
  ON stock_movements(ingredient_id, movement_date DESC);

INSERT INTO suppliers (name)
SELECT DISTINCT supplier
FROM ingredients
WHERE supplier IS NOT NULL AND supplier <> ''
ON CONFLICT (name) DO UPDATE
SET
  is_active = TRUE,
  updated_at = NOW();

INSERT INTO purchase_orders (
  po_code,
  supplier_id,
  order_date,
  status,
  notes,
  subtotal,
  tax_amount,
  total_amount
)
SELECT
  v.po_code,
  s.id,
  v.order_date,
  v.status,
  v.notes,
  v.subtotal,
  v.tax_amount,
  v.total_amount
FROM (
  VALUES
    ('PO-2026-001', 'PT Kopi Nusantara', DATE '2026-05-03', 'received', 'Pengadaan biji kopi mingguan', 600000, 0, 600000),
    ('PO-2026-002', 'Indofood', DATE '2026-05-02', 'received', 'Restock susu untuk minuman', 150000, 0, 150000),
    ('PO-2026-003', 'Gulaku', DATE '2026-04-28', 'received', 'Restock gula pasir', 180000, 0, 180000),
    ('PO-2026-004', 'PT Sumber Protein', DATE '2026-04-25', 'received', 'Restock ayam fillet', 175000, 0, 175000),
    ('PO-2026-005', 'Bimoli', DATE '2026-04-24', 'received', 'Restock minyak goreng', 108000, 0, 108000),
    ('PO-2026-006', 'Peternakan Sejahtera', DATE '2026-04-23', 'received', 'Restock telur', 250000, 0, 250000)
) AS v(po_code, supplier_name, order_date, status, notes, subtotal, tax_amount, total_amount)
JOIN suppliers s ON s.name = v.supplier_name
ON CONFLICT (po_code) DO UPDATE
SET
  supplier_id = EXCLUDED.supplier_id,
  order_date = EXCLUDED.order_date,
  status = EXCLUDED.status,
  notes = EXCLUDED.notes,
  subtotal = EXCLUDED.subtotal,
  tax_amount = EXCLUDED.tax_amount,
  total_amount = EXCLUDED.total_amount,
  updated_at = NOW();

INSERT INTO purchase_order_items (
  purchase_order_id,
  ingredient_id,
  qty,
  unit,
  price_per_unit,
  line_total
)
SELECT
  po.id,
  i.id,
  v.qty,
  v.unit,
  v.price_per_unit,
  v.line_total
FROM (
  VALUES
    ('PO-2026-001', 'Kopi Arabica', 5000, 'gram', 120, 600000),
    ('PO-2026-002', 'Susu Full Cream', 10000, 'ml', 15, 150000),
    ('PO-2026-003', 'Gula Pasir', 15000, 'gram', 12, 180000),
    ('PO-2026-004', 'Ayam Fillet', 5000, 'gram', 35, 175000),
    ('PO-2026-005', 'Minyak Goreng', 6000, 'ml', 18, 108000),
    ('PO-2026-006', 'Telur', 100, 'pcs', 2500, 250000)
) AS v(po_code, ingredient_name, qty, unit, price_per_unit, line_total)
JOIN purchase_orders po ON po.po_code = v.po_code
JOIN ingredients i ON i.name = v.ingredient_name
ON CONFLICT (purchase_order_id, ingredient_id, unit) DO UPDATE
SET
  qty = EXCLUDED.qty,
  price_per_unit = EXCLUDED.price_per_unit,
  line_total = EXCLUDED.line_total,
  updated_at = NOW();

INSERT INTO stock_movements (
  movement_code,
  movement_date,
  ingredient_id,
  movement_type,
  qty,
  unit,
  reference_type,
  reference_code,
  notes,
  created_by
)
SELECT
  v.movement_code,
  v.movement_date,
  i.id,
  v.movement_type,
  v.qty,
  v.unit,
  v.reference_type,
  v.reference_code,
  v.notes,
  v.created_by
FROM (
  VALUES
    ('MV-2026-001', DATE '2026-05-03', 'Kopi Arabica', 'in', 5000, 'gram', 'purchase_order', 'PO-2026-001', 'Barang masuk dari PO', 'Admin'),
    ('MV-2026-002', DATE '2026-05-03', 'Susu Full Cream', 'in', 10000, 'ml', 'purchase_order', 'PO-2026-002', 'Barang masuk dari PO', 'Admin'),
    ('MV-2026-003', DATE '2026-05-02', 'Kopi Arabica', 'out', 250, 'gram', 'sales_order', 'TX4491', 'Pemakaian transaksi', 'Budi'),
    ('MV-2026-004', DATE '2026-05-02', 'Susu Full Cream', 'out', 500, 'ml', 'sales_order', 'TX4491', 'Pemakaian transaksi', 'Budi'),
    ('MV-2026-005', DATE '2026-05-01', 'Gula Pasir', 'out', 300, 'gram', 'waste', 'WASTE-001', 'Bahan rusak', 'Rudi'),
    ('MV-2026-006', DATE '2026-05-01', 'Nasi', 'out', 2000, 'gram', 'sales_order', 'TX4490', 'Pemakaian transaksi', 'Budi'),
    ('MV-2026-007', DATE '2026-04-30', 'Telur', 'adjustment', 20, 'pcs', 'stock_opname', 'SO-2026-001', 'Koreksi stok opname', 'Admin')
) AS v(movement_code, movement_date, ingredient_name, movement_type, qty, unit, reference_type, reference_code, notes, created_by)
JOIN ingredients i ON i.name = v.ingredient_name
ON CONFLICT (movement_code) DO UPDATE
SET
  movement_date = EXCLUDED.movement_date,
  ingredient_id = EXCLUDED.ingredient_id,
  movement_type = EXCLUDED.movement_type,
  qty = EXCLUDED.qty,
  unit = EXCLUDED.unit,
  reference_type = EXCLUDED.reference_type,
  reference_code = EXCLUDED.reference_code,
  notes = EXCLUDED.notes,
  created_by = EXCLUDED.created_by;

COMMIT;
