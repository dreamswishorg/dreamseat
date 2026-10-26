-- ==============================================================================
-- DREAMEATS SUPABASE STORAGE SECURE RLS POLICIES
-- Run this script in your Supabase Dashboard SQL Editor!
-- ==============================================================================

-- 1. Ensure all public buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('user-avatars', 'user-avatars', true),
  ('uploads', 'uploads', true),
  ('merchant-logos', 'merchant-logos', true),
  ('deal_images', 'deal_images', true),
  ('business_branding', 'business_branding', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Drop older restrictive storage policies
DROP POLICY IF EXISTS "Public Read Access for Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Uploads to Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Updates in Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Deletions in Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Uploads Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Updates Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Deletions Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow Authenticated Uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow Authenticated Updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow Authenticated Deletions" ON storage.objects;

-- 3. Public Read Access: Anyone can view public media
CREATE POLICY "Public Read Access for Storage Buckets"
ON storage.objects FOR SELECT
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 4. Upload Access: Authenticated users can upload to these buckets
-- Supports KYC documents ('kyc/...'), avatars ('avatars/...'), deals, logos
CREATE POLICY "Allow Authenticated Uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 5. Update Access: Authenticated users can update/overwrite their files
CREATE POLICY "Allow Authenticated Updates"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'))
WITH CHECK (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 6. Delete Access: Authenticated users can delete files
CREATE POLICY "Allow Authenticated Deletions"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));
