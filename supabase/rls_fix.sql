-- ============================================================
-- RLS FIX: Eliminate infinite recursion on profiles table
-- Run this in Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- STEP 1: Create a SECURITY DEFINER helper function
-- This bypasses RLS to safely check the current user's role
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;


-- ─────────────────────────────────────────────────────────
-- STEP 2: Fix PROFILES policies (drop all, recreate cleanly)
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "profiles_self_read"    ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_read"   ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update"  ON public.profiles;

-- Any authenticated user can read any profile (name + role only - not sensitive)
CREATE POLICY "profiles_read_authenticated"
  ON public.profiles FOR SELECT
  USING (auth.role() = 'authenticated');

-- Users can only update their own profile
CREATE POLICY "profiles_self_update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Admins can update any profile (e.g., change staff roles)
CREATE POLICY "profiles_admin_update"
  ON public.profiles FOR UPDATE
  USING (public.get_my_role() = 'admin');


-- ─────────────────────────────────────────────────────────
-- STEP 3: Fix SALES policies (use get_my_role() instead of
--         inline subquery on profiles)
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "sales_staff_insert"          ON public.sales;
DROP POLICY IF EXISTS "sales_staff_select"          ON public.sales;
DROP POLICY IF EXISTS "sales_admin_select"          ON public.sales;
DROP POLICY IF EXISTS "sales_admin_update_status"   ON public.sales;

-- Staff: insert their own sales
CREATE POLICY "sales_staff_insert"
  ON public.sales FOR INSERT
  WITH CHECK (
    auth.uid() = staff_id AND
    public.get_my_role() = 'staff'
  );

-- Staff: read only their own sales
CREATE POLICY "sales_staff_select"
  ON public.sales FOR SELECT
  USING (auth.uid() = staff_id);

-- Admin: read ALL sales
CREATE POLICY "sales_admin_select"
  ON public.sales FOR SELECT
  USING (public.get_my_role() = 'admin');

-- Admin: update status field
CREATE POLICY "sales_admin_update_status"
  ON public.sales FOR UPDATE
  USING  (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');


-- ─────────────────────────────────────────────────────────
-- STEP 4: Fix CATEGORIES & PRODUCTS policies
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "categories_read_authenticated" ON public.categories;
DROP POLICY IF EXISTS "categories_admin_write"        ON public.categories;
DROP POLICY IF EXISTS "products_read_authenticated"   ON public.products;
DROP POLICY IF EXISTS "products_admin_write"          ON public.products;

CREATE POLICY "categories_read_authenticated"
  ON public.categories FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "categories_admin_write"
  ON public.categories FOR ALL
  USING (public.get_my_role() = 'admin');

CREATE POLICY "products_read_authenticated"
  ON public.products FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "products_admin_write"
  ON public.products FOR ALL
  USING (public.get_my_role() = 'admin');
