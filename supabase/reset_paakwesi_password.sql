-- ==============================================================================
-- RESET PASSWORD FOR paakwesi4@gmail.com TO Dreams@2026
-- Copy and paste this into your Supabase Dashboard -> SQL Editor and click RUN
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Reset password in Supabase Auth to Dreams@2026
UPDATE auth.users
SET 
  encrypted_password = crypt('Dreams@2026', gen_salt('bf')),
  updated_at = NOW()
WHERE email ILIKE 'paakwesi4@gmail.com';

-- 2. Verify user account status
SELECT id, email, created_at, updated_at
FROM auth.users
WHERE email ILIKE 'paakwesi4@gmail.com';
