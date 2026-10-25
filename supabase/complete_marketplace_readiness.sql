-- ==============================================================================
-- DREAMEATS MARKETPLACE COMPLETENESS & RIDER FLEET SCHEMA MIGRATION
-- Run this in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Extend user roles to include 'rider'
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('customer', 'merchant', 'admin', 'super_admin', 'rider'));

-- 2. Add Rider & Dispatch fields to public.profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS vehicle_type TEXT DEFAULT 'Motorbike',
  ADD COLUMN IF NOT EXISTS license_number TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION DEFAULT 5.6037,
  ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION DEFAULT -0.1870,
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS total_deliveries INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE;

-- 3. Add Delivery & Courier fields to public.orders
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS fulfillment_type TEXT DEFAULT 'pickup',
  ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS courier_name TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS courier_phone TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS courier_vehicle TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_address TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION DEFAULT 5.6037,
  ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION DEFAULT -0.1870,
  ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC(10,2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS delivery_pin TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS delivery_proof_url TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS delivery_failure_reason TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_refunded BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS refund_reason TEXT DEFAULT '';

-- 4. Secure Deals: Enforce that pending or suspended vendors CANNOT publish or modify deals
DROP POLICY IF EXISTS "deals_insert" ON public.food_deals;
CREATE POLICY "deals_insert" ON public.food_deals
  FOR INSERT TO authenticated
  WITH CHECK (
    (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id
          AND b.owner_id = auth.uid()
          AND b.is_approved = TRUE
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.is_suspended = TRUE
      )
    )
    OR public.auth_is_staff()
  );

DROP POLICY IF EXISTS "deals_update" ON public.food_deals;
CREATE POLICY "deals_update" ON public.food_deals
  FOR UPDATE TO authenticated
  USING (
    public.auth_is_staff()
    OR (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = food_deals.business_id
          AND b.owner_id = auth.uid()
          AND b.is_approved = TRUE
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.is_suspended = TRUE
      )
    )
  );

-- 5. Policies for Riders to view and update orders
DROP POLICY IF EXISTS "orders_rider_select" ON public.orders;
CREATE POLICY "orders_rider_select" ON public.orders
  FOR SELECT TO authenticated
  USING (
    courier_id = auth.uid()
    OR (
      fulfillment_type = 'delivery'
      AND courier_id IS NULL
      AND status IN ('reserved', 'preparing', 'ready')
      AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'rider' AND is_approved = TRUE)
    )
    OR public.auth_is_staff()
    OR customer_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = orders.business_id AND b.owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "orders_rider_update" ON public.orders;
CREATE POLICY "orders_rider_update" ON public.orders
  FOR UPDATE TO authenticated
  USING (
    courier_id = auth.uid()
    OR (
      fulfillment_type = 'delivery'
      AND courier_id IS NULL
      AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'rider' AND is_approved = TRUE)
    )
    OR public.auth_is_staff()
  )
  WITH CHECK (
    courier_id = auth.uid()
    OR public.auth_is_staff()
  );

-- 6. RPC: Rider accept delivery
CREATE OR REPLACE FUNCTION public.rider_accept_delivery(p_order_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rider public.profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_rider FROM public.profiles WHERE id = auth.uid();
  IF v_rider.role != 'rider' OR v_rider.is_approved = FALSE THEN
    RAISE EXCEPTION 'Only verified riders can accept deliveries';
  END IF;

  UPDATE public.orders
  SET courier_id = v_rider.id,
      courier_name = v_rider.name,
      courier_phone = COALESCE(v_rider.phone, ''),
      courier_vehicle = COALESCE(v_rider.vehicle_type, 'Motorbike'),
      delivery_status = 'assigned'
  WHERE id = p_order_id
    AND courier_id IS NULL
    AND fulfillment_type = 'delivery';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order is already assigned or not available for delivery.';
  END IF;

  RETURN TRUE;
END;
$$;

-- 7. RPC: Rider update delivery status (picked up, in transit, delivered, failed)
CREATE OR REPLACE FUNCTION public.rider_update_delivery_status(
  p_order_id UUID,
  p_status TEXT,
  p_pin TEXT DEFAULT '',
  p_proof_url TEXT DEFAULT '',
  p_reason TEXT DEFAULT ''
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND courier_id = auth.uid();
  IF NOT FOUND AND NOT public.auth_is_staff() THEN
    RAISE EXCEPTION 'Unauthorized: order not assigned to you';
  END IF;

  IF p_status = 'delivered' THEN
    -- If order has a delivery PIN, check it
    IF v_order.delivery_pin IS NOT NULL AND v_order.delivery_pin != '' AND p_pin != '' THEN
      IF v_order.delivery_pin != p_pin THEN
        RAISE EXCEPTION 'Invalid customer delivery PIN';
      END IF;
    END IF;

    UPDATE public.orders
    SET status = 'collected',
        delivery_status = 'delivered',
        delivery_proof_url = p_proof_url
    WHERE id = p_order_id;

    -- Increment rider completed trip count
    UPDATE public.profiles
    SET total_deliveries = total_deliveries + 1
    WHERE id = auth.uid();

  ELSIF p_status = 'failed' THEN
    UPDATE public.orders
    SET status = 'cancelled',
        delivery_status = 'failed',
        delivery_failure_reason = p_reason
    WHERE id = p_order_id;

  ELSE
    UPDATE public.orders
    SET delivery_status = p_status
    WHERE id = p_order_id;
  END IF;

  RETURN TRUE;
END;
$$;

-- 8. RPC: Admin assign/reassign rider to delivery
CREATE OR REPLACE FUNCTION public.admin_assign_rider(
  p_order_id UUID,
  p_rider_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rider public.profiles%ROWTYPE;
BEGIN
  IF NOT public.auth_is_staff() THEN
    RAISE EXCEPTION 'Unauthorized: Staff privilege required';
  END IF;

  SELECT * INTO v_rider FROM public.profiles WHERE id = p_rider_id AND role = 'rider';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Rider profile not found';
  END IF;

  UPDATE public.orders
  SET courier_id = v_rider.id,
      courier_name = v_rider.name,
      courier_phone = COALESCE(v_rider.phone, ''),
      courier_vehicle = COALESCE(v_rider.vehicle_type, 'Motorbike'),
      delivery_status = 'assigned'
  WHERE id = p_order_id;

  RETURN TRUE;
END;
$$;

-- 9. RPC: Admin update user role (promote/change roles directly)
CREATE OR REPLACE FUNCTION public.admin_update_user_role(
  p_target_user_id UUID,
  p_new_role TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.auth_is_staff() THEN
    RAISE EXCEPTION 'Unauthorized: Staff privilege required';
  END IF;

  IF p_new_role NOT IN ('customer', 'merchant', 'admin', 'super_admin', 'rider') THEN
    RAISE EXCEPTION 'Invalid role specified';
  END IF;

  UPDATE public.profiles
  SET role = p_new_role
  WHERE id = p_target_user_id;

  RETURN TRUE;
END;
$$;

-- 10. RPC: Admin approve / reject rider
CREATE OR REPLACE FUNCTION public.admin_approve_rider(
  p_rider_id UUID,
  p_is_approved BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.auth_is_staff() THEN
    RAISE EXCEPTION 'Unauthorized: Staff privilege required';
  END IF;

  UPDATE public.profiles
  SET is_approved = p_is_approved
  WHERE id = p_rider_id AND role = 'rider';

  RETURN TRUE;
END;
$$;

-- 11. RPC: Admin process order refund
CREATE OR REPLACE FUNCTION public.admin_process_order_refund(
  p_order_id UUID,
  p_reason TEXT DEFAULT 'Customer Refund Approved'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.auth_is_staff() THEN
    RAISE EXCEPTION 'Unauthorized: Staff privilege required';
  END IF;

  UPDATE public.orders
  SET is_refunded = TRUE,
      refund_reason = p_reason,
      status = 'cancelled'
  WHERE id = p_order_id;

  RETURN TRUE;
END;
$$;

-- 12. RPC: Rider update online status & location
CREATE OR REPLACE FUNCTION public.rider_update_location(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_is_online BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET current_lat = p_lat,
      current_lng = p_lng,
      is_online = p_is_online
  WHERE id = auth.uid() AND role = 'rider';

  RETURN TRUE;
END;
$$;

-- 13. Tamper-Proof Delivery Quotes Table (Server-validated pricing)
CREATE TABLE IF NOT EXISTS public.delivery_quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  pickup_address TEXT NOT NULL,
  dropoff_address TEXT NOT NULL,
  pickup_lat DOUBLE PRECISION,
  pickup_lng DOUBLE PRECISION,
  dropoff_lat DOUBLE PRECISION,
  dropoff_lng DOUBLE PRECISION,
  distance_km NUMERIC(6,2) NOT NULL,
  duration_mins INTEGER NOT NULL DEFAULT 15,
  delivery_fee NUMERIC(10,2) NOT NULL,
  currency TEXT DEFAULT 'GHS',
  expires_at TIMESTAMPTZ NOT NULL,
  is_consumed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.delivery_quotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "delivery_quotes_customer_select" ON public.delivery_quotes;
CREATE POLICY "delivery_quotes_customer_select" ON public.delivery_quotes
  FOR SELECT TO authenticated
  USING (customer_id = auth.uid() OR public.auth_is_staff());

DROP POLICY IF EXISTS "delivery_quotes_customer_insert" ON public.delivery_quotes;
CREATE POLICY "delivery_quotes_customer_insert" ON public.delivery_quotes
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = auth.uid());

-- 14. Expand Order Status Separation:
-- payment_status: 'pending', 'paid', 'refunded', 'failed'
-- food_status: 'reserved', 'preparing', 'ready_for_pickup', 'completed', 'cancelled'
-- delivery_status: 'none', 'quote_locked', 'dispatch_pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed'
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS food_status TEXT DEFAULT 'reserved',
  ADD COLUMN IF NOT EXISTS quote_id UUID REFERENCES public.delivery_quotes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS dispatch_job_id TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS dispatch_retry_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS dispatch_last_error TEXT DEFAULT '';

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
