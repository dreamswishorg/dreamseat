-- Add device_tokens table for FCM push notification targeting
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS device_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  fcm_token   TEXT        NOT NULL,
  platform    TEXT        DEFAULT 'mobile' CHECK (platform IN ('android', 'ios', 'web', 'mobile')),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id)  -- one token per user (last device wins)
);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY "device_tokens_own" ON device_tokens
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admins/Edge Functions can read all tokens for broadcasts
CREATE POLICY "device_tokens_read_admin" ON device_tokens
  FOR SELECT TO authenticated
  USING (auth_user_role() = 'admin');

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);

-- Function to get FCM token for a given user (used by Edge Functions)
CREATE OR REPLACE FUNCTION get_user_fcm_token(target_user_id UUID)
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT fcm_token FROM device_tokens WHERE user_id = target_user_id
$$;
