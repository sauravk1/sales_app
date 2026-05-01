-- Run this in Supabase SQL Editor
-- Fixes products/categories READ for staff users

-- Separate the admin WRITE policy so it doesn't cover SELECT
DROP POLICY IF EXISTS "products_admin_write"    ON public.products;
DROP POLICY IF EXISTS "categories_admin_write"  ON public.categories;

-- Admin write: only covers INSERT, UPDATE, DELETE (not SELECT)
CREATE POLICY "products_admin_insert"
  ON public.products FOR INSERT
  WITH CHECK (public.get_my_role() = 'admin');

CREATE POLICY "products_admin_update"
  ON public.products FOR UPDATE
  USING (public.get_my_role() = 'admin');

CREATE POLICY "products_admin_delete"
  ON public.products FOR DELETE
  USING (public.get_my_role() = 'admin');

CREATE POLICY "categories_admin_insert"
  ON public.categories FOR INSERT
  WITH CHECK (public.get_my_role() = 'admin');

CREATE POLICY "categories_admin_update"
  ON public.categories FOR UPDATE
  USING (public.get_my_role() = 'admin');

CREATE POLICY "categories_admin_delete"
  ON public.categories FOR DELETE
  USING (public.get_my_role() = 'admin');

-- Verify staff can now read products (run as a test):
-- SELECT COUNT(*) FROM public.products;
