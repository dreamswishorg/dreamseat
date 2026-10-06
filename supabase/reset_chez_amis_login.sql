-- ==============================================================================
-- FIX "NO BUSINESS PROFILE FOUND" & LINK CHEZ AMIS TO Vandyckkarljojo@gmail.com
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Reset password for Vandyckkarljojo@gmail.com to ChezAmis2026!
UPDATE auth.users
SET 
  encrypted_password = crypt('ChezAmis2026!', gen_salt('bf')),
  raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"merchant"'
  ),
  updated_at = NOW()
WHERE email ILIKE 'Vandyckkarljojo@gmail.com';

-- 2. Ensure their profile role is set to 'merchant' in public.profiles
UPDATE public.profiles
SET role = 'merchant'
WHERE email ILIKE 'Vandyckkarljojo@gmail.com' OR id IN (
  SELECT id FROM auth.users WHERE email ILIKE 'Vandyckkarljojo@gmail.com'
);

-- 3. If Chez Amis business exists, assign Vandyckkarljojo@gmail.com as the owner & approve it
UPDATE public.businesses
SET 
  owner_id = (SELECT id FROM auth.users WHERE email ILIKE 'Vandyckkarljojo@gmail.com' LIMIT 1),
  is_approved = true
WHERE name ILIKE '%Chez Amis%';

-- 4. If Chez Amis does NOT exist yet in public.businesses, insert it linked to Vandyckkarljojo@gmail.com
INSERT INTO public.businesses (
  id,
  owner_id,
  name,
  description,
  category,
  location,
  rating,
  is_approved
)
SELECT 
  gen_random_uuid(),
  u.id,
  'Chez Amis',
  'Authentic Ghanaian & Continental Cuisine rescuing delicious fresh surplus meals.',
  'Restaurant',
  'East Legon, Accra, Ghana',
  4.80,
  true
FROM auth.users u
WHERE u.email ILIKE 'Vandyckkarljojo@gmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.businesses b WHERE b.owner_id = u.id OR b.name ILIKE '%Chez Amis%'
  );

-- 5. Verify and display the linked account & business details
SELECT 
  u.email AS merchant_email,
  p.role AS account_role,
  b.name AS business_name,
  b.is_approved AS business_approved,
  'ChezAmis2026!' AS active_password
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.businesses b ON b.owner_id = u.id
WHERE u.email ILIKE 'Vandyckkarljojo@gmail.com';
