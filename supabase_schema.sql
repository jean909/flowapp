-- ==========================================
-- FLOW APP ADDITIONAL TABLES
-- ==========================================

-- 1. USER PROFILES
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    goal TEXT CHECK (goal IN ('LOSE', 'MAINTAIN', 'GAIN')),
    gender TEXT CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    age INTEGER,
    current_weight DECIMAL(5,2),
    target_weight DECIMAL(5,2),
    height DECIMAL(5,2),
    activity_level TEXT,
    daily_calorie_target INTEGER,
    protein_target_percentage INTEGER DEFAULT 30,
    carbs_target_percentage INTEGER DEFAULT 40,
    fat_target_percentage INTEGER DEFAULT 30,
    is_smoker BOOLEAN,
    professional_life TEXT,
    onboarding_metadata JSONB DEFAULT '{}'::jsonb,
    tracked_nutrients JSONB DEFAULT '[]'::jsonb,
    daily_water_target INTEGER DEFAULT 2000,
    water_reminders_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DAILY FOOD LOGS
CREATE TABLE IF NOT EXISTS daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    food_id UUID REFERENCES general_food_flow(id),
    custom_food_name TEXT,
    calories DECIMAL(10,2),
    protein DECIMAL(10,2),
    carbs DECIMAL(10,2),
    fat DECIMAL(10,2),
    quantity DECIMAL(10,2) NOT NULL,
    unit TEXT NOT NULL,
    meal_type TEXT CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fasting_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SPORTS PROGRAMS
CREATE TABLE IF NOT EXISTS sports_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    difficulty TEXT CHECK (difficulty IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),
    duration_weeks INTEGER,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. USER ENROLLED PROGRAMS
CREATE TABLE IF NOT EXISTS user_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    program_id UUID REFERENCES sports_programs(id) ON DELETE CASCADE NOT NULL,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'IN_PROGRESS'
);

-- 5. SOCIAL POSTS
CREATE TABLE IF NOT EXISTS social_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT,
    image_url TEXT,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. WATER LOGS
CREATE TABLE IF NOT EXISTS water_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    amount_ml INTEGER NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. WEIGHT LOGS
CREATE TABLE IF NOT EXISTS weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. FAVORITE FOODS
CREATE TABLE IF NOT EXISTS favorite_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    food_id UUID REFERENCES general_food_flow(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, food_id)
);

-- 9. USER CUSTOM FOODS (from camera, voice, etc.)
CREATE TABLE IF NOT EXISTS user_custom_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    german_name TEXT,
    calories DECIMAL(10,2),
    protein DECIMAL(10,2),
    carbs DECIMAL(10,2),
    fat DECIMAL(10,2),
    fiber DECIMAL(10,2),
    sugar DECIMAL(10,2),
    sodium DECIMAL(10,2),
    water DECIMAL(10,2),
    caffeine DECIMAL(10,2),
    image_url TEXT,
    source TEXT, -- 'camera', 'barcode', 'voice'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- RLS POLICIES
-- ==========================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sports_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_custom_foods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can manage own logs" ON daily_logs FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Public items are viewable by everyone" ON sports_programs FOR SELECT USING (true);

CREATE POLICY "Users can manage own enrollments" ON user_programs FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view posts" ON social_posts FOR SELECT USING (true);
CREATE POLICY "Users can manage own posts" ON social_posts FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own water logs" ON water_logs FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own weight logs" ON weight_logs FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own favorite foods" ON favorite_foods FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add favorite foods" ON favorite_foods FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove favorite foods" ON favorite_foods FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own custom foods" ON user_custom_foods FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- STORAGE BUCKETS
-- ==========================================
-- Note: Create 'food_images' bucket in Supabase Dashboard with public access

-- Policy: Public can view food images (temporary for AI recognition)
CREATE POLICY "Public Food Images" ON storage.objects FOR SELECT USING ( bucket_id = 'food_images' );

-- Policy: Users can upload food images
CREATE POLICY "Users can upload food images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'food_images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own food images
CREATE POLICY "Users can delete own food images" ON storage.objects FOR DELETE USING (
    bucket_id = 'food_images' AND auth.uid()::text = (storage.foldername(name))[1]
);
