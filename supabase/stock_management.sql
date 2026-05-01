-- ============================================================
-- STOCK MANAGEMENT — Run in Supabase SQL Editor
-- ============================================================

-- 1. Add stock_quantity column to products
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS stock_quantity NUMERIC(12, 3) NOT NULL DEFAULT 0
  CHECK (stock_quantity >= 0);

-- Set initial stock for seeded products
UPDATE public.products SET stock_quantity = 100 WHERE stock_quantity = 0;

-- ──────────────────────────────────────────────────────────
-- 2. Trigger: auto-deduct stock when a sale is APPROVED
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_sale_approved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only act when status changes TO 'approved'
  IF NEW.status = 'approved' AND OLD.status <> 'approved' THEN
    UPDATE public.products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE id = NEW.product_id;

    -- Prevent stock going negative
    IF (SELECT stock_quantity FROM public.products WHERE id = NEW.product_id) < 0 THEN
      RAISE EXCEPTION 'Insufficient stock for product id %', NEW.product_id;
    END IF;
  END IF;

  -- If a previously approved sale is rejected, restore stock
  IF NEW.status = 'rejected' AND OLD.status = 'approved' THEN
    UPDATE public.products
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE id = NEW.product_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_sale_status_change ON public.sales;
CREATE TRIGGER on_sale_status_change
  AFTER UPDATE OF status ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.handle_sale_approved();

-- ──────────────────────────────────────────────────────────
-- 3. RPC: Admin adds stock to a product
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.add_stock(
  p_product_id INT,
  p_quantity   NUMERIC
)
RETURNS NUMERIC  -- returns new stock level
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_stock NUMERIC;
BEGIN
  UPDATE public.products
  SET stock_quantity = stock_quantity + p_quantity
  WHERE id = p_product_id
  RETURNING stock_quantity INTO v_new_stock;

  RETURN v_new_stock;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_stock(INT, NUMERIC) TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 4. Verify
-- ──────────────────────────────────────────────────────────
SELECT p.sub_option_name, c.name AS category, p.stock_quantity
FROM public.products p
JOIN public.categories c ON c.id = p.category_id
ORDER BY c.name, p.sub_option_name;
