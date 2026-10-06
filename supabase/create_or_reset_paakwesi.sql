-- ==============================================================================
-- FIX 500 ERROR & CLEANLY CREATE USER paakwesi4@gmail.com
-- Copy and run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_existing_id UUID;
  v_instance_id UUID;
BEGIN
  -- Get active instance_id from existing users (fallback to all-zero UUID)
  SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;

  -- 1. Check if user already exists
  SELECT id INTO v_existing_id FROM auth.users WHERE email ILIKE 'paakwesi4@gmail.com' LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    -- Delete the incomplete manual record to rebuild cleanly with identity
    DELETE FROM auth.identities WHERE user_id = v_existing_id;
    DELETE FROM auth.users WHERE id = v_existing_id;
    DELETE FROM public.profiles WHERE id = v_existing_id;
  END IF;

  -- 2. Insert cleanly into auth.users
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
    'paakwesi4@gmail.com',
    crypt('Dreams@2026', gen_salt('bf')),
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"role": "customer", "full_name": "Paa Kwesi"}'::jsonb,
    'authenticated',
    'authenticated',
    NOW(),
    NOW()
  );

  -- 3. CRITICAL: Insert into auth.identities (Prevents Supabase Auth 500 Error)
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
    format('{"sub":"%s","email":"%s"}', v_user_id, 'paakwesi4@gmail.com')::jsonb,
    'email',
    v_user_id::text,
    NOW(),
    NOW(),
    NOW()
  );

  -- 4. Ensure user exists in public.profiles
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (v_user_id, 'paakwesi4@gmail.com', 'Paa Kwesi', 'customer')
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email, role = 'customer';

END $$;

-- 5. Verify creation
SELECT 
  u.id, 
  u.email, 
  i.provider AS identity_provider,
  p.role AS account_role
FROM auth.users u
JOIN auth.identities i ON i.user_id = u.id
JOIN public.profiles p ON p.id = u.id
WHERE u.email ILIKE 'paakwesi4@gmail.com';
