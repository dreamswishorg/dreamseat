-- ==============================================================================
-- RESET CHEZ AMIS MERCHANT LOGIN & ENSURE BUSINESS PROFILE IS LINKED
-- Run this in your Supabase Dashboard -> SQL Editor (Click 'Run')
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_user_id UUID;
  v_email TEXT := 'vandyckkarljojo@gmail.com';
  v_password TEXT := 'ChezAmis2026!';
BEGIN
  -- 1. Check if the user exists in auth.users
  SELECT id INTO v_user_id FROM auth.users WHERE LOWER(email) = LOWER(v_email);

  -- 2. Create user if they do not exist
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      role,
      aud
    ) VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      v_email,
      crypt(v_password, gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Chez Amis","role":"merchant"}'::jsonb,
      NOW(),
      NOW(),
      'authenticated',
      'authenticated'
    );
  ELSE
    -- Reset password and confirm email
    UPDATE auth.users
    SET 
      encrypted_password = crypt(v_password, gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      raw_user_meta_data = jsonb_set(COALESCE(raw_user_meta_data, '{}'::jsonb), '{role}', '"merchant"'),
      updated_at = NOW()
    WHERE id = v_user_id;
  END IF;

  -- 3. Ensure profile in public.profiles is merchant
  INSERT INTO public.profiles (id, email, name, role, updated_at)
  VALUES (v_user_id, v_email, 'Chez Amis Restaurant', 'merchant', NOW())
  ON CONFLICT (id) DO UPDATE SET 
    role = 'merchant',
    updated_at = NOW();

  -- 4. Link or create Chez Amis in public.businesses
  IF EXISTS (SELECT 1 FROM public.businesses WHERE name ILIKE '%Chez Amis%') THEN
    UPDATE public.businesses
    SET 
      owner_id = v_user_id,
      is_approved = true
    WHERE name ILIKE '%Chez Amis%';
  ELSE
    INSERT INTO public.businesses (
      id,
      owner_id,
      name,
      description,
      category,
      location,
      rating,
      is_approved
    ) VALUES (
      gen_random_uuid(),
      v_user_id,
      'Chez Amis',
      'Authentic Ghanaian & Continental Cuisine rescuing delicious fresh surplus meals.',
      'Restaurant Meal',
      'East Legon, Accra, Ghana',
      4.80,
      true
    );
  END IF;

  RAISE NOTICE '✅ Chez Amis login reset successfully to % with password %', v_email, v_password;
END $$;

-- Verify result
SELECT 
  u.email AS merchant_email,
  p.role AS profile_role,
  b.name AS business_name,
  b.is_approved AS business_approved,
  'ChezAmis2026!' AS active_password
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.businesses b ON b.owner_id = u.id
WHERE LOWER(u.email) = 'vandyckkarljojo@gmail.com';

