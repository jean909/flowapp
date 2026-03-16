-- COMPREHENSIVE FIX FOR COMMENTS FOREIGN KEY
-- Run this in Supabase SQL Editor

-- Step 1: Check if foreign key already exists and drop it if needed
DO $$ 
BEGIN
    -- Drop existing constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'social_comments_user_id_fkey' 
        AND table_name = 'social_comments'
    ) THEN
        ALTER TABLE public.social_comments DROP CONSTRAINT social_comments_user_id_fkey;
    END IF;
END $$;

-- Step 2: Ensure profiles table exists and has proper structure
-- (This should already exist, but just in case)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Step 3: Add the foreign key constraint
ALTER TABLE public.social_comments
ADD CONSTRAINT social_comments_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- Step 4: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_social_comments_user_id ON public.social_comments(user_id);

-- Step 5: Reload the schema cache
NOTIFY pgrst, 'reload schema';

-- Step 6: Verify the relationship exists
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='social_comments'
    AND kcu.column_name = 'user_id';
