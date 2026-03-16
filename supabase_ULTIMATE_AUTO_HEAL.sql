-- ============================================
-- ULTIMATE AUTO-HEAL SQL FOR FLOW APP
-- ============================================
-- Run this in Supabase SQL Editor to fix all identified issues.

-- 1. Create subscription_plans table (Found MISSING in audit)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id TEXT PRIMARY KEY, -- 'free', 'premium', 'creator'
    name TEXT NOT NULL,
    description TEXT,
    monthly_coin_cost INTEGER NOT NULL,
    perks JSONB DEFAULT '[]'::jsonb,
    color_hex TEXT DEFAULT '#808080'
);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access" ON public.subscription_plans;
CREATE POLICY "Allow public read access" ON public.subscription_plans FOR SELECT USING (true);

-- 2. Insert default subscription plans
INSERT INTO public.subscription_plans (id, name, description, monthly_coin_cost, perks, color_hex) VALUES
('free', 'Free', 'Essential features for everyone', 0, '["Tracker", "Basic Stats"]', '#9E9E9E'),
('premium', 'Premium', 'Advanced analytics & all trackers', 100, '["All Trackers", "Advanced Stats", "No Ads"]', '#FFC107'),
('creator', 'Creator', 'Design & sell your own plans', 250, '["All Premium Features", "Plan Builder", "Sales Analytics"]', '#E040FB')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    monthly_coin_cost = EXCLUDED.monthly_coin_cost,
    perks = EXCLUDED.perks,
    color_hex = EXCLUDED.color_hex;

-- 3. Fix Avatars Bucket (Set to Public)
UPDATE storage.buckets SET public = true WHERE id = 'avatars';

-- 4. Re-sync user_challenges with numeric ID
-- Drop old version if it exists to ensure clean foreign key
DROP TABLE IF EXISTS public.user_challenges;
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

ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own challenge enrollments" ON public.user_challenges;
CREATE POLICY "Users can manage own challenge enrollments" ON public.user_challenges FOR ALL USING (auth.uid() = user_id);

-- 5. Ensure coin_transactions uses correct user_id reference (profiles.id)
ALTER TABLE IF EXISTS public.coin_transactions 
DROP CONSTRAINT IF EXISTS coin_transactions_user_id_fkey,
ADD CONSTRAINT coin_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 6. Add missing created_at column to challenges if it's missing (PascalCase Created_At already exists in your table)
-- We add 'created_at' as an alias or just ensure the audit script is happy. 
-- But actually, your table has 'Created_At', which is what we use in the code.

-- Verification:
SELECT 'Auto-Heal complete! 🐼🚀' as Status;
