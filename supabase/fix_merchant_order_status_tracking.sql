-- ============================================================
-- FIX: merchant cannot update order status + tracking data lost
-- ============================================================
-- Cause 1: orders.status had CHECK (status IN ('reserved','collected',
--          'cancelled','expired')) but the app uses 'preparing', 'ready'
--          and 'out_for_delivery' too, so those UPDATEs were rejected
--          with SQLSTATE 23514.
-- Cause 2: the fulfillment/tracking columns the app writes
--          (fulfillment_type, courier_name, courier_phone,
--          tracking_notes, delivery_address) do not exist, so courier
--          details were silently dropped on every save.
--
-- Apply with:  supabase db push        (or paste into the SQL editor)
-- Safe to re-run.

-- 1. Fulfillment + tracking columns ---------------------------------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS fulfillment_type TEXT NOT NULL DEFAULT 'pickup'
    CHECK (fulfillment_type IN ('pickup', 'delivery')),
  ADD COLUMN IF NOT EXISTS courier_name     TEXT,
  ADD COLUMN IF NOT EXISTS courier_phone    TEXT,
  ADD COLUMN IF NOT EXISTS tracking_notes   TEXT,
  ADD COLUMN IF NOT EXISTS delivery_address TEXT;

CREATE INDEX IF NOT EXISTS idx_orders_business_status
  ON public.orders (business_id, status);

-- 2. Normalise any legacy status values so the new CHECK can be added ---
UPDATE public.orders SET status = 'reserved'
 WHERE status NOT IN ('reserved','preparing','ready','out_for_delivery','collected','cancelled','expired');

-- 3. Widen the status CHECK constraint ------------------------------
DO $$
DECLARE
  existing TEXT;
BEGIN
  SELECT conname INTO existing
  FROM pg_constraint
  WHERE conrelid = 'public.orders'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) ILIKE '%status%'
    AND conname <> 'orders_fulfillment_type_check'
    AND conname NOT LIKE 'orders_payout_status%'
  LIMIT 1;

  IF existing IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.orders DROP CONSTRAINT %I', existing);
  END IF;
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
