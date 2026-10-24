-- ==============================================================================
-- DREAMEATS SUPABASE STORAGE SECURE RLS POLICIES
-- Run this script in your Supabase Dashboard SQL Editor to harden storage security!
-- ==============================================================================

-- 1. Ensure buckets exist and are public for media reads
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('user-avatars', 'user-avatars', true),
  ('uploads', 'uploads', true),
  ('merchant-logos', 'merchant-logos', true),
  ('deal_images', 'deal_images', true),
  ('business_branding', 'business_branding', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop previous permissive policies
DROP POLICY IF EXISTS "Public Read Access for Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Uploads to Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Updates in Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Deletions in Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Uploads Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Updates Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Secure Deletions Storage Buckets" ON storage.objects;

-- 2. Read Access: Anyone can view public images
CREATE POLICY "Public Read Access for Storage Buckets"
ON storage.objects FOR SELECT
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 3. Upload Access: Authenticated users only
CREATE POLICY "Secure Uploads Storage Buckets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding')
  AND (
    -- User uploading to their own user-avatars or uploads directory
    (storage.foldername(name))[1] = auth.uid()::text
    OR bucket_id IN ('merchant-logos', 'deal_images', 'business_branding')
    OR public.auth_is_staff()
  )
);

-- 4. Update Access: File owners or staff only
CREATE POLICY "Secure Updates Storage Buckets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  public.auth_is_staff()
  OR (storage.foldername(name))[1] = auth.uid()::text
  OR owner = auth.uid()
);

-- 5. Delete Access: File owners or staff only (blocks anonymous or malicious deletions)
CREATE POLICY "Secure Deletions Storage Buckets"
ON storage.objects FOR DELETE
TO authenticated
USING (
  public.auth_is_staff()
  OR (storage.foldername(name))[1] = auth.uid()::text
  OR owner = auth.uid()
);
