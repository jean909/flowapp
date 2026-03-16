-- ==========================================
-- WORKOUT ROUTINES & PLANNING
-- ==========================================

-- Workout Routines (saved workout templates)
CREATE TABLE IF NOT EXISTS workout_routines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    exercises JSONB NOT NULL, -- Array of exercise objects with sets, reps, weight
    total_duration_minutes INTEGER,
    total_calories DECIMAL(10,2),
    difficulty TEXT CHECK (difficulty IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),
    muscle_groups TEXT[], -- Array of muscle groups targeted
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Planned Workouts (scheduled future workouts)
CREATE TABLE IF NOT EXISTS planned_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    routine_id UUID REFERENCES workout_routines(id) ON DELETE SET NULL, -- Optional: link to routine
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    exercises JSONB NOT NULL, -- Array of exercise objects
    notes TEXT,
    status TEXT DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'COMPLETED', 'SKIPPED', 'CANCELLED')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout Sessions (completed workouts with full details)
CREATE TABLE IF NOT EXISTS workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    planned_workout_id UUID REFERENCES planned_workouts(id) ON DELETE SET NULL,
    routine_id UUID REFERENCES workout_routines(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,
    total_calories_burned DECIMAL(10,2) DEFAULT 0,
    exercises_completed JSONB NOT NULL, -- Full exercise log data
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5), -- 1-5 stars
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE workout_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE planned_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own routines" ON workout_routines FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own planned workouts" ON planned_workouts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own workout sessions" ON workout_sessions FOR ALL USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workout_routines_user_id ON workout_routines(user_id);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_user_id ON planned_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_planned_workouts_date ON planned_workouts(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_start_time ON workout_sessions(start_time);

