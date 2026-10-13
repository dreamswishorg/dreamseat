-- ==============================================================================
-- ADMIN USER SUSPENSION RPC & POLICIES
-- ==============================================================================

-- 1. Ensure public.auth_is_staff function supports both admin and super_admin
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

-- 2. Staff policy on public.profiles to allow updating any profile's suspension status
DROP POLICY IF EXISTS "profiles_update_staff" ON public.profiles;
CREATE POLICY "profiles_update_staff" ON public.profiles
  FOR UPDATE TO authenticated
  USING (public.auth_is_staff())
  WITH CHECK (public.auth_is_staff());

-- 3. Security Definer RPC for admin to safely toggle user suspension
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
