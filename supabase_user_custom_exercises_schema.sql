-- Create user_custom_exercises table
CREATE TABLE IF NOT EXISTS public.user_custom_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name_en TEXT NOT NULL,
    name_de TEXT,
    muscle_group TEXT NOT NULL DEFAULT 'Full Body', -- 'Chest', 'Legs', 'Back', 'Abs', 'Arms', 'Shoulders', 'Cardio', 'Full Body'
    equipment TEXT DEFAULT 'None', -- 'None', 'Dumbbells', 'Resistance Band', etc.
    difficulty TEXT DEFAULT 'Beginner', -- 'Beginner', 'Intermediate', 'Advanced'
    instructions_en TEXT,
    instructions_de TEXT,
    calories_per_rep DECIMAL(5,2) DEFAULT 0.5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name_en) -- Prevent duplicates for same user
);

-- Enable RLS
ALTER TABLE public.user_custom_exercises ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can insert their own custom exercises"
ON public.user_custom_exercises FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own custom exercises"
ON public.user_custom_exercises FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own custom exercises"
ON public.user_custom_exercises FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom exercises"
ON public.user_custom_exercises FOR DELETE
USING (auth.uid() = user_id);

-- Index for faster searches
CREATE INDEX IF NOT EXISTS idx_user_custom_exercises_user_id ON public.user_custom_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_user_custom_exercises_name ON public.user_custom_exercises(name_en);

COMMENT ON TABLE public.user_custom_exercises IS 'Custom exercises created by users, especially through AI journal processing';
COMMENT ON COLUMN public.user_custom_exercises.muscle_group IS 'Target muscle group: Chest, Legs, Back, Abs, Arms, Shoulders, Cardio, Full Body';
COMMENT ON COLUMN public.user_custom_exercises.calories_per_rep IS 'Estimated calories burned per rep (or per minute for cardio)';

