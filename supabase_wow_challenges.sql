-- DROP OLD TABLES
DROP TABLE IF EXISTS user_challenges CASCADE;
DROP TABLE IF EXISTS challenges CASCADE;

-- CREATE NEW CHALLENGES TABLE
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title_en TEXT NOT NULL,
    title_de TEXT NOT NULL,
    description_en TEXT NOT NULL,
    description_de TEXT NOT NULL,
    goal_type TEXT NOT NULL, -- WATER, PROTEIN, FASTING, STREAK, WORKOUT
    goal_value FLOAT NOT NULL,
    reward_coins INTEGER DEFAULT 50,
    difficulty TEXT DEFAULT 'MEDIUM', -- EASY, MEDIUM, HARD
    icon TEXT DEFAULT '🏆',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- CREATE NEW USER_CHALLENGES TABLE (LINKING)
CREATE TABLE user_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE NOT NULL,
    progress FLOAT DEFAULT 0 NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL, -- active, completed
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, challenge_id)
);

-- ENABLE RLS
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;

-- POLICIES
CREATE POLICY "Anyone can read challenges" ON challenges FOR SELECT USING (true);
CREATE POLICY "Users can read own challenges" ON user_challenges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can join challenges" ON user_challenges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own challenge progress" ON user_challenges FOR UPDATE USING (auth.uid() = user_id);

-- SEED DATA: WOW CHALLENGES
INSERT INTO challenges (title_en, title_de, description_en, description_de, goal_type, goal_value, reward_coins, difficulty, icon)
VALUES 
('Water Warrior', 'Wasser-Krieger', 'Drink 2000ml of water today.', 'Trinke heute 2000ml Wasser.', 'WATER', 2000, 50, 'EASY', '💧'),
('Protein Pro', 'Protein-Profi', 'Reach 150g of protein to maximize muscle growth.', 'Erreiche 150g Protein, um das Muskelwachstum zu maximieren.', 'PROTEIN', 150, 100, 'MEDIUM', '💪'),
('Fast Lane', 'Überholspur', 'Complete a 16-hour fast.', 'Absolviere ein 16-Stunden-Fasten.', 'FASTING', 16, 75, 'MEDIUM', '⏳'),
('Habit Hero', 'Gewohnheits-Held', 'Maintain a 7-day login streak.', 'Behalte eine 7-tägige Login-Serie bei.', 'STREAK', 7, 200, 'HARD', '🔥'),
('Workout Wizard', 'Trainings-Zauberer', 'Log 3 workouts this week.', 'Protokolliere 3 Trainingseinheiten in dieser Woche.', 'WORKOUT', 3, 150, 'MEDIUM', '🏋️'),
('Hydration Hero', 'Hydratations-Held', 'Drink 3000ml of water for ultimate clarity.', 'Trinke 3000ml Wasser für ultimative Klarheit.', 'WATER', 3000, 100, 'MEDIUM', '🌊'),
('Early Bird Fast', 'Frühaufsteher-Fasten', 'Complete a fast ending before 8 AM.', 'Beende ein Fasten vor 8 Uhr morgens.', 'FASTING', 12, 50, 'EASY', '🌅');
