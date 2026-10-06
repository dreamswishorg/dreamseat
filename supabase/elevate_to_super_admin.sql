-- ==============================================================================
-- OPTIONAL: ELEVATE TO SUPER_ADMIN (Run in Supabase SQL Editor)
-- ==============================================================================
-- The admin user is ALREADY CREATED and can log in right now as 'admin'.
-- If you want the specific 'super_admin' badge/toggle, run these 3 lines:

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('customer', 'merchant', 'admin', 'super_admin'));

UPDATE public.profiles
SET role = 'super_admin'
WHERE email = 'admin@dreameats.fly.dev';
