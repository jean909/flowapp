-- USERNAME SETUP SCHEMA
-- Run this in Supabase SQL Editor

-- Ensure username column exists with proper constraints
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS username TEXT;

-- Make username unique
ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_username_key;

ALTER TABLE public.profiles
ADD CONSTRAINT profiles_username_key UNIQUE (username);

-- Add username format constraint (lowercase, alphanumeric + underscore, 3-30 chars)
ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS username_format;

ALTER TABLE public.profiles
ADD CONSTRAINT username_format 
CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,30}$');

-- Create index for fast username lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username 
ON public.profiles(username);

-- Ensure bio column exists
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- Update RLS policies to allow username updates
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles' 
AND column_name IN ('username', 'bio', 'full_name', 'avatar_url');
