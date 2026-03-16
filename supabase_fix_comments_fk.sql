-- Fix Comments Foreign Key Relationship
-- Run this in Supabase SQL Editor

-- The issue is that social_comments doesn't have a proper foreign key to profiles
-- We need to add it explicitly

-- First, check if the foreign key exists
-- If not, add it:

ALTER TABLE public.social_comments
ADD CONSTRAINT social_comments_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- Also ensure the profiles table references auth.users correctly
-- (This should already exist, but just in case)

ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_id_fkey;

ALTER TABLE public.profiles
ADD CONSTRAINT profiles_id_fkey 
FOREIGN KEY (id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- Refresh the schema cache
NOTIFY pgrst, 'reload schema';
