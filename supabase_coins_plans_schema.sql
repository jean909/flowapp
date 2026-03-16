-- ============================================
-- FLOW COINS & SUBSCRIPTION SYSTEM
-- ============================================

-- 1. Update Profiles with Coins and Plan
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS coins INTEGER DEFAULT 100,
ADD COLUMN IF NOT EXISTS plan_type TEXT DEFAULT 'free' CHECK (plan_type IN ('free', 'premium', 'creator'));

-- 2. Create Coin Transactions for auditing
CREATE TABLE IF NOT EXISTS coin_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL,
    type TEXT CHECK (type IN ('EARN', 'SPEND', 'PURCHASE', 'BONUS')),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Update Available Addons with Coin Price
ALTER TABLE available_addons 
ADD COLUMN IF NOT EXISTS coin_price INTEGER;

-- Update existing addons with coin prices (10 coins = 1 USD approx)
UPDATE available_addons SET coin_price = 50 WHERE id = 'menstruation_tracker';
UPDATE available_addons SET coin_price = 40 WHERE id = 'sleep_tracker';
UPDATE available_addons SET coin_price = 30 WHERE id = 'mood_tracker';
UPDATE available_addons SET coin_price = 100 WHERE id = 'advanced_analytics';
UPDATE available_addons SET coin_price = 80 WHERE id = 'meal_planner';
UPDATE available_addons SET coin_price = 60 WHERE id = 'workout_tracker';

-- 4. RLS for Transactions
ALTER TABLE coin_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions" 
ON coin_transactions FOR SELECT
USING (auth.uid() = user_id);

-- 5. FUNCTION & TRIGGER FOR INITIAL COINS
-- This is a safety measure in case a profile is created without initial coins logic
CREATE OR REPLACE FUNCTION grant_initial_coins()
RETURNS TRIGGER AS $$
BEGIN
    -- Grant 100 coins to new profiles
    NEW.coins = 100;
    
    -- Record the initial bonus
    INSERT INTO coin_transactions (user_id, amount, type, description)
    VALUES (NEW.id, 100, 'BONUS', 'Welcome bonus coins');
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Note: We only apply this if it's a NEW row and coins is null or 0
-- But usually handle_new_user is the better place for this in production.
-- Since we are iterating, we'll just ensure it's there.
