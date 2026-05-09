BEGIN;

CREATE TABLE IF NOT EXISTS members (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(160) NOT NULL UNIQUE,
  phone VARCHAR(30) NOT NULL,
  location VARCHAR(120) NOT NULL,
  tier VARCHAR(20) NOT NULL CHECK (tier IN ('Bronze', 'Silver', 'Gold', 'Platinum')),
  points_balance INTEGER NOT NULL DEFAULT 0 CHECK (points_balance >= 0),
  visit_count INTEGER NOT NULL DEFAULT 0 CHECK (visit_count >= 0),
  total_spending NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total_spending >= 0),
  last_visit_at DATE,
  favorite_menu_id BIGINT REFERENCES menus(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_members_tier ON members(tier);
CREATE INDEX IF NOT EXISTS idx_members_last_visit ON members(last_visit_at DESC);

CREATE TABLE IF NOT EXISTS member_transactions (
  id BIGSERIAL PRIMARY KEY,
  member_id BIGINT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  transaction_code VARCHAR(30) NOT NULL UNIQUE,
  transaction_date DATE NOT NULL,
  item_summary TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_member_transactions_member_date
  ON member_transactions(member_id, transaction_date DESC);

CREATE TABLE IF NOT EXISTS member_point_ledger (
  id BIGSERIAL PRIMARY KEY,
  member_id BIGINT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  transaction_id BIGINT REFERENCES member_transactions(id) ON DELETE SET NULL,
  entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('earn', 'redeem', 'adjust')),
  description VARCHAR(255) NOT NULL,
  points_delta INTEGER NOT NULL CHECK (points_delta <> 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_member_point_ledger_member_created
  ON member_point_ledger(member_id, created_at DESC);

CREATE TABLE IF NOT EXISTS rewards (
  id BIGSERIAL PRIMARY KEY,
  reward_name VARCHAR(150) NOT NULL UNIQUE,
  points_cost INTEGER NOT NULL CHECK (points_cost > 0),
  discount_percent NUMERIC(5,2) CHECK (discount_percent >= 0 AND discount_percent <= 100),
  free_menu_id BIGINT REFERENCES menus(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS member_reward_redemptions (
  id BIGSERIAL PRIMARY KEY,
  member_id BIGINT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  reward_id BIGINT NOT NULL REFERENCES rewards(id) ON DELETE RESTRICT,
  points_cost_snapshot INTEGER NOT NULL CHECK (points_cost_snapshot > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'redeemed' CHECK (status IN ('redeemed', 'cancelled')),
  notes TEXT,
  redeemed_at DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_member_reward_redemptions_member
  ON member_reward_redemptions(member_id, redeemed_at DESC);

INSERT INTO members (
  name,
  email,
  phone,
  location,
  tier,
  points_balance,
  visit_count,
  total_spending,
  last_visit_at,
  favorite_menu_id
)
SELECT
  v.name,
  v.email,
  v.phone,
  v.location,
  v.tier,
  v.points_balance,
  v.visit_count,
  v.total_spending,
  v.last_visit_at,
  m.id
FROM (
  VALUES
    ('Budi Santoso', 'budi.s@email.com', '0812-3456-7890', 'Jakarta', 'Gold', 2134, 48, 2847000, DATE '2026-05-02', 'Nasi Goreng'),
    ('Siti Aminah', 'siti.a@email.com', '0821-9876-5432', 'Bandung', 'Silver', 1742, 32, 1850000, DATE '2026-05-01', 'Es Buah'),
    ('Ahmad Hidayat', 'ahmad.h@email.com', '0856-1234-5678', 'Jakarta', 'Gold', 2204, 51, 3200000, DATE '2026-05-02', 'Rendang'),
    ('Dewi Kusuma', 'dewi.k@email.com', '0813-5678-9012', 'Surabaya', 'Bronze', 730, 15, 850000, DATE '2026-04-25', 'Sate Ayam'),
    ('Rudi Hartono', 'rudi.h@email.com', '0877-4455-6677', 'Jakarta', 'Silver', 1730, 29, 2100000, DATE '2026-04-29', 'Nasi Goreng'),
    ('Lina Marlina', 'lina.m@email.com', '0899-1122-3344', 'Bandung', 'Gold', 3420, 62, 4500000, DATE '2026-05-03', 'Es Buah')
) AS v(name, email, phone, location, tier, points_balance, visit_count, total_spending, last_visit_at, favorite_menu)
LEFT JOIN menus m ON m.name = v.favorite_menu
ON CONFLICT (email) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  location = EXCLUDED.location,
  tier = EXCLUDED.tier,
  points_balance = EXCLUDED.points_balance,
  visit_count = EXCLUDED.visit_count,
  total_spending = EXCLUDED.total_spending,
  last_visit_at = EXCLUDED.last_visit_at,
  favorite_menu_id = EXCLUDED.favorite_menu_id,
  is_active = TRUE,
  updated_at = NOW();

INSERT INTO member_transactions (member_id, transaction_code, transaction_date, item_summary, amount)
SELECT m.id, v.tx_code, v.tx_date, v.item_summary, v.amount
FROM (
  VALUES
    ('budi.s@email.com', '#TX4491', DATE '2026-05-02', 'Nasi Goreng x2, Es Buah', 90000),
    ('budi.s@email.com', '#TX4485', DATE '2026-04-28', 'Rendang, Sate Ayam', 150000),
    ('budi.s@email.com', '#TX4478', DATE '2026-04-20', 'Nasi Goreng, Es Teh', 52000),

    ('siti.a@email.com', '#TX4490', DATE '2026-05-01', 'Es Buah x2, Klepon', 68000),
    ('siti.a@email.com', '#TX4482', DATE '2026-04-25', 'Gado-Gado, Es Teler', 78000),

    ('ahmad.h@email.com', '#TX4492', DATE '2026-05-02', 'Rendang x3, Es Teh x2', 210000),
    ('ahmad.h@email.com', '#TX4488', DATE '2026-04-30', 'Nasi Goreng, Sate Ayam', 95000),

    ('dewi.k@email.com', '#TX4475', DATE '2026-04-25', 'Sate Ayam x2', 80000),

    ('rudi.h@email.com', '#TX4480', DATE '2026-04-29', 'Nasi Goreng, Gado-Gado', 72000),

    ('lina.m@email.com', '#TX4493', DATE '2026-05-03', 'Es Buah x3, Nasi Goreng', 130000),
    ('lina.m@email.com', '#TX4489', DATE '2026-05-01', 'Rendang x2', 180000)
) AS v(email, tx_code, tx_date, item_summary, amount)
JOIN members m ON m.email = v.email
ON CONFLICT (transaction_code) DO UPDATE
SET
  member_id = EXCLUDED.member_id,
  transaction_date = EXCLUDED.transaction_date,
  item_summary = EXCLUDED.item_summary,
  amount = EXCLUDED.amount;

INSERT INTO member_point_ledger (member_id, transaction_id, entry_type, description, points_delta, created_at)
SELECT
  m.id,
  tx.id,
  v.entry_type,
  v.description,
  v.points_delta,
  v.created_at
FROM (
  VALUES
    ('budi.s@email.com', '#TX4491', 'earn', 'Pembelian #TX4491', 90, TIMESTAMPTZ '2026-05-02 12:00:00+07'),
    ('budi.s@email.com', '#TX4485', 'earn', 'Pembelian #TX4485', 150, TIMESTAMPTZ '2026-04-28 12:00:00+07'),
    ('budi.s@email.com', NULL, 'redeem', 'Tukar Free Es Buah', -500, TIMESTAMPTZ '2026-04-15 12:00:00+07'),

    ('siti.a@email.com', '#TX4490', 'earn', 'Pembelian #TX4490', 68, TIMESTAMPTZ '2026-05-01 12:00:00+07'),
    ('siti.a@email.com', '#TX4482', 'earn', 'Pembelian #TX4482', 78, TIMESTAMPTZ '2026-04-25 12:00:00+07'),

    ('ahmad.h@email.com', '#TX4492', 'earn', 'Pembelian #TX4492', 210, TIMESTAMPTZ '2026-05-02 12:00:00+07'),

    ('dewi.k@email.com', '#TX4475', 'earn', 'Pembelian #TX4475', 80, TIMESTAMPTZ '2026-04-25 12:00:00+07'),

    ('rudi.h@email.com', '#TX4480', 'earn', 'Pembelian #TX4480', 72, TIMESTAMPTZ '2026-04-29 12:00:00+07'),

    ('lina.m@email.com', '#TX4493', 'earn', 'Pembelian #TX4493', 130, TIMESTAMPTZ '2026-05-03 12:00:00+07')
) AS v(email, tx_code, entry_type, description, points_delta, created_at)
JOIN members m ON m.email = v.email
LEFT JOIN member_transactions tx ON tx.transaction_code = v.tx_code
WHERE NOT EXISTS (
  SELECT 1
  FROM member_point_ledger l
  WHERE l.member_id = m.id
    AND l.description = v.description
    AND l.points_delta = v.points_delta
    AND l.created_at = v.created_at
);

INSERT INTO rewards (reward_name, points_cost, discount_percent, free_menu_id)
SELECT v.reward_name, v.points_cost, v.discount_percent, m.id
FROM (
  VALUES
    ('Free Es Buah', 500, NULL, 'Es Buah'),
    ('Diskon 5%', 300, 5, NULL),
    ('Diskon 10%', 1000, 10, NULL),
    ('Diskon 15%', 1200, 15, NULL),
    ('Free Rendang', 1500, NULL, 'Rendang'),
    ('Free Nasi Goreng', 2000, NULL, 'Nasi Goreng'),
    ('Diskon 20%', 2000, 20, NULL)
) AS v(reward_name, points_cost, discount_percent, free_menu_name)
LEFT JOIN menus m ON m.name = v.free_menu_name
ON CONFLICT (reward_name) DO UPDATE
SET
  points_cost = EXCLUDED.points_cost,
  discount_percent = EXCLUDED.discount_percent,
  free_menu_id = EXCLUDED.free_menu_id,
  is_active = TRUE,
  updated_at = NOW();

INSERT INTO member_reward_redemptions (
  member_id,
  reward_id,
  points_cost_snapshot,
  status,
  notes,
  redeemed_at
)
SELECT
  m.id,
  r.id,
  r.points_cost,
  'redeemed',
  'Seed data redemption',
  DATE '2026-04-15'
FROM members m
JOIN rewards r ON r.reward_name = 'Free Es Buah'
WHERE m.email = 'budi.s@email.com'
  AND NOT EXISTS (
    SELECT 1
    FROM member_reward_redemptions x
    WHERE x.member_id = m.id
      AND x.reward_id = r.id
      AND x.redeemed_at = DATE '2026-04-15'
  );

COMMIT;
