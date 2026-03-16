-- ============================================
-- FLOW CHALLENGES SYSTEM
-- ============================================

-- Table for available challenges
CREATE TABLE IF NOT EXISTS public.challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    difficulty TEXT DEFAULT 'Beginner', -- 'Beginner', 'Intermediate', 'Advanced'
    category TEXT DEFAULT 'Fitness', -- 'Fitness', 'Nutrition', 'Mindfulness'
    duration_days INTEGER DEFAULT 7,
    reward_coins INTEGER DEFAULT 50,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for user's enrolled challenges
CREATE TABLE IF NOT EXISTS public.user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'STARTED', -- 'STARTED', 'COMPLETED', 'FAILED'
    current_progress INTEGER DEFAULT 0, -- Days completed or specific metric
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, challenge_id)
);

-- Enable RLS
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow public read access to challenges" ON public.challenges FOR SELECT USING (true);

CREATE POLICY "Users can manage own challenge enrollments" ON public.user_challenges FOR ALL USING (auth.uid() = user_id);

-- Seed Data
INSERT INTO public.challenges (title, description, difficulty, category, duration_days, reward_coins, image_url) VALUES
('7-Day Water Flush', 'Drink 2.5L of water every day for a week to detox and hydrate.', 'Beginner', 'Nutrition', 7, 50, 'https://images.unsplash.com/photo-1548919973-5dea585f3968?w=800'),
('Push-up Master', 'Complete 50 push-ups daily for 14 days to build upper body strength.', 'Intermediate', 'Fitness', 14, 150, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800'),
('Sugar-Free Week', 'Avoid all processed sugars for 7 days to reset your palate and energy.', 'Advanced', 'Nutrition', 7, 200, 'https://images.unsplash.com/photo-1590080875515-8a3a8dc3605e?w=800'),
('Morning Meditation', 'Start your day with 10 minutes of mindfulness for 10 days.', 'Beginner', 'Mindfulness', 10, 100, 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800'),
('Squattober', '100 squats every day for 30 days. Feel the burn!', 'Advanced', 'Fitness', 30, 500, 'https://images.unsplash.com/photo-1574680088814-c9e8a10d8a4d?w=800');
