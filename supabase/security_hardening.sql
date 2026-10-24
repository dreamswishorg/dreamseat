-- ==============================================================================
-- DREAMEATS DATABASE SECURITY HARDENING MIGRATION
-- Run this script in your Supabase Dashboard SQL Editor to enforce:
-- 1. Anti-Field Tampering & Privilege Escalation Prevention (Profiles)
-- 2. Merchant Approval Bypass Prevention (Businesses)
-- 3. Payment & Order Status Tampering Prevention (Orders)
-- 4. Database Input Validation Constraints (CHECK constraints)
-- ==============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PREVENT PROFILE FIELD TAMPERING & SELF-PRIVILEGE ESCALATION
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.protect_profile_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If not admin/super_admin or service_role, restrict sensitive fields
  IF NOT (public.auth_is_staff() OR auth.role() = 'service_role') THEN
    -- Prevent privilege escalation (changing role to admin, super_admin, etc.)
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Security Violation: Users cannot alter their own account role.';
    END IF;

    -- Prevent self-unsuspension
    IF NEW.is_suspended IS DISTINCT FROM OLD.is_suspended THEN
      RAISE EXCEPTION 'Security Violation: Users cannot alter their suspension status.';
    END IF;

    -- Prevent dream_points manipulation from client
    IF NEW.dream_points IS DISTINCT FROM OLD.dream_points THEN
      RAISE EXCEPTION 'Security Violation: Dream points can only be modified by system functions.';
    END IF;

    -- Prevent referral_credit manipulation from client
    IF NEW.referral_credit IS DISTINCT FROM OLD.referral_credit THEN
      RAISE EXCEPTION 'Security Violation: Referral credit can only be modified by system functions.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_fields ON public.profiles;
CREATE TRIGGER trg_protect_profile_fields
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_fields();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PREVENT BUSINESS APPROVAL TAMPERING (MERCHANTS CANNOT SELF-APPROVE)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.protect_business_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If not staff or service_role, prevent merchant from altering approval status or rating
  IF NOT (public.auth_is_staff() OR auth.role() = 'service_role') THEN
    IF NEW.is_approved IS DISTINCT FROM OLD.is_approved THEN
      RAISE EXCEPTION 'Security Violation: Only staff can approve or reject businesses.';
    END IF;

    IF NEW.rating IS DISTINCT FROM OLD.rating THEN
      RAISE EXCEPTION 'Security Violation: Business ratings are calculated from verified reviews.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_business_fields ON public.businesses;
CREATE TRIGGER trg_protect_business_fields
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_business_fields();

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. PREVENT ORDER TAMPERING (CUSTOMERS CANNOT FAKE PRICING OR FORCE COMPLETIONS)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.protect_order_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_merchant BOOLEAN;
BEGIN
  -- Staff and service_role have full authority
  IF public.auth_is_staff() OR auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Check if caller is the merchant owner
  SELECT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = OLD.business_id AND b.owner_id = auth.uid()
  ) INTO v_is_merchant;

  IF v_is_merchant THEN
    -- Merchant cannot modify pricing, customer_id, or collection code
    IF NEW.price IS DISTINCT FROM OLD.price OR
       NEW.customer_id IS DISTINCT FROM OLD.customer_id THEN
      RAISE EXCEPTION 'Security Violation: Merchants cannot alter order price or customer.';
    END IF;
    RETURN NEW;
  END IF;

  -- Caller is the customer (or third-party)
  IF OLD.customer_id = auth.uid() THEN
    -- Customers CANNOT alter price, deal, or business
    IF NEW.price IS DISTINCT FROM OLD.price OR
       NEW.business_id IS DISTINCT FROM OLD.business_id OR
       NEW.deal_id IS DISTINCT FROM OLD.deal_id THEN
      RAISE EXCEPTION 'Security Violation: Order details cannot be modified after placement.';
    END IF;

    -- Customers CANNOT alter collection_code or payout_status
    IF NEW.collection_code IS DISTINCT FROM OLD.collection_code OR
       NEW.payout_status IS DISTINCT FROM OLD.payout_status THEN
      RAISE EXCEPTION 'Security Violation: Unauthorized modification of order verification code or payout status.';
    END IF;

    -- Customers can only cancel a reserved order
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
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_order_fields();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. DATABASE INPUT VALIDATION (CHECK CONSTRAINTS)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  -- Check food deals prices and quantities (using exact column: discounted_price)
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_deal_positive_values') THEN
    ALTER TABLE public.food_deals ADD CONSTRAINT check_deal_positive_values 
      CHECK (discounted_price >= 0 AND original_price >= 0 AND quantity_total >= 0 AND quantity_remaining >= 0);
  END IF;

  -- Check order price (using exact column: price)
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_order_positive_price') THEN
    ALTER TABLE public.orders ADD CONSTRAINT check_order_positive_price 
      CHECK (price >= 0);
  END IF;

  -- Check profile balances
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_profile_positive_credits') THEN
    ALTER TABLE public.profiles ADD CONSTRAINT check_profile_positive_credits 
      CHECK (dream_points >= 0 AND referral_credit >= 0);
  END IF;

  -- Check valid geographic coordinates
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_business_valid_coordinates') THEN
    ALTER TABLE public.businesses ADD CONSTRAINT check_business_valid_coordinates 
      CHECK ((lat IS NULL OR lat BETWEEN -90 AND 90) AND (lng IS NULL OR lng BETWEEN -180 AND 180));
  END IF;

  -- Check valid review rating
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_review_valid_rating') THEN
    ALTER TABLE public.reviews ADD CONSTRAINT check_review_valid_rating 
      CHECK (rating >= 1 AND rating <= 5);
  END IF;
END $$;
