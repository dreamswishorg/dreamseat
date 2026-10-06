-- ============================================================
-- SQL SCRIPT: Fix Payout Status Column & Reload PostgREST Cache
-- Run this in your Supabase Dashboard SQL Editor:
-- https://supabase.com/dashboard/project/trhefcuuhwavbdqhgamr/sql
-- ============================================================

-- 1. Add the payout_status column safely if it is missing
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS payout_status TEXT DEFAULT 'pending' CHECK (payout_status IN ('pending', 'processing', 'paid'));

-- 2. Force PostgREST to reload the schema cache so the Rest API recognizes the column
NOTIFY pgrst, 'reload schema';
