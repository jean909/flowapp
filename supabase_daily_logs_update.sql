-- ==========================================
-- UPDATE daily_logs TO STORE ALL NUTRITIONAL DATA
-- ==========================================
-- This migration adds a nutrition_data JSONB field to store ALL nutritional information
-- This is critical for supplement sales - we need to track ALL nutrients (caffeine, calcium, etc.)

-- Add nutrition_data JSONB field to daily_logs
ALTER TABLE daily_logs 
ADD COLUMN IF NOT EXISTS nutrition_data JSONB DEFAULT '{}'::jsonb;

-- Add recipe_id to link recipes to daily_logs
ALTER TABLE daily_logs
ADD COLUMN IF NOT EXISTS recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL;

-- Create index on nutrition_data for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_logs_nutrition_data ON daily_logs USING GIN (nutrition_data);

-- Create index on recipe_id
CREATE INDEX IF NOT EXISTS idx_daily_logs_recipe_id ON daily_logs (recipe_id);

-- Comment explaining the nutrition_data structure
COMMENT ON COLUMN daily_logs.nutrition_data IS 'Complete nutritional data in JSONB format. Contains all nutrients: calories, protein, carbs, fat, fiber, sugar, saturated_fat, omega3, omega6, all vitamins (A, C, D, E, K, B1-B12), all minerals (calcium, iron, magnesium, etc.), water, caffeine, creatine, taurine, beta_alanine, l_carnitine, glutamine, bcaa, and all amino acids. This is essential for supplement sales tracking.';

