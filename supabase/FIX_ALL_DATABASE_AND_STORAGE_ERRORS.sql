-- ==============================================================================
-- DREAMEATS MASTER FIX: ALL DATABASE, STORAGE & PERMISSIONS ERRORS
-- ==============================================================================
-- Run this single script in your Supabase Dashboard -> SQL Editor -> Run!
-- It resolves:
--  1. "The database still rejects the 'preparing' / 'out_for_delivery' status"
--  2. "Could not find the 'payout_account_name' column of 'businesses' in the schema cache"
--  3. "Storage permission error (403): Row Level Security policy blocked image upload"
--  4. Missing merchant KYC documents table and RLS permissions
--  5. Missing order fulfillment/courier tracking columns
--  6. Missing tables and columns (platform_settings, favorites, reviews, disputes, etc.)
--  7. Stale PostgREST schema cache
-- Safe to re-run anytime (idempotent).
-- ==============================================================================

-- ============================================================
-- 1. EXTEND USER ROLES & RIDER PROFILES
-- ============================================================
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Drop existing role checks on profiles
  FOR r IN (
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.profiles'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) ILIKE '%role%'
  ) LOOP
    EXECUTE 'ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname);
  END LOOP;
END $$;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('customer', 'merchant', 'admin', 'super_admin', 'rider'));

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS vehicle_type TEXT DEFAULT 'Motorbike',
  ADD COLUMN IF NOT EXISTS license_number TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION DEFAULT 5.6037,
  ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION DEFAULT -0.1870,
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS total_deliveries INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE;

-- ============================================================
-- 2. BUSINESS PROFILE: PAYOUT, PHONE & RATINGS COLUMNS
-- ============================================================
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS phone TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_provider TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_account_name TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_account_number TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS opening_time TEXT DEFAULT '08:00',
  ADD COLUMN IF NOT EXISTS closing_time TEXT DEFAULT '22:00';

-- ============================================================
-- 3. ORDERS: STATUS CHECK CONSTRAINT & TRACKING COLUMNS
-- ============================================================
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS fulfillment_type TEXT NOT NULL DEFAULT 'pickup',
  ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS courier_name TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS courier_phone TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS courier_vehicle TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS tracking_notes TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_address TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC(10,2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS delivery_pin TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS delivery_proof_url TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_failure_reason TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_refunded BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS refund_reason TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS payout_status TEXT DEFAULT 'pending';

-- Normalise legacy status values
UPDATE public.orders SET status = 'reserved'
 WHERE status IS NULL OR status NOT IN ('reserved','preparing','ready','out_for_delivery','collected','cancelled','expired');

-- Drop ALL conflicting status constraints on orders
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.orders'::regclass
      AND contype = 'c'
      AND (
        conname = 'orders_status_check'
        OR pg_get_constraintdef(oid) ILIKE '%status%reserved%'
        OR (pg_get_constraintdef(oid) ILIKE '%status%' 
            AND pg_get_constraintdef(oid) NOT ILIKE '%delivery_status%' 
            AND pg_get_constraintdef(oid) NOT ILIKE '%payout_status%'
            AND pg_get_constraintdef(oid) NOT ILIKE '%fulfillment_type%')
      )
  ) LOOP
    EXECUTE 'ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname);
  END LOOP;
END $$;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check CHECK (
    status IN (
      'reserved',
      'preparing',
      'ready',
      'out_for_delivery',
      'collected',
      'cancelled',
      'expired'
    )
  );

DO $$
BEGIN
  ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_fulfillment_type_check;
  ALTER TABLE public.orders ADD CONSTRAINT orders_fulfillment_type_check CHECK (fulfillment_type IN ('pickup', 'delivery'));
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_orders_business_status
  ON public.orders (business_id, status);

CREATE INDEX IF NOT EXISTS idx_orders_courier_status
  ON public.orders (courier_id, delivery_status);

-- ============================================================
-- 4. MERCHANT DOCUMENTS (KYC VERIFICATION)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.merchant_documents (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  doc_type         TEXT        NOT NULL,
  reference_number TEXT        NOT NULL DEFAULT '',
  file_url         TEXT        NOT NULL DEFAULT '',
  status           TEXT        NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'verified', 'rejected')),
  reviewer_note    TEXT,
  uploaded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (business_id, doc_type)
);

ALTER TABLE public.merchant_documents
  ADD COLUMN IF NOT EXISTS reference_number TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS file_url TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'submitted',
  ADD COLUMN IF NOT EXISTS reviewer_note TEXT,
  ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_merchant_documents_business
  ON public.merchant_documents (business_id);

ALTER TABLE public.merchant_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "merchant_docs_select_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_select_owner" ON public.merchant_documents
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "merchant_docs_insert_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_insert_owner" ON public.merchant_documents
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "merchant_docs_update_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_update_owner" ON public.merchant_documents
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "merchant_docs_delete_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_delete_owner" ON public.merchant_documents
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

GRANT ALL ON public.merchant_documents TO authenticated;

-- ============================================================
-- 5. STORAGE BUCKETS & RLS POLICIES (FIXES 403 / 400 ERRORS)
-- ============================================================
-- 5.1 Ensure all public buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('user-avatars', 'user-avatars', true),
  ('uploads', 'uploads', true),
  ('merchant-logos', 'merchant-logos', true),
  ('deal_images', 'deal_images', true),
  ('business_branding', 'business_branding', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 5.2 Drop older restrictive storage policies
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

-- 5.3 Public Read: Anyone can view images from these buckets
CREATE POLICY "Public Read Access for Storage Buckets"
ON storage.objects FOR SELECT
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 5.4 Authenticated Uploads: Any authenticated user can upload
CREATE POLICY "Allow Authenticated Uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 5.5 Authenticated Updates: Any authenticated user can update / overwrite
CREATE POLICY "Allow Authenticated Updates"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'))
WITH CHECK (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- 5.6 Authenticated Deletes: Any authenticated user can delete
CREATE POLICY "Allow Authenticated Deletions"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id IN ('user-avatars', 'uploads', 'merchant-logos', 'deal_images', 'business_branding'));

-- ============================================================
-- 6. SUPPORTING TABLES: FAVORITES, REVIEWS, DISPUTES, TOKENS, SETTINGS
-- ============================================================

-- FAVORITES
CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, business_id)
);
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "favorites_select" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete" ON public.favorites;
CREATE POLICY "favorites_select" ON public.favorites FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "favorites_insert" ON public.favorites FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "favorites_delete" ON public.favorites FOR DELETE TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.favorites TO authenticated;

-- REVIEWS (Contains customer_id to match Flutter app queries)
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID  REFERENCES public.orders(id) ON DELETE CASCADE,
  business_id UUID  REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating      INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS rating INTEGER NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS comment TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reviews_select" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT TO authenticated WITH CHECK (
  customer_id = auth.uid() OR user_id = auth.uid()
);
GRANT ALL ON public.reviews TO authenticated;

-- DISPUTES (Contains customer_id, merchant_id, issue_description, chat_logs)
CREATE TABLE IF NOT EXISTS public.disputes (
  id                UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID      REFERENCES public.orders(id) ON DELETE CASCADE,
  customer_id       UUID      REFERENCES public.profiles(id),
  merchant_id       UUID      REFERENCES public.profiles(id),
  issue_description TEXT      NOT NULL DEFAULT '',
  status            TEXT      DEFAULT 'open',
  chat_logs         JSONB     DEFAULT '[]'::jsonb,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.disputes
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS merchant_id UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS issue_description TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'open',
  ADD COLUMN IF NOT EXISTS chat_logs JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "disputes_select" ON public.disputes;
DROP POLICY IF EXISTS "disputes_insert" ON public.disputes;
DROP POLICY IF EXISTS "disputes_update" ON public.disputes;
CREATE POLICY "disputes_select" ON public.disputes FOR SELECT TO authenticated USING (true);
CREATE POLICY "disputes_insert" ON public.disputes FOR INSERT TO authenticated WITH CHECK (customer_id = auth.uid());
CREATE POLICY "disputes_update" ON public.disputes FOR UPDATE TO authenticated USING (true);
GRANT ALL ON public.disputes TO authenticated;

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT  NOT NULL,
  message     TEXT  NOT NULL,
  is_read     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS title TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS message TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.notifications TO authenticated;

-- DEVICE TOKENS
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID  REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT  NOT NULL,
  platform    TEXT  DEFAULT 'android',
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);
ALTER TABLE public.device_tokens
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS token TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS platform TEXT DEFAULT 'android',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tokens_select" ON public.device_tokens;
DROP POLICY IF EXISTS "tokens_insert" ON public.device_tokens;
CREATE POLICY "tokens_select" ON public.device_tokens FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "tokens_insert" ON public.device_tokens FOR ALL TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.device_tokens TO authenticated;

-- USER PUSH TOKENS
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  user_id     UUID  PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT  NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.user_push_tokens
  ADD COLUMN IF NOT EXISTS token TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_push_tokens_all" ON public.user_push_tokens;
CREATE POLICY "user_push_tokens_all" ON public.user_push_tokens FOR ALL TO authenticated USING (user_id = auth.uid());
GRANT ALL ON public.user_push_tokens TO authenticated;

-- PLATFORM SETTINGS
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id                   INTEGER     PRIMARY KEY DEFAULT 1,
  commission_rate      DECIMAL(5,4) DEFAULT 0.1500,
  min_app_version      TEXT        DEFAULT '1.0.0',
  maintenance_mode     BOOLEAN     DEFAULT FALSE,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);
-- Ensure all columns exist even if table was previously created with fewer columns
ALTER TABLE public.platform_settings
  ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,4) DEFAULT 0.1500,
  ADD COLUMN IF NOT EXISTS min_app_version TEXT DEFAULT '1.0.0',
  ADD COLUMN IF NOT EXISTS maintenance_mode BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "platform_settings_select" ON public.platform_settings;
CREATE POLICY "platform_settings_select" ON public.platform_settings FOR SELECT USING (true);
GRANT ALL ON public.platform_settings TO authenticated;

INSERT INTO public.platform_settings (id, commission_rate, maintenance_mode) 
VALUES (1, 0.1500, false) 
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- ============================================================
-- 7. SECURITY FUNCTIONS & RLS TRIGGERS
-- ============================================================
CREATE OR REPLACE FUNCTION public.auth_is_staff()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

-- Protect order fields without blocking merchants or assigned riders from updating status
CREATE OR REPLACE FUNCTION public.protect_order_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_merchant BOOLEAN;
BEGIN
  IF public.auth_is_staff() OR auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = OLD.business_id AND b.owner_id = auth.uid()
  ) INTO v_is_merchant;

  IF v_is_merchant THEN
    IF NEW.price IS DISTINCT FROM OLD.price OR
       NEW.customer_id IS DISTINCT FROM OLD.customer_id THEN
      RAISE EXCEPTION 'Security Violation: Merchants cannot alter order price or customer.';
    END IF;
    RETURN NEW;
  END IF;

  -- Assigned rider or new claiming rider
  IF (OLD.courier_id IS NOT NULL AND OLD.courier_id = auth.uid()) OR
     (OLD.courier_id IS NULL AND NEW.courier_id = auth.uid()) THEN
    RETURN NEW;
  END IF;

  IF OLD.customer_id = auth.uid() THEN
    IF NEW.price IS DISTINCT FROM OLD.price OR
       NEW.business_id IS DISTINCT FROM OLD.business_id OR
       NEW.deal_id IS DISTINCT FROM OLD.deal_id THEN
      RAISE EXCEPTION 'Security Violation: Order details cannot be modified after placement.';
    END IF;

    IF NEW.collection_code IS DISTINCT FROM OLD.collection_code OR
       NEW.payout_status IS DISTINCT FROM OLD.payout_status THEN
      RAISE EXCEPTION 'Security Violation: Unauthorized modification of order verification code or payout status.';
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
      IF NOT (OLD.status = 'reserved' AND NEW.status = 'cancelled') THEN
        RAISE EXCEPTION 'Security Violation: Customers can only cancel reserved orders.';
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Unauthorized: You do not have permission to modify this order.';
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_order_fields ON public.orders;
CREATE TRIGGER trg_protect_order_fields
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.protect_order_fields();

-- Update orders RLS policy to ensure merchants & riders can update
DROP POLICY IF EXISTS "orders_update" ON public.orders;
CREATE POLICY "orders_update" ON public.orders
  FOR UPDATE TO authenticated
  USING (
    customer_id = auth.uid()
    OR public.auth_is_staff()
    OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = orders.business_id AND b.owner_id = auth.uid())
    OR courier_id = auth.uid()
    OR (fulfillment_type = 'delivery' AND courier_id IS NULL)
  );

-- Update businesses RLS policy so owners can update their business
DROP POLICY IF EXISTS "businesses_update" ON public.businesses;
CREATE POLICY "businesses_update" ON public.businesses
  FOR UPDATE TO authenticated
  USING (owner_id = auth.uid() OR public.auth_is_staff())
  WITH CHECK (owner_id = auth.uid() OR public.auth_is_staff());

-- Staff toggle suspension RPC
CREATE OR REPLACE FUNCTION public.admin_toggle_user_suspension(target_user_id UUID, should_suspend BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: staff privileges required';
  END IF;

  UPDATE public.profiles
  SET is_suspended = should_suspend
  WHERE id = target_user_id;

  RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_toggle_user_suspension(UUID, BOOLEAN) TO authenticated;

-- ============================================================
-- 8. RELOAD POSTGREST SCHEMA CACHE
-- ============================================================
NOTIFY pgrst, 'reload schema';

-- Done! DreamEats database & storage are fully synchronized.
