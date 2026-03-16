-- Add unit and piece_weight columns to user_custom_foods table
ALTER TABLE user_custom_foods
ADD COLUMN IF NOT EXISTS unit TEXT DEFAULT 'g' CHECK (unit IN ('g', 'ml', 'piece')),
ADD COLUMN IF NOT EXISTS piece_weight DECIMAL(10,2) DEFAULT NULL;

-- Update existing rows to have default unit 'g' if NULL
UPDATE user_custom_foods SET unit = 'g' WHERE unit IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN user_custom_foods.unit IS 'Unit of measurement: g (grams), ml (milliliters), or piece (pieces)';
COMMENT ON COLUMN user_custom_foods.piece_weight IS 'Average weight in grams for one piece (only used when unit is "piece", can be NULL)';

