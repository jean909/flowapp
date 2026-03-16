-- ==========================================
-- AUTO CREATE PROFILE TRIGGER
-- ==========================================
-- This trigger automatically creates a profile entry when a new user signs up
-- Run this in Supabase SQL Editor

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  metadata JSONB;
  goal_val TEXT;
  gender_val TEXT;
  age_val INTEGER;
  weight_val DECIMAL;
  target_weight_val DECIMAL;
  height_val DECIMAL;
  activity_val TEXT;
  is_smoker_val BOOLEAN;
  full_name_val TEXT;
  onboarding_meta JSONB;
  -- Target calculation variables
  bmr DECIMAL;
  multiplier DECIMAL;
  tdee DECIMAL;
  calorie_target INTEGER;
  protein_pct INTEGER;
  carbs_pct INTEGER;
  fat_pct INTEGER;
  water_target INTEGER;
BEGIN
  -- Get metadata from user
  metadata := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
  
  -- Extract and validate REQUIRED fields - NO FALLBACKS
  goal_val := NULLIF(metadata->>'goal', '');
  IF goal_val IS NULL OR goal_val NOT IN ('LOSE', 'MAINTAIN', 'GAIN') THEN
    RAISE EXCEPTION 'Missing or invalid goal in onboarding data';
  END IF;
  
  gender_val := NULLIF(metadata->>'gender', '');
  IF gender_val IS NULL OR gender_val NOT IN ('MALE', 'FEMALE', 'OTHER') THEN
    RAISE EXCEPTION 'Missing or invalid gender in onboarding data';
  END IF;
  
  -- Safe integer casting for age
  BEGIN
    age_val := NULLIF(metadata->>'age', '')::INTEGER;
    IF age_val IS NULL OR age_val <= 0 THEN
      RAISE EXCEPTION 'Missing or invalid age in onboarding data';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid age value in onboarding data';
  END;
  
  -- Safe decimal casting for weight
  BEGIN
    weight_val := NULLIF(metadata->>'current_weight', '')::DECIMAL;
    IF weight_val IS NULL OR weight_val <= 0 THEN
      RAISE EXCEPTION 'Missing or invalid current_weight in onboarding data';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid current_weight value in onboarding data';
  END;
  
  -- Safe decimal casting for height
  BEGIN
    height_val := NULLIF(metadata->>'height', '')::DECIMAL;
    IF height_val IS NULL OR height_val <= 0 THEN
      RAISE EXCEPTION 'Missing or invalid height in onboarding data';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid height value in onboarding data';
  END;
  
  activity_val := NULLIF(metadata->>'activity_level', '');
  IF activity_val IS NULL OR activity_val NOT IN ('SEDENTARY', 'LIGHTLY ACTIVE', 'MODERATELY ACTIVE', 'VERY ACTIVE') THEN
    RAISE EXCEPTION 'Missing or invalid activity_level in onboarding data';
  END IF;
  
  -- Optional fields
  BEGIN
    target_weight_val := NULLIF(metadata->>'target_weight', '')::DECIMAL;
  EXCEPTION WHEN OTHERS THEN
    target_weight_val := NULL;
  END;
  
  BEGIN
    IF metadata->>'is_smoker' IS NOT NULL AND metadata->>'is_smoker' != '' THEN
      is_smoker_val := (metadata->>'is_smoker')::BOOLEAN;
    ELSE
      is_smoker_val := NULL;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    is_smoker_val := NULL;
  END;
  
  full_name_val := COALESCE(
    NULLIF(metadata->>'full_name', ''),
    split_part(NEW.email, '@', 1),
    'User'
  );
  
  onboarding_meta := COALESCE(metadata->'onboarding_metadata', '{}'::jsonb);
  
  -- Calculate BMR (Mifflin-St Jeor Equation)
  IF UPPER(gender_val) = 'MALE' THEN
    bmr := (10 * weight_val) + (6.25 * height_val) - (5 * age_val) + 5;
  ELSE
    bmr := (10 * weight_val) + (6.25 * height_val) - (5 * age_val) - 161;
  END IF;
  
  -- Activity Multiplier
  multiplier := 1.2; -- Default SEDENTARY
  CASE UPPER(activity_val)
    WHEN 'SEDENTARY' THEN multiplier := 1.2;
    WHEN 'LIGHTLY ACTIVE' THEN multiplier := 1.375;
    WHEN 'MODERATELY ACTIVE' THEN multiplier := 1.55;
    WHEN 'VERY ACTIVE' THEN multiplier := 1.725;
  END CASE;
  
  tdee := bmr * multiplier;
  
  -- Adjust for Goal
  CASE UPPER(goal_val)
    WHEN 'LOSE' THEN
      calorie_target := (tdee - 500)::INTEGER;
      protein_pct := 35;
      carbs_pct := 35;
      fat_pct := 30;
    WHEN 'GAIN' THEN
      calorie_target := (tdee + 300)::INTEGER;
      protein_pct := 25;
      carbs_pct := 45;
      fat_pct := 30;
    WHEN 'MAINTAIN' THEN
      calorie_target := tdee::INTEGER;
      protein_pct := 30;
      carbs_pct := 40;
      fat_pct := 30;
  END CASE;
  
  -- Calculate water target (35ml per kg + gender/activity adjustments)
  water_target := (weight_val * 35)::INTEGER;
  IF UPPER(gender_val) = 'MALE' THEN
    water_target := water_target + 500;
  ELSIF UPPER(gender_val) = 'FEMALE' THEN
    water_target := water_target + 200;
  END IF;
  
  CASE UPPER(activity_val)
    WHEN 'LIGHTLY ACTIVE' THEN water_target := water_target + 300;
    WHEN 'MODERATELY ACTIVE' THEN water_target := water_target + 500;
    WHEN 'VERY ACTIVE' THEN water_target := water_target + 800;
  END CASE;
  
  -- Round to nearest 50ml and ensure bounds
  water_target := ((water_target / 50)::INTEGER * 50);
  IF water_target < 1500 THEN water_target := 1500; END IF;
  IF water_target > 5000 THEN water_target := 5000; END IF;
  
  -- Insert profile with ALL required fields and calculated targets
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name,
    goal,
    gender,
    age,
    current_weight,
    target_weight,
    height,
    activity_level,
    is_smoker,
    onboarding_metadata,
    daily_calorie_target,
    protein_target_percentage,
    carbs_target_percentage,
    fat_target_percentage,
    daily_water_target,
    coins, 
    plan_type, 
    created_at, 
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    full_name_val,
    goal_val,
    gender_val,
    age_val,
    weight_val,
    target_weight_val,
    height_val,
    activity_val,
    is_smoker_val,
    onboarding_meta,
    calorie_target,
    protein_pct,
    carbs_pct,
    fat_pct,
    water_target,
    100, -- Initial coins
    'free', -- Default plan
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Prevent errors if profile already exists
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the user creation
  -- In production, you might want to log this to a table
  RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger that fires after a new user is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- Verify the trigger was created
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table, 
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

