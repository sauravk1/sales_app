-- Run in Supabase SQL Editor to check & re-seed products
-- ─────────────────────────────────────────────────────
-- STEP 1: Check current state
SELECT c.name as category, p.sub_option_name, p.base_rate
FROM products p JOIN categories c ON c.id = p.category_id
ORDER BY c.name, p.sub_option_name;

-- ─────────────────────────────────────────────────────
-- STEP 2: If above returns 0 rows, run this seed block:
-- ─────────────────────────────────────────────────────
INSERT INTO public.products (category_id, sub_option_name, base_rate)
SELECT c.id, v.sub_option_name, v.base_rate
FROM (VALUES
  ('Cement',        'ACC',           380.00),
  ('Cement',        'Birla',         370.00),
  ('Cement',        'UltraTech',     390.00),
  ('Cement',        'Ambuja',        375.00),
  ('Rod / Steel',   'TATA Steel',     65.00),
  ('Rod / Steel',   'JSW',            63.00),
  ('Rod / Steel',   'SAIL',           61.00),
  ('Sand',          'River Sand',     55.00),
  ('Sand',          'M-Sand',         42.00),
  ('Bricks',        'Red Bricks',      8.50),
  ('Bricks',        'Fly Ash',         6.50),
  ('Aggregates',    '20mm Gravel',    48.00),
  ('Aggregates',    '40mm Gravel',    45.00),
  ('Paint',         'Asian Paints',  210.00),
  ('Paint',         'Berger',        195.00),
  ('Tiles',         'Kajaria',        95.00),
  ('Tiles',         'Somany',         88.00)
) AS v(category_name, sub_option_name, base_rate)
JOIN public.categories c ON c.name = v.category_name
ON CONFLICT (category_id, sub_option_name) DO NOTHING;

-- Confirm:
SELECT COUNT(*) as total_products FROM public.products;
