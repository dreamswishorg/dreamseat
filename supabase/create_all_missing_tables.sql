-- ==============================================================================
-- CREATE ALL MISSING TABLES & RLS POLICIES (Fixes 400 Bad Request errors)
-- Copy and paste this entire script into your Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. FAVORITES TABLE
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

-- 2. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID  REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  rating      INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reviews_select" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
GRANT ALL ON public.reviews TO authenticated;

-- 3. DISPUTES TABLE
CREATE TABLE IF NOT EXISTS public.disputes (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID  REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason      TEXT  NOT NULL,
  status      TEXT  DEFAULT 'open',
  chat_logs   JSONB[] DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "disputes_select" ON public.disputes;
DROP POLICY IF EXISTS "disputes_insert" ON public.disputes;
CREATE POLICY "disputes_select" ON public.disputes FOR SELECT TO authenticated USING (true);
CREATE POLICY "disputes_insert" ON public.disputes FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
GRANT ALL ON public.disputes TO authenticated;

-- 4. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT  NOT NULL,
  message     TEXT  NOT NULL,
  is_read     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.notifications TO authenticated;

-- 5. USER PUSH TOKENS
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  user_id     UUID  PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT  NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tokens_select" ON public.user_push_tokens;
DROP POLICY IF EXISTS "tokens_insert" ON public.user_push_tokens;
CREATE POLICY "tokens_select" ON public.user_push_tokens FOR SELECT TO authenticated USING (true);
CREATE POLICY "tokens_insert" ON public.user_push_tokens FOR ALL TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.user_push_tokens TO authenticated;

-- 6. PLATFORM SETTINGS
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id          INTEGER PRIMARY KEY DEFAULT 1,
  commission_rate NUMERIC DEFAULT 10.0,
  maintenance_mode BOOLEAN DEFAULT false,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "settings_select" ON public.platform_settings;
CREATE POLICY "settings_select" ON public.platform_settings FOR SELECT TO authenticated USING (true);
GRANT ALL ON public.platform_settings TO authenticated;
INSERT INTO public.platform_settings (id, commission_rate, maintenance_mode) VALUES (1, 10.0, false) ON CONFLICT (id) DO NOTHING;

-- 7. VOUCHERS, BROADCASTS & SUPPORT TICKETS
CREATE TABLE IF NOT EXISTS public.vouchers (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT  UNIQUE NOT NULL,
  discount    NUMERIC NOT NULL,
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "vouchers_select" ON public.vouchers;
CREATE POLICY "vouchers_select" ON public.vouchers FOR SELECT TO authenticated USING (true);
GRANT ALL ON public.vouchers TO authenticated;

CREATE TABLE IF NOT EXISTS public.broadcasts (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT  NOT NULL,
  message     TEXT  NOT NULL,
  target_role TEXT  DEFAULT 'all',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "broadcasts_select" ON public.broadcasts;
CREATE POLICY "broadcasts_select" ON public.broadcasts FOR SELECT TO authenticated USING (true);
GRANT ALL ON public.broadcasts TO authenticated;

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject     TEXT  NOT NULL,
  message     TEXT  NOT NULL,
  status      TEXT  DEFAULT 'open',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tickets_select" ON public.support_tickets;
DROP POLICY IF EXISTS "tickets_insert" ON public.support_tickets;
CREATE POLICY "tickets_select" ON public.support_tickets FOR SELECT TO authenticated USING (true);
CREATE POLICY "tickets_insert" ON public.support_tickets FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
GRANT ALL ON public.support_tickets TO authenticated;
