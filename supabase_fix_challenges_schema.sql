-- FIX FOR CHALLENGES TABLE MISSING created_at COLUMN
-- RUN THIS IN SUPABASE SQL EDITOR

-- 1. Ensure created_at column exists in challenges table
ALTER TABLE IF EXISTS public.challenges 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

-- 2. Ensure created_at column exists in user_challenges table (for consistency)
ALTER TABLE IF EXISTS public.user_challenges 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

-- 3. Verify RLS policies are correct
DROP POLICY IF EXISTS "Allow public read access to challenges" ON public.challenges;
CREATE POLICY "Allow public read access to challenges" ON public.challenges FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own challenge enrollments" ON public.user_challenges;
CREATE POLICY "Users can manage own challenge enrollments" ON public.user_challenges FOR ALL USING (auth.uid() = user_id);
