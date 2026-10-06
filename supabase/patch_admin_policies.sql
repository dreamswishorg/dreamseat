-- Fix missing policies that failed on first run due to auth_user_role() not existing yet
-- Run this in Supabase Dashboard → SQL Editor

-- profiles: admin update policy (was skipped on first run)
DROP POLICY IF EXISTS "profiles_update_admin" ON profiles;
CREATE POLICY "profiles_update_admin" ON profiles
  FOR UPDATE TO authenticated
  USING (auth_user_role() = 'admin');

-- businesses: admin delete policy
DROP POLICY IF EXISTS "businesses_delete_admin" ON businesses;
CREATE POLICY "businesses_delete_admin" ON businesses
  FOR DELETE TO authenticated
  USING (auth_user_role() = 'admin');

-- food_deals: admin update access
DROP POLICY IF EXISTS "deals_update_admin" ON food_deals;
CREATE POLICY "deals_update_admin" ON food_deals
  FOR UPDATE TO authenticated
  USING (auth_user_role() = 'admin');

-- orders: admin select all
DROP POLICY IF EXISTS "orders_select_admin" ON orders;
CREATE POLICY "orders_select_admin" ON orders
  FOR SELECT TO authenticated
  USING (auth_user_role() = 'admin');

-- disputes: admin update/resolve
DROP POLICY IF EXISTS "disputes_update_admin" ON disputes;
CREATE POLICY "disputes_update_admin" ON disputes
  FOR UPDATE TO authenticated
  USING (auth_user_role() = 'admin');

-- platform_settings: admin write
DROP POLICY IF EXISTS "settings_write_admin" ON platform_settings;
CREATE POLICY "settings_write_admin" ON platform_settings
  FOR ALL TO authenticated
  USING (auth_user_role() = 'admin')
  WITH CHECK (auth_user_role() = 'admin');

-- Verify the auth_user_role function is working
SELECT auth_user_role();
