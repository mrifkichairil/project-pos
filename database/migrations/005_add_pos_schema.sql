BEGIN;

CREATE TABLE IF NOT EXISTS cashier_shifts (
  id BIGSERIAL PRIMARY KEY,
  shift_code VARCHAR(40) NOT NULL UNIQUE,
  cashier_name VARCHAR(100) NOT NULL,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  opening_cash NUMERIC(14,2) NOT NULL DEFAULT 0,
  closed_at TIMESTAMPTZ,
  closing_cash NUMERIC(14,2),
  expected_cash NUMERIC(14,2),
  cash_variance NUMERIC(14,2),
  status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_opened_at ON cashier_shifts(opened_at DESC);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_status ON cashier_shifts(status);

CREATE TABLE IF NOT EXISTS sales_orders (
  id BIGSERIAL PRIMARY KEY,
  order_code VARCHAR(40) NOT NULL UNIQUE,
  shift_id BIGINT REFERENCES cashier_shifts(id) ON DELETE SET NULL,
  member_id BIGINT REFERENCES members(id) ON DELETE SET NULL,
  order_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cashier_name VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'paid' CHECK (status IN ('draft', 'open', 'paid', 'cancelled', 'refunded')),
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  service_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_orders_order_at ON sales_orders(order_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_orders_member_id ON sales_orders(member_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_shift_id ON sales_orders(shift_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_status ON sales_orders(status);

CREATE TABLE IF NOT EXISTS sales_order_items (
  id BIGSERIAL PRIMARY KEY,
  sales_order_id BIGINT NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  menu_id BIGINT REFERENCES menus(id) ON DELETE SET NULL,
  menu_name_snapshot VARCHAR(160) NOT NULL,
  variant_name VARCHAR(60),
  sugar_level VARCHAR(30),
  note TEXT,
  qty NUMERIC(14,2) NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  line_total NUMERIC(14,2) NOT NULL CHECK (line_total >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_order_items_order_id ON sales_order_items(sales_order_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_menu_id ON sales_order_items(menu_id);

CREATE TABLE IF NOT EXISTS order_payments (
  id BIGSERIAL PRIMARY KEY,
  sales_order_id BIGINT NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  method VARCHAR(30) NOT NULL CHECK (method IN ('cash', 'qris', 'card', 'e_wallet', 'transfer')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  provider VARCHAR(40),
  provider_tx_id VARCHAR(120),
  status VARCHAR(20) NOT NULL DEFAULT 'paid' CHECK (status IN ('pending', 'paid', 'failed', 'voided', 'refunded')),
  paid_at TIMESTAMPTZ,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_order_payments_provider_tx_id
  ON order_payments(provider_tx_id)
  WHERE provider_tx_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_payments_sales_order_id ON order_payments(sales_order_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_status ON order_payments(status);

CREATE TABLE IF NOT EXISTS cash_drawer_movements (
  id BIGSERIAL PRIMARY KEY,
  shift_id BIGINT NOT NULL REFERENCES cashier_shifts(id) ON DELETE CASCADE,
  movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('in', 'out')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  reason VARCHAR(200) NOT NULL,
  reference_code VARCHAR(50),
  created_by VARCHAR(100) NOT NULL DEFAULT 'system',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cash_drawer_movements_shift_id ON cash_drawer_movements(shift_id);
CREATE INDEX IF NOT EXISTS idx_cash_drawer_movements_created_at ON cash_drawer_movements(created_at DESC);

CREATE TABLE IF NOT EXISTS order_status_history (
  id BIGSERIAL PRIMARY KEY,
  sales_order_id BIGINT NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  from_status VARCHAR(20),
  to_status VARCHAR(20) NOT NULL CHECK (to_status IN ('draft', 'open', 'paid', 'cancelled', 'refunded')),
  changed_by VARCHAR(100) NOT NULL DEFAULT 'system',
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  note TEXT
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(sales_order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_changed_at ON order_status_history(changed_at DESC);

COMMIT;
