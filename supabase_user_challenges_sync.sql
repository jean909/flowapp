-- ============================================
-- SYNC USER_CHALLENGES WITH EXISTING CHALLENGES
-- ============================================

-- Use the existing challenges table structure provided by user
-- The primary key in the user's data seems to be 'id' (BIGINT/INT)

CREATE TABLE IF NOT EXISTS public.user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'STARTED', -- 'STARTED', 'COMPLETED', 'FAILED'
    current_progress INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, challenge_id)
);

-- Enable RLS
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can manage own challenge enrollments" ON public.user_challenges;
CREATE POLICY "Users can manage own challenge enrollments" ON public.user_challenges FOR ALL USING (auth.uid() = user_id);

-- Note: No need to touch 'challenges' table as it already exists with:
-- Created_At, Name_English, Difficulty, etc.
