-- Supabase RPC Function to securely delete user accounts from both public profiles and auth users schema.
-- This function must run with SECURITY DEFINER to bypass client RLS restrictions on auth schemas.
-- It strictly verifies auth.uid() to ensure users can only delete their own account.

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS BOOLEAN AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- 1. Delete associated profile (this triggers ON DELETE CASCADE foreign key purges on ledger/favorites/etc)
  DELETE FROM public.profiles WHERE id = current_user_id;

  -- 2. Delete user account from the auth.users table
  DELETE FROM auth.users WHERE id = current_user_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
