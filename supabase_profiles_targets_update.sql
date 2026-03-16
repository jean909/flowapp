-- =============================================
-- ADD MISSING TARGET FIELDS TO PROFILES TABLE
-- =============================================

-- Add fiber_target and sugar_target columns if they don't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fiber_target DECIMAL(5,2) DEFAULT 25.0,
ADD COLUMN IF NOT EXISTS sugar_target DECIMAL(5,2) DEFAULT 50.0;

-- Update existing profiles with calculated defaults if they are NULL
-- Fiber: Recommended daily intake is 25-30g for women, 30-38g for men
-- Sugar: WHO recommends <50g per day (ideally <25g)
UPDATE profiles 
SET 
  fiber_target = CASE 
    WHEN gender = 'FEMALE' THEN 25.0
    WHEN gender = 'MALE' THEN 30.0
    ELSE 27.5
  END,
  sugar_target = 50.0
WHERE fiber_target IS NULL OR sugar_target IS NULL;

