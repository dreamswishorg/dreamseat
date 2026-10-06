-- ==============================================================================
-- DREAMEATS SUPABASE STORAGE RLS POLICIES
-- Run this script in your Supabase Dashboard SQL Editor to fix 403 RLS errors!
-- ==============================================================================

-- 1. Ensure buckets exist and are public
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('user-avatars', 'user-avatars', true),
  ('uploads', 'uploads', true),
  ('merchant-logos', 'merchant-logos', true),
  ('deal_images', 'deal_images', true),
  ('business_branding', 'business_branding', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Note: storage.objects already has Row Level Security enabled by Supabase cloud default.

-- Drop existing policies if they exist to prevent duplication errors
DROP POLICY IF EXISTS "Public Read Access for Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Uploads to Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Updates in Storage Buckets" ON storage.objects;
DROP POLICY IF EXISTS "Allow File Deletions in Storage Buckets" ON storage.objects;

-- 3. Policy: Allow anyone (anon & authenticated) to read/view images
CREATE POLICY "Public Read Access for Storage Buckets"
ON storage.objects FOR SELECT
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 4. Policy: Allow anyone (or authenticated users) to upload new files
CREATE POLICY "Allow File Uploads to Storage Buckets"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 5. Policy: Allow updating existing files (upsert)
CREATE POLICY "Allow File Updates in Storage Buckets"
ON storage.objects FOR UPDATE
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 6. Policy: Allow deleting files
CREATE POLICY "Allow File Deletions in Storage Buckets"
ON storage.objects FOR DELETE
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));
