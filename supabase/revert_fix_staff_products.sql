-- Reverts fix_staff_products.sql — restores original combined policies
DROP POLICY IF EXISTS "products_admin_insert"    ON public.products;
DROP POLICY IF EXISTS "products_admin_update"    ON public.products;
DROP POLICY IF EXISTS "products_admin_delete"    ON public.products;
DROP POLICY IF EXISTS "categories_admin_insert"  ON public.categories;
DROP POLICY IF EXISTS "categories_admin_update"  ON public.categories;
DROP POLICY IF EXISTS "categories_admin_delete"  ON public.categories;

-- Restore the original FOR ALL policies from rls_fix.sql
CREATE POLICY "products_admin_write"
  ON public.products FOR ALL
  USING (public.get_my_role() = 'admin');

CREATE POLICY "categories_admin_write"
  ON public.categories FOR ALL
  USING (public.get_my_role() = 'admin');
