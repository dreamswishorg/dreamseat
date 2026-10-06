-- ==============================================================================
-- FIX RLS POLICIES AND MISSING TABLES (Matches exact schema.sql columns)
-- ==============================================================================

-- 1. FAVORITES TABLE & POLICIES
CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, business_id)
);
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "favorites_select" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete" ON public.favorites;
CREATE POLICY "favorites_select" ON public.favorites FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "favorites_insert" ON public.favorites FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "favorites_delete" ON public.favorites FOR DELETE TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.favorites TO authenticated;

-- 2. REVIEWS POLICIES (Using customer_id)
ALTER TABLE IF EXISTS public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reviews_select" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT TO authenticated WITH CHECK (customer_id = auth.uid());
GRANT ALL ON public.reviews TO authenticated;

-- 3. DISPUTES POLICIES (Using customer_id and merchant_id)
ALTER TABLE IF EXISTS public.disputes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "disputes_select" ON public.disputes;
DROP POLICY IF EXISTS "disputes_insert" ON public.disputes;
CREATE POLICY "disputes_select" ON public.disputes FOR SELECT TO authenticated USING (customer_id = auth.uid() OR merchant_id = auth.uid());
CREATE POLICY "disputes_insert" ON public.disputes FOR INSERT TO authenticated WITH CHECK (customer_id = auth.uid());
GRANT ALL ON public.disputes TO authenticated;

-- 4. PLATFORM SETTINGS
ALTER TABLE IF EXISTS public.platform_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "platform_settings_select" ON public.platform_settings;
CREATE POLICY "platform_settings_select" ON public.platform_settings FOR SELECT USING (true);
GRANT ALL ON public.platform_settings TO authenticated;

-- 5. DEVICE TOKENS
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT  NOT NULL,
  platform    TEXT  DEFAULT 'android',
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tokens_select" ON public.device_tokens;
DROP POLICY IF EXISTS "tokens_insert" ON public.device_tokens;
CREATE POLICY "tokens_select" ON public.device_tokens FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "tokens_insert" ON public.device_tokens FOR ALL TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.device_tokens TO authenticated;
