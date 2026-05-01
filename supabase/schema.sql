-- ============================================================
-- SALES APP - Supabase PostgreSQL Schema
-- Run this script in Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────
-- 1. PROFILES (linked to auth.users)
-- ─────────────────────────────────────────
CREATE TABLE public.profiles (
  id        UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role      TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
  full_name TEXT NOT NULL
);

-- Auto-create profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Unknown'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'staff')
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────
-- 2. CATEGORIES
-- ─────────────────────────────────────────
CREATE TABLE public.categories (
  id   SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

-- Seed initial categories
INSERT INTO public.categories (name) VALUES
  ('Cement'),
  ('Rod / Steel'),
  ('Sand'),
  ('Bricks'),
  ('Aggregates'),
  ('Paint'),
  ('Tiles');

-- ─────────────────────────────────────────
-- 3. PRODUCTS (Sub-options per category)
-- ─────────────────────────────────────────
CREATE TABLE public.products (
  id              SERIAL PRIMARY KEY,
  category_id     INT NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  sub_option_name TEXT NOT NULL,
  base_rate       NUMERIC(12, 2) NOT NULL CHECK (base_rate >= 0),
  UNIQUE (category_id, sub_option_name)
);

-- Seed sample products
INSERT INTO public.products (category_id, sub_option_name, base_rate) VALUES
  (1, 'ACC',        380.00),
  (1, 'Birla',      370.00),
  (1, 'UltraTech',  390.00),
  (1, 'Ambuja',     375.00),
  (2, 'TATA Steel', 65.00),
  (2, 'JSW',        63.00),
  (2, 'SAIL',       61.00),
  (3, 'River Sand', 55.00),
  (3, 'M-Sand',     42.00),
  (4, 'Red Bricks', 8.50),
  (4, 'Fly Ash',    6.50),
  (5, '20mm Gravel',48.00),
  (5, '40mm Gravel',45.00),
  (6, 'Asian Paints', 210.00),
  (6, 'Berger',     195.00),
  (7, 'Kajaria',    95.00),
  (7, 'Somany',     88.00);

-- ─────────────────────────────────────────
-- 4. SALES TABLE
-- ─────────────────────────────────────────
CREATE TABLE public.sales (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id   INT NOT NULL REFERENCES public.products(id),
  quantity     NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
  rate         NUMERIC(12, 2) NOT NULL CHECK (rate >= 0),
  total_amount NUMERIC(14, 2) GENERATED ALWAYS AS (quantity * rate) STORED,
  staff_id     UUID NOT NULL REFERENCES public.profiles(id),
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  sale_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for common query patterns
CREATE INDEX idx_sales_staff_id    ON public.sales(staff_id);
CREATE INDEX idx_sales_status      ON public.sales(status);
CREATE INDEX idx_sales_sale_date   ON public.sales(sale_date);
CREATE INDEX idx_sales_created_at  ON public.sales(created_at DESC);

-- ─────────────────────────────────────────
-- 5. ROW LEVEL SECURITY
-- ─────────────────────────────────────────

-- Profiles: users can read/update own profile; admins can read all
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_self_read"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_admin_read"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

CREATE POLICY "profiles_self_update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Categories & Products: readable by all authenticated users
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "categories_read_authenticated"
  ON public.categories FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "categories_admin_write"
  ON public.categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "products_read_authenticated"
  ON public.products FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "products_admin_write"
  ON public.products FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Sales RLS
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

-- Staff: Insert own sales
CREATE POLICY "sales_staff_insert"
  ON public.sales FOR INSERT
  WITH CHECK (
    auth.uid() = staff_id AND
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'staff')
  );

-- Staff: Read own sales only
CREATE POLICY "sales_staff_select"
  ON public.sales FOR SELECT
  USING (
    auth.uid() = staff_id
  );

-- Admin: Read ALL sales
CREATE POLICY "sales_admin_select"
  ON public.sales FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin: Update status only
CREATE POLICY "sales_admin_update_status"
  ON public.sales FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ─────────────────────────────────────────
-- 6. RPC: REVENUE ANALYTICS FUNCTION
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_revenue_summary(
  p_start_date DATE,
  p_end_date   DATE
)
RETURNS TABLE (
  total_revenue   NUMERIC,
  total_sales     BIGINT,
  avg_sale_value  NUMERIC,
  by_category     JSONB
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH approved AS (
    SELECT
      s.total_amount,
      c.name AS category_name
    FROM public.sales s
    JOIN public.products  p ON p.id = s.product_id
    JOIN public.categories c ON c.id = p.category_id
    WHERE s.status    = 'approved'
      AND s.sale_date BETWEEN p_start_date AND p_end_date
  ),
  summary AS (
    SELECT
      COALESCE(SUM(total_amount), 0)::NUMERIC  AS total_revenue,
      COUNT(*)::BIGINT                          AS total_sales,
      COALESCE(AVG(total_amount), 0)::NUMERIC   AS avg_sale_value
    FROM approved
  ),
  by_cat AS (
    SELECT jsonb_object_agg(
      category_name,
      ROUND(SUM(total_amount)::NUMERIC, 2)
    ) AS by_category
    FROM approved
    GROUP BY category_name
  )
  SELECT
    s.total_revenue,
    s.total_sales,
    ROUND(s.avg_sale_value, 2),
    COALESCE(bc.by_category, '{}'::JSONB)
  FROM summary s, by_cat bc;
END;
$$;

-- Grant execute to authenticated users (RLS is SECURITY DEFINER internally)
GRANT EXECUTE ON FUNCTION public.get_revenue_summary TO authenticated;

-- ─────────────────────────────────────────
-- 7. RPC: PENDING SALES COUNT (for badge)
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_pending_sales_count()
RETURNS BIGINT
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT COUNT(*) FROM public.sales WHERE status = 'pending';
$$;

GRANT EXECUTE ON FUNCTION public.get_pending_sales_count TO authenticated;

-- ─────────────────────────────────────────
-- 8. REALTIME (enable for live dashboard)
-- ─────────────────────────────────────────
-- Run in Supabase Dashboard → Database → Replication → Tables
-- OR via SQL:
ALTER PUBLICATION supabase_realtime ADD TABLE public.sales;
