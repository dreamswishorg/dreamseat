-- ==============================================================================
-- DREAMSEAT SUPER ADMIN CREATION / PASSWORD RESET SCRIPT
-- ==============================================================================
-- Instructions:
-- 1. Open your Supabase Dashboard (https://supabase.com/dashboard/project/trhefcuuhwavbdqhgamr)
-- 2. Go to the "SQL Editor" tab on the left sidebar
-- 3. Paste this entire script and click "RUN"
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_admin_email TEXT := 'admin@dreameats.fly.dev';
  v_admin_password TEXT := 'Admin@DreamEats2026!';
  v_user_id UUID := gen_random_uuid();
  v_existing_id UUID;
  v_instance_id UUID;
BEGIN
  -- Get active instance_id from existing users (fallback to zero UUID)
  SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;

  -- 1. Clean up any existing record for this email
  SELECT id INTO v_existing_id FROM auth.users WHERE email ILIKE v_admin_email LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    DELETE FROM auth.identities WHERE user_id = v_existing_id;
    DELETE FROM public.profiles WHERE id = v_existing_id;
    DELETE FROM auth.users WHERE id = v_existing_id;
  END IF;

  -- 2. Insert into auth.users with encrypted password & verified email
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_instance_id,
    v_admin_email,
    crypt(v_admin_password, gen_salt('bf')),
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"role": "super_admin", "name": "Super Admin", "full_name": "Super Admin"}'::jsonb,
    'authenticated',
    'authenticated',
    NOW(),
    NOW()
  );

  -- 3. Insert into auth.identities (Prevents GoTrue Auth 500 Schema error)
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    format('{"sub":"%s","email":"%s"}', v_user_id, v_admin_email)::jsonb,
    'email',
    v_user_id::text,
    NOW(),
    NOW(),
    NOW()
  );

  -- 4. Insert or update public.profiles with super_admin role
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (v_user_id, v_admin_email, 'Super Admin', 'super_admin')
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email, role = 'super_admin';

END $$;

-- 5. Confirmation output
SELECT 
  u.id, 
  u.email, 
  u.email_confirmed_at,
  i.provider AS identity_provider,
  p.role AS account_role
FROM auth.users u
JOIN auth.identities i ON i.user_id = u.id
JOIN public.profiles p ON p.id = u.id
WHERE u.email ILIKE 'admin@dreameats.fly.dev';
