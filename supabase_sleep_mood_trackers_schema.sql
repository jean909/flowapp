-- ============================================
-- SLEEP AND MOOD TRACKER TABLES
-- ============================================

-- Sleep Logs Table
CREATE TABLE IF NOT EXISTS sleep_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    sleep_date DATE NOT NULL,
    bedtime TIMESTAMPTZ,
    wake_time TIMESTAMPTZ,
    duration_hours DECIMAL(4,2),
    quality_rating INTEGER CHECK (quality_rating >= 1 AND quality_rating <= 5),
    sleep_stages JSONB DEFAULT '{}'::jsonb, -- {deep: 120, rem: 90, light: 180, awake: 30} in minutes
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, sleep_date)
);

-- Mood Logs Table
CREATE TABLE IF NOT EXISTS mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    log_date DATE NOT NULL,
    mood TEXT CHECK (mood IN ('very_happy', 'happy', 'neutral', 'sad', 'very_sad', 'anxious', 'stressed', 'calm', 'energetic', 'tired')),
    mood_score INTEGER CHECK (mood_score >= 1 AND mood_score <= 10),
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 5),
    activities JSONB DEFAULT '[]'::jsonb, -- Array of activities that affected mood
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

-- Enable RLS
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own sleep logs" ON sleep_logs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own mood logs" ON mood_logs FOR ALL USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date ON sleep_logs(user_id, sleep_date);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_date ON mood_logs(user_id, log_date);

-- Triggers for updated_at
CREATE TRIGGER update_sleep_logs_updated_at BEFORE UPDATE ON sleep_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mood_logs_updated_at BEFORE UPDATE ON mood_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

