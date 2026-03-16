-- Fix relationship between social_stories and profiles to allow joining
-- Run this in your Supabase SQL Editor

-- 1. Identify and drop the existing constraint if it exists (usually named after the table and column)
ALTER TABLE public.social_stories
DROP CONSTRAINT IF EXISTS social_stories_user_id_fkey;

-- 2. Add the new constraint pointing to the profiles table
-- This allows Postgrest to understand how to join stories with profile data
ALTER TABLE public.social_stories
ADD CONSTRAINT social_stories_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. (Optional) Ensure RLS is still correct
-- The policies usually use auth.uid() so they should be unchanged, 
-- but it's good practice to verify.
