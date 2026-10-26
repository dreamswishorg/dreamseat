-- ============================================================
-- FIX: merchant cannot update order status + tracking data lost
-- ============================================================

-- 1. Fulfillment + tracking columns
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
  ADD COLUMN IF NOT EXISTS refund_reason TEXT DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_orders_business_status
  ON public.orders (business_id, status);

-- 2. Normalise any legacy status values so the new CHECK can be added
UPDATE public.orders SET status = 'reserved'
 WHERE status IS NULL OR status NOT IN ('reserved','preparing','ready','out_for_delivery','collected','cancelled','expired');

-- 3. Drop ALL existing status check constraints dynamically
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT conname
    FROM pg_constraint
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

-- 4. Add the widened status CHECK constraint
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

-- 5. Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
