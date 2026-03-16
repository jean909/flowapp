-- ==========================================
-- EMAIL CONFIRMATION: DEACTIVATE IF NOT CONFIRMED IN X DAYS
-- ==========================================
-- Run this in Supabase SQL Editor.
-- Allows sign-up without blocking on email confirm; after N days unconfirmed, account is "deactivated".
-- In Supabase Dashboard: Authentication → Providers → Email → turn OFF "Confirm email" if you want instant access.

-- 1. Add column on profiles to mark deactivation (until user confirms email)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ NULL;

COMMENT ON COLUMN public.profiles.deactivated_at IS 'Set when user did not confirm email within grace period; cleared when they confirm.';

-- 2. Function: deactivate users who have not confirmed email within N days
-- Run this daily via pg_cron or Supabase Edge Function + cron trigger
CREATE OR REPLACE FUNCTION public.deactivate_unconfirmed_users(grace_days INTEGER DEFAULT 7)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected INTEGER;
BEGIN
  UPDATE public.profiles p
  SET deactivated_at = NOW()
  FROM auth.users u
  WHERE p.id = u.id
    AND u.email_confirmed_at IS NULL
    AND u.created_at < (NOW() - (grace_days || ' days')::INTERVAL)
    AND (p.deactivated_at IS NULL OR p.deactivated_at < NOW() - INTERVAL '1 day');
  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;

-- 3. Function: clear deactivated_at when user has confirmed email (call from app after login if needed)
CREATE OR REPLACE FUNCTION public.clear_deactivated_if_confirmed(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET deactivated_at = NULL
  WHERE id = p_user_id
    AND EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = p_user_id AND u.email_confirmed_at IS NOT NULL
    );
END;
$$;

-- 4. Grant execute to authenticated (so app can call clear_deactivated_if_confirmed)
GRANT EXECUTE ON FUNCTION public.clear_deactivated_if_confirmed(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.deactivate_unconfirmed_users(INTEGER) TO service_role;

-- ==========================================
-- HOW TO RUN THE DAILY JOB
-- ==========================================
-- Option A – pg_cron (if enabled on your Supabase project):
--   SELECT cron.schedule('deactivate-unconfirmed', '0 3 * * *', 'SELECT public.deactivate_unconfirmed_users(7)');
--
-- Option B – Supabase Edge Function on cron:
--   Create an Edge Function that calls the Supabase client (service_role) to run SQL:
--   supabase.rpc('deactivate_unconfirmed_users', { grace_days: 7 })
--   Schedule it in Dashboard → Edge Functions → your function → Cron (e.g. 0 3 * * * = 3 AM daily).
--
-- Option C – Run manually when you want:
--   SELECT public.deactivate_unconfirmed_users(7);
