-- ==============================================================================
-- FIX & ENSURE AUDIT LOGS TABLE FOR ALL ROLES (ADMIN, MERCHANT, CUSTOMER, SYSTEM)
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Create or alter audit_logs table to allow all actors without foreign-key lock
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      TEXT,
  actor_name    TEXT NOT NULL,
  actor_role    TEXT NOT NULL,
  action        TEXT NOT NULL,
  entity_type   TEXT NOT NULL,
  entity_id     TEXT,
  description   TEXT NOT NULL,
  metadata      JSONB DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- If table already existed with UUID actor_id FK constraint, relax it to avoid FK errors on system actions
DO $$
BEGIN
  ALTER TABLE public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_actor_id_fkey;
  ALTER TABLE public.audit_logs ALTER COLUMN actor_id TYPE TEXT;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- 2. Enable Row Level Security & Allow authenticated read/write
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_logs_read_all" ON public.audit_logs;
CREATE POLICY "audit_logs_read_all" ON public.audit_logs
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "audit_logs_insert_all" ON public.audit_logs;
CREATE POLICY "audit_logs_insert_all" ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- 3. Populate initial audit logs from existing real platform entities if empty
INSERT INTO public.audit_logs (id, actor_id, actor_name, actor_role, action, entity_type, entity_id, description, metadata, created_at)
SELECT 
  gen_random_uuid(),
  p.id::text,
  COALESCE(p.name, p.email, 'User'),
  p.role,
  'USER_REGISTERED',
  'user',
  SUBSTRING(p.id::text FROM 1 FOR 8),
  format('User %s (%s) joined the platform with role %s', COALESCE(p.name, 'Account'), p.email, UPPER(p.role)),
  jsonb_build_object('email', p.email, 'role', p.role),
  p.created_at
FROM public.profiles p
WHERE NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'USER_REGISTERED' AND entity_id = SUBSTRING(p.id::text FROM 1 FOR 8))
LIMIT 20;

INSERT INTO public.audit_logs (id, actor_id, actor_name, actor_role, action, entity_type, entity_id, description, metadata, created_at)
SELECT 
  gen_random_uuid(),
  b.owner_id::text,
  b.name,
  'merchant',
  'MERCHANT_REGISTER',
  'merchant',
  SUBSTRING(b.id::text FROM 1 FOR 8),
  format('Merchant "%s" registered in category %s at %s', b.name, b.category, b.location),
  jsonb_build_object('business_id', b.id, 'category', b.category),
  b.created_at
FROM public.businesses b
WHERE NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'MERCHANT_REGISTER' AND entity_id = SUBSTRING(b.id::text FROM 1 FOR 8))
LIMIT 20;

INSERT INTO public.audit_logs (id, actor_id, actor_name, actor_role, action, entity_type, entity_id, description, metadata, created_at)
SELECT 
  gen_random_uuid(),
  o.customer_id::text,
  o.customer_name,
  'customer',
  'ORDER_PLACED',
  'order',
  SUBSTRING(o.id::text FROM 1 FOR 8),
  format('Customer %s placed meal rescue order for %s (GHS %s)', o.customer_name, o.business_name, o.total_amount::text),
  jsonb_build_object('order_id', o.id, 'status', o.status, 'total', o.total_amount),
  o.created_at
FROM public.orders o
WHERE NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'ORDER_PLACED' AND entity_id = SUBSTRING(o.id::text FROM 1 FOR 8))
LIMIT 30;

-- 4. Verify count of logs
SELECT 
  actor_role,
  action,
  COUNT(*) as log_count
FROM public.audit_logs
GROUP BY actor_role, action
ORDER BY actor_role;
