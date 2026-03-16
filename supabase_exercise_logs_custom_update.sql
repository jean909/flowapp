-- Update exercise_logs to support custom exercises
-- Add custom_exercise_id column (nullable, for user custom exercises)
ALTER TABLE public.exercise_logs
ADD COLUMN IF NOT EXISTS custom_exercise_id UUID REFERENCES public.user_custom_exercises(id) ON DELETE CASCADE;

-- Make exercise_id nullable (since we'll use either exercise_id OR custom_exercise_id)
-- Actually, let's keep exercise_id NOT NULL for general exercises and use custom_exercise_id for custom
-- Add constraint to ensure at least one is set
ALTER TABLE public.exercise_logs
ADD CONSTRAINT check_exercise_reference 
CHECK (
  (exercise_id IS NOT NULL AND custom_exercise_id IS NULL) OR 
  (exercise_id IS NULL AND custom_exercise_id IS NOT NULL)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_exercise_logs_custom_exercise_id 
ON public.exercise_logs(custom_exercise_id);

COMMENT ON COLUMN public.exercise_logs.custom_exercise_id IS 'Reference to user custom exercise (if exercise_id is NULL)';
COMMENT ON CONSTRAINT check_exercise_reference ON public.exercise_logs IS 'Ensures either exercise_id or custom_exercise_id is set, but not both';

