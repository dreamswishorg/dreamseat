-- ============================================================
-- DreamEats — Supabase Database Schema (CLEAN PRODUCTION VERSION)
-- ============================================================

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLE: profiles (Extends auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id              UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email           TEXT        NOT NULL,
  name            TEXT        NOT NULL,
  role            TEXT        NOT NULL CHECK (role IN ('customer', 'merchant', 'admin', 'super_admin')),
  phone           TEXT,
  avatar_url      TEXT,
  is_suspended    BOOLEAN     DEFAULT FALSE,
  dream_points    INTEGER     DEFAULT 0,
  referral_credit DECIMAL(10,2) DEFAULT 0.00,
  referral_code   TEXT        UNIQUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER FUNCTION: staff check
-- ============================================================
CREATE OR REPLACE FUNCTION public.auth_is_staff()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT role IN ('admin', 'super_admin') FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- TABLE: businesses
-- ============================================================
CREATE TABLE IF NOT EXISTS public.businesses (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name         TEXT        NOT NULL,
  description  TEXT        DEFAULT '',
  logo_url     TEXT        DEFAULT '',
  cover_url    TEXT        DEFAULT '',
  category     TEXT        NOT NULL,
  location     TEXT        DEFAULT 'Accra, Ghana',
  lat          DECIMAL(10,8),
  lng          DECIMAL(11,8),
  rating       DECIMAL(3,2) DEFAULT 0.00,
  is_approved  BOOLEAN     DEFAULT FALSE,
  phone        TEXT        NOT NULL DEFAULT '',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: merchant_documents (compliance uploads owned by a store)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.merchant_documents (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  doc_type         TEXT        NOT NULL CHECK (doc_type IN ('business_registration', 'health_certificate', 'tax_clearance')),
  reference_number TEXT        NOT NULL DEFAULT '',
  file_url         TEXT        NOT NULL DEFAULT '',
  status           TEXT        NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'verified', 'rejected')),
  reviewer_note    TEXT,
  uploaded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (business_id, doc_type)
);

ALTER TABLE public.merchant_documents ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: food_deals
-- ============================================================
CREATE TABLE IF NOT EXISTS public.food_deals (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id         UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  business_name       TEXT        NOT NULL,
  title               TEXT        NOT NULL,
  description         TEXT        DEFAULT '',
  category            TEXT        NOT NULL,
  original_price      DECIMAL(10,2) NOT NULL,
  discounted_price    DECIMAL(10,2) NOT NULL,
  pickup_window       TEXT        NOT NULL,
  quantity_remaining  INTEGER     NOT NULL DEFAULT 0 CHECK (quantity_remaining >= 0),
  quantity_total      INTEGER     NOT NULL DEFAULT 0,
  image_url           TEXT        DEFAULT '',
  is_active           BOOLEAN     DEFAULT TRUE,
  dietary_tags        TEXT[]      DEFAULT '{}',
  expires_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.food_deals ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: orders
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id             UUID        REFERENCES public.food_deals(id),
  business_id         UUID        REFERENCES public.businesses(id),
  customer_id         UUID        NOT NULL REFERENCES public.profiles(id),
  deal_title          TEXT        NOT NULL,
  business_name       TEXT        NOT NULL,
  customer_name       TEXT        NOT NULL,
  price               DECIMAL(10,2) NOT NULL,
  original_price      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  category            TEXT        NOT NULL DEFAULT 'Food Rescue',
  status              TEXT        DEFAULT 'reserved' CHECK (status IN ('reserved', 'preparing', 'ready', 'out_for_delivery', 'collected', 'cancelled', 'expired')),
  payment_method      TEXT        NOT NULL,
  payment_reference   TEXT        UNIQUE,
  collection_code     TEXT        NOT NULL,
  is_rated            BOOLEAN     DEFAULT FALSE,
  payout_status       TEXT        DEFAULT 'pending' CHECK (payout_status IN ('pending', 'processing', 'paid')),
  fulfillment_type    TEXT        NOT NULL DEFAULT 'pickup' CHECK (fulfillment_type IN ('pickup', 'delivery')),
  courier_name        TEXT,
  courier_phone       TEXT,
  tracking_notes      TEXT,
  delivery_address    TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID        NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  business_id   UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating        INTEGER     NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: audit_logs (EXCLUSIVE FOR STAFF TRACKING)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      UUID        REFERENCES public.profiles(id),
  actor_name    TEXT        NOT NULL,
  actor_role    TEXT        NOT NULL,
  action        TEXT        NOT NULL,
  entity_type   TEXT        NOT NULL,
  entity_id     TEXT,
  description   TEXT        NOT NULL,
  metadata      JSONB       DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, business_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: disputes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.disputes (
  id                UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID      REFERENCES public.orders(id),
  customer_id       UUID      REFERENCES public.profiles(id),
  merchant_id       UUID      REFERENCES public.profiles(id),
  issue_description TEXT      NOT NULL,
  status            TEXT      DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  chat_logs         JSONB     DEFAULT '[]'::jsonb,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: platform_settings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id                   INTEGER     PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  commission_rate      DECIMAL(5,4) DEFAULT 0.1500,
  min_app_version      TEXT        DEFAULT '1.0.0',
  maintenance_mode     BOOLEAN     DEFAULT FALSE,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read settings (needed for splash screen/maintenance check)
CREATE POLICY "platform_settings_select" ON public.platform_settings FOR SELECT USING (true);

-- ============================================================
-- TABLE: device_tokens (FCM)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token   TEXT        NOT NULL,
  platform    TEXT        DEFAULT 'mobile' CHECK (platform IN ('android', 'ios', 'web', 'mobile')),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_manage_own" ON public.device_tokens
  FOR ALL TO authenticated USING (user_id = auth.uid());

-- ============================================================
-- TABLE: notifications
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  screen      TEXT,
  data_id     TEXT,
  is_read     BOOLEAN     DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- ============================================================
-- TABLE: vouchers
-- ============================================================
CREATE TABLE IF NOT EXISTS public.vouchers (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code              TEXT        NOT NULL UNIQUE,
  discount_amount   DECIMAL(10,2) NOT NULL,
  discount_type     TEXT        NOT NULL CHECK (discount_type IN ('fixed', 'percentage')),
  expires_at        TIMESTAMPTZ,
  usage_limit       INTEGER     DEFAULT 100,
  usage_count       INTEGER     DEFAULT 0,
  is_active         BOOLEAN     DEFAULT TRUE,
  funded_by         TEXT        DEFAULT 'platform' CHECK (funded_by IN ('platform', 'merchant')),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: broadcasts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.broadcasts (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT        NOT NULL,
  message     TEXT        NOT NULL,
  audience    TEXT        NOT NULL CHECK (audience IN ('all', 'customers', 'merchants')),
  sent_by     UUID        REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: support_tickets
-- ============================================================
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id                UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID      REFERENCES public.profiles(id),
  user_name         TEXT      NOT NULL,
  subject           TEXT      NOT NULL,
  message           TEXT      NOT NULL,
  status            TEXT      DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
  priority          TEXT      DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  category          TEXT      DEFAULT 'general',
  assigned_to       UUID      REFERENCES public.profiles(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: ticket_replies
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ticket_replies (
  id                UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID      REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_id         UUID      REFERENCES public.profiles(id),
  sender_name       TEXT      NOT NULL,
  message           TEXT      NOT NULL,
  is_staff_reply    BOOLEAN   DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.ticket_replies ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICIES: PROFILES
-- ============================================================
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_staff" ON public.profiles;
CREATE POLICY "profiles_update_staff" ON public.profiles FOR UPDATE TO authenticated USING (public.auth_is_staff());

-- ============================================================
-- POLICIES: BUSINESSES
-- ============================================================
DROP POLICY IF EXISTS "businesses_select" ON public.businesses;
CREATE POLICY "businesses_select" ON public.businesses FOR SELECT USING (is_approved = TRUE OR owner_id = auth.uid() OR public.auth_is_staff());

DROP POLICY IF EXISTS "businesses_insert" ON public.businesses;
CREATE POLICY "businesses_insert" ON public.businesses FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "businesses_update" ON public.businesses;
CREATE POLICY "businesses_update" ON public.businesses FOR UPDATE TO authenticated USING (owner_id = auth.uid() OR public.auth_is_staff());

-- ============================================================
-- POLICIES: FOOD DEALS
-- ============================================================
DROP POLICY IF EXISTS "deals_select" ON public.food_deals;
CREATE POLICY "deals_select" ON public.food_deals FOR SELECT USING (is_active = TRUE OR public.auth_is_staff() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = food_deals.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "deals_insert" ON public.food_deals;
CREATE POLICY "deals_insert" ON public.food_deals FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "deals_update" ON public.food_deals;
CREATE POLICY "deals_update" ON public.food_deals FOR UPDATE TO authenticated USING (public.auth_is_staff() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = food_deals.business_id AND b.owner_id = auth.uid()));

-- ============================================================
-- POLICIES: ORDERS
-- ============================================================
DROP POLICY IF EXISTS "orders_select" ON public.orders;
CREATE POLICY "orders_select" ON public.orders FOR SELECT TO authenticated USING (customer_id = auth.uid() OR public.auth_is_staff() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = orders.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "orders_insert" ON public.orders;
CREATE POLICY "orders_insert" ON public.orders FOR INSERT TO authenticated WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "orders_update" ON public.orders;
CREATE POLICY "orders_update" ON public.orders FOR UPDATE TO authenticated USING (customer_id = auth.uid() OR public.auth_is_staff() OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = orders.business_id AND b.owner_id = auth.uid()));

-- ============================================================
-- POLICIES: MERCHANT DOCUMENTS
-- ============================================================
DROP POLICY IF EXISTS "merchant_docs_select_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_select_owner" ON public.merchant_documents FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "merchant_docs_insert_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_insert_owner" ON public.merchant_documents FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "merchant_docs_update_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_update_owner" ON public.merchant_documents FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "merchant_docs_delete_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_delete_owner" ON public.merchant_documents FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "merchant_docs_staff_all" ON public.merchant_documents;
CREATE POLICY "merchant_docs_staff_all" ON public.merchant_documents FOR ALL TO authenticated
  USING (public.auth_is_staff()) WITH CHECK (public.auth_is_staff());

-- ============================================================
-- POLICIES: AUDIT LOGS (SUPER ADMIN ONLY FOR SELECT, STAFF FOR INSERT)
-- ============================================================
DROP POLICY IF EXISTS "audit_logs_select" ON public.audit_logs;
CREATE POLICY "audit_logs_select" ON public.audit_logs FOR SELECT TO authenticated
  USING (public.auth_is_staff());

DROP POLICY IF EXISTS "audit_logs_insert" ON public.audit_logs;
CREATE POLICY "audit_logs_insert" ON public.audit_logs FOR INSERT TO authenticated
  WITH CHECK (public.auth_is_staff());

-- ============================================================
-- POLICIES: VOUCHERS
-- ============================================================
DROP POLICY IF EXISTS "vouchers_select" ON public.vouchers;
CREATE POLICY "vouchers_select" ON public.vouchers FOR SELECT USING (true);

DROP POLICY IF EXISTS "vouchers_all_staff" ON public.vouchers;
CREATE POLICY "vouchers_all_staff" ON public.vouchers FOR ALL TO authenticated USING (public.auth_is_staff());

-- ============================================================
-- POLICIES: BROADCASTS
-- ============================================================
DROP POLICY IF EXISTS "broadcasts_select" ON public.broadcasts;
CREATE POLICY "broadcasts_select" ON public.broadcasts FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "broadcasts_insert_staff" ON public.broadcasts;
CREATE POLICY "broadcasts_insert_staff" ON public.broadcasts FOR INSERT TO authenticated WITH CHECK (public.auth_is_staff());

-- ============================================================
-- POLICIES: SUPPORT TICKETS
-- ============================================================
DROP POLICY IF EXISTS "tickets_select" ON public.support_tickets;
CREATE POLICY "tickets_select" ON public.support_tickets FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.auth_is_staff());

DROP POLICY IF EXISTS "tickets_insert" ON public.support_tickets;
CREATE POLICY "tickets_insert" ON public.support_tickets FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "tickets_update_staff" ON public.support_tickets;
CREATE POLICY "tickets_update_staff" ON public.support_tickets FOR UPDATE TO authenticated
  USING (public.auth_is_staff());

-- ============================================================
-- POLICIES: TICKET REPLIES
-- ============================================================
DROP POLICY IF EXISTS "replies_select" ON public.ticket_replies;
CREATE POLICY "replies_select" ON public.ticket_replies FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND (t.user_id = auth.uid() OR public.auth_is_staff())));

DROP POLICY IF EXISTS "replies_insert" ON public.ticket_replies;
CREATE POLICY "replies_insert" ON public.ticket_replies FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND (t.user_id = auth.uid() OR public.auth_is_staff())));

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role, phone, referral_code)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    COALESCE(new.raw_user_meta_data->>'role', 'customer'),
    new.raw_user_meta_data->>'phone',
    'REF-' || UPPER(SUBSTRING(new.id::text FROM 1 FOR 8))
  );

  IF COALESCE(new.raw_user_meta_data->>'role', '') = 'merchant' THEN
    INSERT INTO public.businesses (id, owner_id, name, description, category, location, is_approved)
    VALUES (
      gen_random_uuid(),
      new.id,
      COALESCE(new.raw_user_meta_data->>'businessName', 'My Business'),
      COALESCE(new.raw_user_meta_data->>'businessDescription', ''),
      COALESCE(new.raw_user_meta_data->>'businessCategory', 'Restaurant Meal'),
      'Accra, Ghana',
      false
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.decrement_deal_quantity(deal_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.food_deals
  SET quantity_remaining = quantity_remaining - 1
  WHERE id = deal_id
    AND quantity_remaining > 0
    AND is_active = TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Deal is no longer available or sold out';
  END IF;
END;
$$;

-- Insert default settings
INSERT INTO public.platform_settings (id, commission_rate)
VALUES (1, 0.1500)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- RPC FUNCTIONS FOR DREAMPOINTS & REFERRALS
-- ============================================================

CREATE OR REPLACE FUNCTION public.increment_dream_points(user_id UUID, points_to_add INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET dream_points = COALESCE(dream_points, 0) + points_to_add
  WHERE id = user_id;
  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_dream_points(user_id UUID, points_to_deduct INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_pts INT;
BEGIN
  SELECT COALESCE(dream_points, 0) INTO current_pts FROM public.profiles WHERE id = user_id;
  IF current_pts < points_to_deduct THEN
    RETURN FALSE;
  END IF;
  UPDATE public.profiles
  SET dream_points = current_pts - points_to_deduct
  WHERE id = user_id;
  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.apply_referral_code(target_code TEXT, user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  referrer_id UUID;
  referrer_pts INT;
  my_credit DECIMAL;
BEGIN
  SELECT id, COALESCE(dream_points, 0) INTO referrer_id, referrer_pts FROM public.profiles WHERE referral_code = target_code;
  IF NOT FOUND OR referrer_id = user_id THEN
    RETURN FALSE;
  END IF;
  SELECT COALESCE(referral_credit, 0.0) INTO my_credit FROM public.profiles WHERE id = user_id;
  IF my_credit > 0 THEN
    RETURN FALSE;
  END IF;
  UPDATE public.profiles SET dream_points = referrer_pts + 100 WHERE id = referrer_id;
  UPDATE public.profiles SET referral_credit = 15.0 WHERE id = user_id;
  RETURN TRUE;
END;
$$;

-- Trigger to recalculate business rating on review submission
CREATE OR REPLACE FUNCTION public.update_business_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  avg_rating DECIMAL(3,2);
BEGIN
  SELECT ROUND(AVG(rating)::numeric, 2) INTO avg_rating FROM public.reviews WHERE business_id = NEW.business_id;
  UPDATE public.businesses SET rating = COALESCE(avg_rating, 5.00) WHERE id = NEW.business_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_review_inserted ON public.reviews;
CREATE TRIGGER on_review_inserted
  AFTER INSERT OR UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_business_rating();
