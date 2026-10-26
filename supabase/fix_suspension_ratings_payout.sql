-- ==============================================================================
-- DREAMEATS DATABASE FIX SCRIPT: PAYOUT, PHONE & SUSPENSION
-- Run this in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Ensure 'phone' and all business columns exist on public.businesses
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS phone TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_provider TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_account_name TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_account_number TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS opening_time TEXT DEFAULT '08:00',
  ADD COLUMN IF NOT EXISTS closing_time TEXT DEFAULT '22:00';

-- 2. Notify PostgREST to refresh its schema cache
NOTIFY pgrst, 'reload schema';

-- 3. Fix Staff Check Function
CREATE OR REPLACE FUNCTION public.auth_is_staff()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

-- 4. Staff policy on public.profiles to allow updating any user's suspension
DROP POLICY IF EXISTS "profiles_update_staff" ON public.profiles;
CREATE POLICY "profiles_update_staff" ON public.profiles
  FOR UPDATE TO authenticated
  USING (public.auth_is_staff())
  WITH CHECK (public.auth_is_staff());

-- 5. RPC function for Admins to toggle user suspension safely
CREATE OR REPLACE FUNCTION public.admin_toggle_user_suspension(target_user_id UUID, should_suspend BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: staff privileges required';
  END IF;

  UPDATE public.profiles
  SET is_suspended = should_suspend
  WHERE id = target_user_id;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_toggle_user_suspension(UUID, BOOLEAN) TO authenticated;
