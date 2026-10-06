-- ==============================================================================
-- CREATE FAVORITES TABLE AND POLICIES
-- Run this in your Supabase Dashboard -> SQL Editor to fix 400 Bad Request
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, business_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "favorites_select" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete" ON public.favorites;

-- 1. Users can view their own favorites
CREATE POLICY "favorites_select" ON public.favorites
FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- 2. Users can add to their own favorites
CREATE POLICY "favorites_insert" ON public.favorites
FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- 3. Users can remove their own favorites
CREATE POLICY "favorites_delete" ON public.favorites
FOR DELETE TO authenticated
USING (user_id = auth.uid());

-- Grant access to authenticated users
GRANT ALL ON public.favorites TO authenticated;
