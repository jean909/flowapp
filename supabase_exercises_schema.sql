-- Create exercises table
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en TEXT NOT NULL,
    name_de TEXT NOT NULL,
    muscle_group TEXT NOT NULL, -- 'Chest', 'Legs', 'Back', 'Abs', 'Arms', 'Shoulders', 'Cardio', 'Full Body'
    equipment TEXT DEFAULT 'None', -- 'None', 'Dumbbells', 'Resistance Band', etc.
    difficulty TEXT DEFAULT 'Beginner', -- 'Beginner', 'Intermediate', 'Advanced'
    instructions_en TEXT,
    instructions_de TEXT,
    video_url TEXT,
    calories_per_rep DECIMAL(5,2) DEFAULT 0.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create exercise_logs table
CREATE TABLE IF NOT EXISTS public.exercise_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    exercise_id UUID REFERENCES public.exercises(id) NOT NULL,
    sets INTEGER DEFAULT 1,
    reps INTEGER DEFAULT 0,
    weight_kg DECIMAL(5,2) DEFAULT 0,
    duration_seconds INTEGER DEFAULT 0, -- For cardio or timed exercises
    calories_burned DECIMAL(10,2) DEFAULT 0,
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow public read access to exercises" ON public.exercises FOR SELECT USING (true);

CREATE POLICY "Users can insert own exercise logs" ON public.exercise_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own exercise logs" ON public.exercise_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own exercise logs" ON public.exercise_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own exercise logs" ON public.exercise_logs FOR DELETE USING (auth.uid() = user_id);

-- Insert Initial Home Exercises (EN & DE)
INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
('Push-ups', 'Liegestütze', 'Chest', 'None', 'Beginner', 'Keep your body in a straight line.', 'Halten Sie Ihren Körper in einer geraden Linie.', 0.8),
('Squats', 'Kniebeugen', 'Legs', 'None', 'Beginner', 'Keep your back straight and lower your hips.', 'Halten Sie den Rücken gerade und senken Sie die Hüften.', 0.6),
('Lunges', 'Ausfallschritte', 'Legs', 'None', 'Beginner', 'Step forward with one leg and lower your hips.', 'Machen Sie einen Schritt nach vorne und senken Sie die Hüften.', 0.7),
('Plank', 'Unterarmstütz', 'Abs', 'None', 'Intermediate', 'Hold your body in a straight line supported by forearms.', 'Halten Sie Ihren Körper gerade, gestützt auf die Unterarme.', 0.2), -- Calories per second? Let's assume per rep/unit
('Crunches', 'Crunches', 'Abs', 'None', 'Beginner', 'Lift your shoulders off the ground using your abs.', 'Heben Sie Ihre Schultern mit den Bauchmuskeln vom Boden ab.', 0.4),
('Burpees', 'Burpees', 'Full Body', 'None', 'Advanced', 'Full body exercise combining a squat, push-up, and jump.', 'Ganzkörperübung, die Kniebeuge, Liegestütz und Sprung kombiniert.', 1.5),
('Mountain Climbers', 'Bergsteiger', 'Cardio', 'None', 'Intermediate', 'Bring knees to chest alternately in a plank position.', 'Bringen Sie die Knie in der Plank-Position abwechselnd zur Brust.', 0.5),
('Jumping Jacks', 'Hampelmann', 'Cardio', 'None', 'Beginner', 'Jump with legs apart and hands overhead.', 'Springen Sie mit gespreizten Beinen und Händen über dem Kopf.', 0.6),
('Glute Bridge', 'Beckenheben', 'Legs', 'None', 'Beginner', 'Lift your hips while lying on your back.', 'Heben Sie Ihr Becken an, während Sie auf dem Rücken liegen.', 0.5),
('Tricep Dips', 'Trizeps-Dips', 'Arms', 'None', 'Beginner', 'Lower your body using a chair or bench.', 'Senken Sie Ihren Körper mit Hilfe eines Stuhls oder einer Bank.', 0.6),
('Russian Twists', 'Russian Twists', 'Abs', 'None', 'Intermediate', 'Twist your torso from side to side while sitting.', 'Drehen Sie Ihren Oberkörper im Sitzen von Seite zu Seite.', 0.5);
