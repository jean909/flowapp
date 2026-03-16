-- ============================================
-- MARKETPLACE & ADD-ONS SYSTEM
-- ============================================

-- Table for available add-ons with pricing
CREATE TABLE IF NOT EXISTS available_addons (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    category TEXT,
    is_premium BOOLEAN DEFAULT false,
    price_monthly DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    preferred_gender TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table for user's activated add-ons
CREATE TABLE IF NOT EXISTS user_addons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    addon_id TEXT REFERENCES available_addons(id) NOT NULL,
    activated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ, -- For subscription management
    UNIQUE(user_id, addon_id)
);

-- RLS for user_addons
ALTER TABLE user_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own addons" 
ON user_addons FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addons" 
ON user_addons FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addons" 
ON user_addons FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addons" 
ON user_addons FOR DELETE
USING (auth.uid() = user_id);

-- Seed available add-ons with pricing
INSERT INTO available_addons (id, name, description, icon, category, is_premium, price_monthly, preferred_gender) VALUES
('menstruation_tracker', 'Menstruation Tracker', 'Track your cycle, predict periods, and monitor symptoms with advanced insights', '🩸', 'tracker', true, 4.99, 'female'),
('sleep_tracker', 'Sleep Tracker', 'Monitor sleep quality, duration, and patterns', '😴', 'tracker', true, 3.99, NULL),
('mood_tracker', 'Mood Tracker', 'Track daily mood and emotional patterns with AI insights', '😊', 'tracker', true, 2.99, NULL),
('advanced_analytics', 'Advanced Analytics', 'Deep insights, trend analysis, and personalized recommendations', '📊', 'analytics', true, 9.99, NULL),
('meal_planner', 'AI Meal Planner', 'Personalized meal plans based on your goals', '🍽️', 'ai', true, 7.99, NULL),
('workout_tracker', 'Workout Tracker', 'Track exercises, sets, reps, and progress', '💪', 'tracker', true, 5.99, NULL)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price_monthly = EXCLUDED.price_monthly,
    is_premium = EXCLUDED.is_premium,
    preferred_gender = EXCLUDED.preferred_gender;

-- ============================================
-- MENSTRUATION TRACKER TABLES
-- ============================================

-- Main menstruation logs table
CREATE TABLE IF NOT EXISTS menstruation_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE,
    cycle_length INTEGER,
    flow_intensity TEXT CHECK (flow_intensity IN ('light', 'medium', 'heavy')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Menstruation setup/configuration table
CREATE TABLE IF NOT EXISTS menstruation_setup (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
    average_cycle_length INTEGER DEFAULT 28,
    average_period_length INTEGER DEFAULT 5,
    last_period_start DATE,
    tracking_since DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily symptoms table
CREATE TABLE IF NOT EXISTS menstruation_symptoms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    date DATE NOT NULL,
    symptoms TEXT[] DEFAULT '{}',
    mood TEXT,
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- RLS for menstruation tables
ALTER TABLE menstruation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE menstruation_setup ENABLE ROW LEVEL SECURITY;
ALTER TABLE menstruation_symptoms ENABLE ROW LEVEL SECURITY;

-- Policies for menstruation_logs
CREATE POLICY "Users can manage their own menstruation logs" 
ON menstruation_logs FOR ALL
USING (auth.uid() = user_id);

-- Policies for menstruation_setup
CREATE POLICY "Users can manage their own menstruation setup" 
ON menstruation_setup FOR ALL
USING (auth.uid() = user_id);

-- Policies for menstruation_symptoms
CREATE POLICY "Users can manage their own symptoms" 
ON menstruation_symptoms FOR ALL
USING (auth.uid() = user_id);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_addons_user_id ON user_addons(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addons_addon_id ON user_addons(addon_id);
CREATE INDEX IF NOT EXISTS idx_menstruation_logs_user_id ON menstruation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_menstruation_logs_period_start ON menstruation_logs(period_start);
CREATE INDEX IF NOT EXISTS idx_menstruation_symptoms_user_date ON menstruation_symptoms(user_id, date);

-- ============================================
-- FUNCTIONS FOR AUTOMATIC UPDATES
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_menstruation_logs_updated_at BEFORE UPDATE ON menstruation_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menstruation_setup_updated_at BEFORE UPDATE ON menstruation_setup
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
