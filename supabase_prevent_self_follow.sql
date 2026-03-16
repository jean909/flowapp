-- PREVENT SELF-FOLLOW
-- Run this in Supabase SQL Editor

ALTER TABLE public.social_follows
DROP CONSTRAINT IF EXISTS no_self_follow;

ALTER TABLE public.social_follows
ADD CONSTRAINT no_self_follow 
CHECK (follower_id <> following_id);
