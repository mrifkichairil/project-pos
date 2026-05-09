BEGIN;

CREATE TABLE IF NOT EXISTS menus (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  category VARCHAR(50) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ingredients (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  base_unit VARCHAR(20) NOT NULL,
  price_per_unit NUMERIC(14,2) NOT NULL DEFAULT 0,
  supplier VARCHAR(120),
  stock NUMERIC(14,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS menu_ingredients (
  menu_id BIGINT NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
  ingredient_id BIGINT NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
  qty NUMERIC(14,2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (menu_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS menu_prices (
  id BIGSERIAL PRIMARY KEY,
  menu_id BIGINT NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
  hpp NUMERIC(14,2) NOT NULL,
  selling_price NUMERIC(14,2) NOT NULL,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_menus_category ON menus(category);
CREATE INDEX IF NOT EXISTS idx_menu_prices_menu_id ON menu_prices(menu_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_active ON menu_prices(menu_id) WHERE is_active;
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_prices_menu_start_date ON menu_prices(menu_id, start_date);

INSERT INTO ingredients (name, base_unit, price_per_unit, supplier, stock)
VALUES
  ('Kopi Arabica', 'gram', 40, 'PT Kopi Nusantara', 3500),
  ('Susu Full Cream', 'ml', 35, 'Indofood', 8000),
  ('Gula Pasir', 'gram', 25, 'Gulaku', 12000),
  ('Es Batu', 'gram', 8, 'CV Aneka Es', 200),
  ('Nasi', 'gram', 25, 'PT Beras Jaya', 25000),
  ('Ayam Fillet', 'gram', 60, 'PT Sumber Protein', 4500),
  ('Minyak Goreng', 'ml', 30, 'Bimoli', 6000),
  ('Telur', 'pcs', 2500, 'Peternakan Sejahtera', 300),
  ('Tepung Terigu', 'gram', 22, 'Segitiga Biru', 8000),
  ('Kecap Manis', 'ml', 40, 'ABC', 4000),
  ('Bawang', 'gram', 30, 'Sayurku', 5000),
  ('Daging Sapi', 'gram', 140, 'PT Daging Segar', 3000),
  ('Tusuk Sate', 'pcs', 100, 'CV Sate Jaya', 2000),
  ('Santan', 'ml', 50, 'Kara', 5000),
  ('Jeruk Peras', 'ml', 20, 'Petani Jeruk', 10000),
  ('Teh Hitam', 'gram', 80, 'Sariwangi', 2000),
  ('Sayur Sop', 'gram', 35, 'Sayurku', 6000),
  ('Kulit Lumpia', 'lembar', 500, 'Toko Kue', 500),
  ('Ubi', 'gram', 25, 'Petani Ubi', 8000),
  ('Kelapa Parut', 'gram', 35, 'CV Kelapa', 4000),
  ('Tepung Ketan', 'gram', 35, 'Bogasari', 3000),
  ('Gula Merah', 'gram', 32, 'Gula Jawa', 2500),
  ('Pisang', 'gram', 25, 'Petani Pisang', 10000),
  ('Roti Tawar', 'gram', 30, 'Sari Roti', 2000),
  ('Tepung Martabak', 'gram', 25, 'Bogasari', 4000),
  ('Susu Kental Manis', 'ml', 70, 'Indomilk', 3000),
  ('Susu UHT', 'ml', 30, 'Ultra', 6000),
  ('Coklat Bubuk', 'gram', 180, 'Silver Queen', 1000),
  ('Tepung Terigu Premium', 'gram', 30, 'Segitiga Biru', 5000),
  ('Margarin', 'gram', 50, 'Blue Band', 2000),
  ('Kacang Panjang', 'gram', 35, 'Sayurku', 3000),
  ('Kacang Tanah', 'gram', 45, 'PT Kacang', 4000)
ON CONFLICT (name) DO UPDATE
SET
  base_unit = EXCLUDED.base_unit,
  price_per_unit = EXCLUDED.price_per_unit,
  supplier = EXCLUDED.supplier,
  stock = EXCLUDED.stock,
  updated_at = NOW();

INSERT INTO menus (name, category)
VALUES
  ('Nasi Goreng', 'Main Dish'),
  ('Ayam Goreng', 'Main Dish'),
  ('Mie Goreng', 'Main Dish'),
  ('Sate Ayam', 'Main Dish'),
  ('Rendang', 'Main Dish'),
  ('Kopi Susu', 'Beverage'),
  ('Es Buah', 'Beverage'),
  ('Es Teh', 'Beverage'),
  ('Jus Jeruk', 'Beverage'),
  ('Kopi Hitam', 'Beverage'),
  ('Gado-Gado', 'Appetizer'),
  ('Bakso', 'Appetizer'),
  ('Soto', 'Appetizer'),
  ('Lumpia', 'Appetizer'),
  ('Risoles', 'Appetizer'),
  ('Klepon', 'Snack'),
  ('Onde-Onde', 'Snack'),
  ('Pisang Goreng', 'Snack'),
  ('Roti Bakar', 'Snack'),
  ('Martabak', 'Snack'),
  ('Es Krim', 'Dessert'),
  ('Pudding', 'Dessert'),
  ('Bolu', 'Dessert'),
  ('Donat', 'Dessert'),
  ('Cake', 'Dessert')
ON CONFLICT (name) DO UPDATE
SET
  category = EXCLUDED.category,
  updated_at = NOW();

INSERT INTO menu_ingredients (menu_id, ingredient_id, qty, unit)
SELECT m.id, i.id, v.qty, v.unit
FROM (
  VALUES
    ('Nasi Goreng', 'Nasi', 300, 'gram'),
    ('Nasi Goreng', 'Minyak Goreng', 15, 'ml'),
    ('Nasi Goreng', 'Telur', 1, 'pcs'),
    ('Nasi Goreng', 'Kecap Manis', 10, 'ml'),
    ('Nasi Goreng', 'Bawang', 20, 'gram'),

    ('Ayam Goreng', 'Ayam Fillet', 250, 'gram'),
    ('Ayam Goreng', 'Minyak Goreng', 50, 'ml'),
    ('Ayam Goreng', 'Tepung Terigu', 30, 'gram'),
    ('Ayam Goreng', 'Telur', 0.5, 'pcs'),

    ('Mie Goreng', 'Minyak Goreng', 10, 'ml'),
    ('Mie Goreng', 'Telur', 1, 'pcs'),
    ('Mie Goreng', 'Kecap Manis', 15, 'ml'),
    ('Mie Goreng', 'Bawang', 15, 'gram'),

    ('Sate Ayam', 'Ayam Fillet', 200, 'gram'),
    ('Sate Ayam', 'Tusuk Sate', 10, 'pcs'),
    ('Sate Ayam', 'Kecap Manis', 20, 'ml'),
    ('Sate Ayam', 'Minyak Goreng', 10, 'ml'),
    ('Sate Ayam', 'Bawang', 10, 'gram'),

    ('Rendang', 'Daging Sapi', 200, 'gram'),
    ('Rendang', 'Santan', 150, 'ml'),
    ('Rendang', 'Bawang', 20, 'gram'),
    ('Rendang', 'Minyak Goreng', 20, 'ml'),

    ('Kopi Susu', 'Kopi Arabica', 18, 'gram'),
    ('Kopi Susu', 'Susu Full Cream', 120, 'ml'),
    ('Kopi Susu', 'Gula Pasir', 10, 'gram'),

    ('Es Buah', 'Es Batu', 200, 'gram'),
    ('Es Buah', 'Gula Pasir', 30, 'gram'),

    ('Es Teh', 'Teh Hitam', 5, 'gram'),
    ('Es Teh', 'Gula Pasir', 15, 'gram'),
    ('Es Teh', 'Es Batu', 150, 'gram'),

    ('Jus Jeruk', 'Jeruk Peras', 200, 'ml'),
    ('Jus Jeruk', 'Gula Pasir', 15, 'gram'),
    ('Jus Jeruk', 'Es Batu', 100, 'gram'),

    ('Kopi Hitam', 'Kopi Arabica', 15, 'gram'),
    ('Kopi Hitam', 'Gula Pasir', 8, 'gram'),

    ('Gado-Gado', 'Sayur Sop', 150, 'gram'),
    ('Gado-Gado', 'Kacang Panjang', 50, 'gram'),
    ('Gado-Gado', 'Kacang Tanah', 30, 'gram'),
    ('Gado-Gado', 'Santan', 50, 'ml'),
    ('Gado-Gado', 'Minyak Goreng', 10, 'ml'),

    ('Bakso', 'Ayam Fillet', 100, 'gram'),
    ('Bakso', 'Tepung Terigu', 20, 'gram'),
    ('Bakso', 'Bawang', 10, 'gram'),
    ('Bakso', 'Minyak Goreng', 15, 'ml'),

    ('Soto', 'Ayam Fillet', 150, 'gram'),
    ('Soto', 'Santan', 100, 'ml'),
    ('Soto', 'Bawang', 15, 'gram'),
    ('Soto', 'Minyak Goreng', 10, 'ml'),

    ('Lumpia', 'Kulit Lumpia', 2, 'lembar'),
    ('Lumpia', 'Ubi', 100, 'gram'),
    ('Lumpia', 'Minyak Goreng', 30, 'ml'),
    ('Lumpia', 'Bawang', 5, 'gram'),

    ('Risoles', 'Tepung Terigu', 30, 'gram'),
    ('Risoles', 'Telur', 1, 'pcs'),
    ('Risoles', 'Minyak Goreng', 20, 'ml'),
    ('Risoles', 'Susu Full Cream', 30, 'ml'),

    ('Klepon', 'Tepung Ketan', 80, 'gram'),
    ('Klepon', 'Gula Merah', 20, 'gram'),
    ('Klepon', 'Kelapa Parut', 30, 'gram'),

    ('Onde-Onde', 'Tepung Terigu', 50, 'gram'),
    ('Onde-Onde', 'Kelapa Parut', 40, 'gram'),
    ('Onde-Onde', 'Gula Pasir', 15, 'gram'),
    ('Onde-Onde', 'Minyak Goreng', 20, 'ml'),

    ('Pisang Goreng', 'Pisang', 150, 'gram'),
    ('Pisang Goreng', 'Tepung Terigu', 30, 'gram'),
    ('Pisang Goreng', 'Minyak Goreng', 30, 'ml'),
    ('Pisang Goreng', 'Gula Pasir', 10, 'gram'),

    ('Roti Bakar', 'Roti Tawar', 100, 'gram'),
    ('Roti Bakar', 'Margarin', 15, 'gram'),
    ('Roti Bakar', 'Gula Pasir', 10, 'gram'),
    ('Roti Bakar', 'Susu Kental Manis', 10, 'ml'),

    ('Martabak', 'Tepung Martabak', 80, 'gram'),
    ('Martabak', 'Telur', 2, 'pcs'),
    ('Martabak', 'Minyak Goreng', 30, 'ml'),
    ('Martabak', 'Bawang', 10, 'gram'),

    ('Es Krim', 'Susu UHT', 200, 'ml'),
    ('Es Krim', 'Gula Pasir', 25, 'gram'),
    ('Es Krim', 'Coklat Bubuk', 10, 'gram'),

    ('Pudding', 'Susu UHT', 150, 'ml'),
    ('Pudding', 'Gula Pasir', 20, 'gram'),
    ('Pudding', 'Tepung Terigu Premium', 15, 'gram'),

    ('Bolu', 'Tepung Terigu Premium', 100, 'gram'),
    ('Bolu', 'Telur', 2, 'pcs'),
    ('Bolu', 'Gula Pasir', 50, 'gram'),
    ('Bolu', 'Margarin', 30, 'gram'),

    ('Donat', 'Tepung Terigu Premium', 80, 'gram'),
    ('Donat', 'Telur', 1, 'pcs'),
    ('Donat', 'Gula Pasir', 30, 'gram'),
    ('Donat', 'Minyak Goreng', 30, 'ml'),

    ('Cake', 'Tepung Terigu Premium', 120, 'gram'),
    ('Cake', 'Telur', 3, 'pcs'),
    ('Cake', 'Gula Pasir', 80, 'gram'),
    ('Cake', 'Margarin', 50, 'gram')
) AS v(menu_name, ingredient_name, qty, unit)
JOIN menus m ON m.name = v.menu_name
JOIN ingredients i ON i.name = v.ingredient_name
ON CONFLICT (menu_id, ingredient_id) DO UPDATE
SET
  qty = EXCLUDED.qty,
  unit = EXCLUDED.unit,
  updated_at = NOW();

UPDATE menu_prices
SET is_active = FALSE,
    end_date = CURRENT_DATE,
    updated_at = NOW()
WHERE is_active = TRUE;

INSERT INTO menu_prices (menu_id, hpp, selling_price, start_date, is_active)
SELECT m.id, v.hpp, v.selling_price, CURRENT_DATE, TRUE
FROM (
  VALUES
    ('Nasi Goreng', 10500, 35000),
    ('Kopi Susu', 6600, 22000),
    ('Es Buah', 7800, 26000),
    ('Ayam Goreng', 12000, 40000),
    ('Mie Goreng', 9600, 32000),
    ('Sate Ayam', 11400, 38000),
    ('Rendang', 16500, 55000),
    ('Es Teh', 2400, 8000),
    ('Jus Jeruk', 5400, 18000),
    ('Kopi Hitam', 4500, 15000),
    ('Gado-Gado', 7500, 25000),
    ('Bakso', 8400, 28000),
    ('Soto', 9000, 30000),
    ('Lumpia', 6000, 20000),
    ('Risoles', 5400, 18000),
    ('Klepon', 4500, 15000),
    ('Onde-Onde', 4800, 16000),
    ('Pisang Goreng', 5400, 18000),
    ('Roti Bakar', 6000, 20000),
    ('Martabak', 7500, 25000),
    ('Es Krim', 7500, 25000),
    ('Pudding', 6000, 20000),
    ('Bolu', 10500, 35000),
    ('Donat', 6600, 22000),
    ('Cake', 13500, 45000)
) AS v(menu_name, hpp, selling_price)
JOIN menus m ON m.name = v.menu_name
ON CONFLICT (menu_id, start_date) DO UPDATE
SET
  hpp = EXCLUDED.hpp,
  selling_price = EXCLUDED.selling_price,
  is_active = TRUE,
  end_date = NULL,
  updated_at = NOW();

COMMIT;
