-- ============================================================
-- Real reward vouchers, server-side promo validation, and a
-- security fix for point redemption.
--
-- Run once in the Supabase SQL editor. The app detects whether these
-- functions exist and falls back safely (points deducted + a support
-- ticket for the team) until they are applied.
-- ============================================================

-- 1. Vouchers can belong to one customer and record where they came from.
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS source   TEXT DEFAULT 'admin';

-- Customers may read their own vouchers (admins keep full access via existing policies).
DROP POLICY IF EXISTS "vouchers_owner_select" ON public.vouchers;
CREATE POLICY "vouchers_owner_select" ON public.vouchers
  FOR SELECT TO authenticated USING (owner_id = auth.uid());

-- 2. SECURITY FIX: redeem_dream_points trusted a caller-supplied user_id, so any
--    signed-in user could spend another customer's points. It now only ever acts
--    on the calling user. (Same signature, so existing clients keep working.)
CREATE OR REPLACE FUNCTION public.redeem_dream_points(user_id UUID, points_to_deduct INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_pts INT;
BEGIN
  IF auth.uid() IS NULL OR user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'NOT_ALLOWED';
  END IF;
  IF points_to_deduct <= 0 THEN
    RETURN FALSE;
  END IF;
  SELECT COALESCE(dream_points, 0) INTO current_pts
    FROM public.profiles WHERE id = user_id FOR UPDATE;
  IF current_pts < points_to_deduct THEN
    RETURN FALSE;
  END IF;
  UPDATE public.profiles SET dream_points = current_pts - points_to_deduct WHERE id = user_id;
  RETURN TRUE;
END;
$$;

-- 3. Redeem points for a single-use, 30-day voucher owned by the caller.
--    Returns the new voucher code. Raises INSUFFICIENT_POINTS when short.
CREATE OR REPLACE FUNCTION public.redeem_reward(points_cost INT, reward_name TEXT, discount NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
  current_pts INT;
  new_code TEXT;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'NOT_ALLOWED'; END IF;
  IF points_cost <= 0 OR discount <= 0 THEN RAISE EXCEPTION 'INVALID_REWARD'; END IF;

  SELECT COALESCE(dream_points, 0) INTO current_pts
    FROM public.profiles WHERE id = uid FOR UPDATE;
  IF current_pts < points_cost THEN RAISE EXCEPTION 'INSUFFICIENT_POINTS'; END IF;

  UPDATE public.profiles SET dream_points = current_pts - points_cost WHERE id = uid;

  LOOP
    new_code := 'DE-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.vouchers WHERE code = new_code);
  END LOOP;

  INSERT INTO public.vouchers
    (code, discount_amount, discount_type, expires_at, usage_limit, usage_count, is_active, funded_by, owner_id, source)
  VALUES
    (new_code, discount, 'fixed', NOW() + INTERVAL '30 days', 1, 0, TRUE, 'platform', uid, 'reward: ' || reward_name);

  RETURN new_code;
END;
$$;

-- 4. Validate a promo/voucher code for the caller. Returns no row when the code is
--    unknown, inactive, expired, used up, or owned by someone else.
CREATE OR REPLACE FUNCTION public.validate_voucher(voucher_code TEXT)
RETURNS TABLE (discount_amount NUMERIC, discount_type TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT v.discount_amount, v.discount_type
  FROM public.vouchers v
  WHERE upper(v.code) = upper(trim(voucher_code))
    AND v.is_active
    AND (v.expires_at IS NULL OR v.expires_at > NOW())
    AND v.usage_count < v.usage_limit
    AND (v.owner_id IS NULL OR v.owner_id = auth.uid())
  LIMIT 1;
$$;

-- 5. Record one use after a successful payment (atomic; no-op when already used up).
CREATE OR REPLACE FUNCTION public.consume_voucher(voucher_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE n INT;
BEGIN
  UPDATE public.vouchers v
     SET usage_count = v.usage_count + 1,
         is_active   = (v.usage_count + 1) < v.usage_limit
   WHERE upper(v.code) = upper(trim(voucher_code))
     AND v.is_active
     AND v.usage_count < v.usage_limit
     AND (v.owner_id IS NULL OR v.owner_id = auth.uid());
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.redeem_reward(INT, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_voucher(TEXT)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.consume_voucher(TEXT)             TO authenticated;
