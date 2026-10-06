-- ==============================================================================
-- RESET PASSWORD / SETUP CUSTOMER: 1billion1@mail.com
-- Password: Dreams2026!
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_user_id UUID;
  v_instance_id UUID;
BEGIN
  -- Get active instance_id from existing users (fallback to zero UUID)
  SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;

  -- 1. Check if user already exists in auth.users
  SELECT id INTO v_user_id FROM auth.users WHERE email ILIKE '1billion1@mail.com' LIMIT 1;

  IF v_user_id IS NOT NULL THEN
    -- If user exists, reset password and update metadata
    UPDATE auth.users
    SET 
      encrypted_password = crypt('Dreams2026!', gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      raw_user_meta_data = jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{role}',
        '"customer"'
      ),
      updated_at = NOW()
    WHERE id = v_user_id;

    -- Ensure identity exists
    IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_user_id) THEN
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
        format('{"sub":"%s","email":"%s"}', v_user_id, '1billion1@mail.com')::jsonb,
        'email',
        v_user_id::text,
        NOW(),
        NOW(),
        NOW()
      );
    END IF;

    -- Ensure public.profiles is synced
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (v_user_id, '1billion1@mail.com', 'Customer 1Billion', 'customer')
    ON CONFLICT (id) DO UPDATE
    SET role = 'customer', email = EXCLUDED.email;

  ELSE
    -- If user does NOT exist, create clean user
    v_user_id := gen_random_uuid();

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
      '1billion1@mail.com',
      crypt('Dreams2026!', gen_salt('bf')),
      NOW(),
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      '{"role": "customer", "full_name": "Customer 1Billion"}'::jsonb,
      'authenticated',
      'authenticated',
      NOW(),
      NOW()
    );

    -- Insert identity
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
      format('{"sub":"%s","email":"%s"}', v_user_id, '1billion1@mail.com')::jsonb,
      'email',
      v_user_id::text,
      NOW(),
      NOW(),
      NOW()
    );

    -- Insert public.profiles
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (v_user_id, '1billion1@mail.com', 'Customer 1Billion', 'customer')
    ON CONFLICT (id) DO UPDATE
    SET role = 'customer', email = EXCLUDED.email;

  END IF;
END $$;

-- Verify setup
SELECT 
  u.id, 
  u.email, 
  p.role AS account_role,
  'Dreams2026!' AS active_password
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email ILIKE '1billion1@mail.com';
