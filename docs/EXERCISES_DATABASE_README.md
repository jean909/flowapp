# Exercises Database - Flow App

## Overview
This document describes the comprehensive exercise database for the Flow app, containing 100+ exercises covering all major muscle groups and equipment types.

## Database Structure

### Table: `exercises`
- `id` (UUID) - Primary key
- `name_en` (TEXT) - Exercise name in English
- `name_de` (TEXT) - Exercise name in German
- `muscle_group` (TEXT) - Target muscle group
- `equipment` (TEXT) - Required equipment
- `difficulty` (TEXT) - Difficulty level
- `instructions_en` (TEXT) - Instructions in English
- `instructions_de` (TEXT) - Instructions in German
- `video_url` (TEXT) - Optional video URL
- `calories_per_rep` (DECIMAL) - Estimated calories per repetition
- `created_at` (TIMESTAMP) - Creation timestamp

### Muscle Groups
- **Chest** (Brust) - 12 exercises
- **Back** (Rücken) - 9 exercises
- **Legs** (Beine) - 17 exercises
- **Shoulders** (Schultern) - 9 exercises
- **Arms** (Arme) - 10 exercises
- **Abs** (Bauch) - 12 exercises
- **Cardio** - 10 exercises
- **Full Body** (Ganzkörper) - 7 exercises

### Equipment Types
- **None** - Bodyweight exercises
- **Dumbbells** - Requires dumbbells
- **Pull-up Bar** - Requires pull-up bar
- **Resistance Band** - Requires resistance band
- **Jump Rope** - Requires jump rope

### Difficulty Levels
- **Beginner** - Suitable for beginners
- **Intermediate** - Moderate difficulty
- **Advanced** - Challenging exercises

## Installation

### Step 1: Create the table (if not exists)
Run the SQL from `supabase_exercises_schema.sql` to create the table structure.

### Step 2: Insert exercises
Run the SQL from `supabase_exercises_comprehensive.sql` to populate the database with 100+ exercises.

```sql
-- In Supabase SQL Editor, run:
\i supabase_exercises_comprehensive.sql
```

Or copy and paste the entire content into the Supabase SQL Editor.

## Usage in App

### Search Exercises
```dart
final exercises = await supabaseService.searchExercises('push');
```

### Filter by Muscle Group
```dart
final chestExercises = await supabaseService.getExercisesByMuscleGroup('Chest');
```

### Filter by Equipment
```dart
final bodyweightExercises = await supabaseService.getExercisesByEquipment('None');
```

### Filter by Difficulty
```dart
final beginnerExercises = await supabaseService.getExercisesByDifficulty('Beginner');
```

### Multiple Filters
```dart
final filtered = await supabaseService.getExercisesFiltered(
  muscleGroup: 'Chest',
  equipment: 'None',
  difficulty: 'Beginner',
  searchQuery: 'push',
);
```

### Get Available Filters
```dart
final muscleGroups = await supabaseService.getMuscleGroups();
final equipmentTypes = await supabaseService.getEquipmentTypes();
```

## Exercise Categories Breakdown

### Chest Exercises (12)
- Push-ups variations (standard, wide, diamond, incline, decline, pike, archer)
- Dumbbell exercises (bench press, flyes, pullover)
- Push-up with rotation

### Back Exercises (9)
- Pull-ups and chin-ups
- Inverted rows
- Superman and reverse snow angels
- Prone Y-T-W
- Dumbbell rows (bent-over, one-arm, reverse flyes)

### Legs Exercises (17)
- Squats (standard, jump, goblet, pistol)
- Lunges (forward, reverse, walking, Bulgarian split)
- Calf raises (standard, single-leg)
- Glute bridges (standard, single-leg, hip thrusts)
- Wall sit
- Romanian deadlifts
- Step-ups

### Shoulders Exercises (9)
- Pike push-ups
- Handstand push-ups
- Wall walk
- Shoulder taps
- Dumbbell exercises (press, lateral raises, front raises, rear delt flyes, Arnold press)

### Arms Exercises (10)
- Tricep exercises (dips, extensions, kickbacks)
- Bicep exercises (curls, hammer curls, concentration curls)
- Diamond and close-grip push-ups

### Abs Exercises (12)
- Crunches variations
- Plank variations (standard, side)
- Russian twists
- Mountain climbers
- Leg raises
- Flutter kicks
- Dead bug
- V-ups
- Hollow body hold
- Scissor kicks

### Cardio Exercises (10)
- Jumping jacks
- Burpees
- High knees
- Butt kicks
- Jump rope
- Mountain climbers
- Star jumps
- Sprint in place
- Jump squats
- Bear crawl

### Full Body Exercises (7)
- Burpees
- Thrusters
- Man makers
- Turkish get-ups
- Renegade rows
- Squat to press
- Deadlift to row

## Future Enhancements

1. **Video URLs**: Add video demonstration URLs for each exercise
2. **Exercise Images**: Add image URLs showing proper form
3. **Target Muscles Array**: Store primary and secondary muscles
4. **Exercise Type**: Add field for strength/cardio/flexibility
5. **Common Mistakes**: Add field with common form mistakes to avoid
6. **Progression Path**: Link exercises to show progression (e.g., push-up → diamond push-up)
7. **Equipment Alternatives**: Show alternative equipment for same exercise
8. **Calorie Calculation**: Improve calorie calculation based on user weight and intensity

## Maintenance

### Adding New Exercises
Simply add new INSERT statements to `supabase_exercises_comprehensive.sql` following the same format:

```sql
INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
('Exercise Name', 'Übungsname', 'Muscle Group', 'Equipment', 'Difficulty', 'English instructions...', 'Deutsche Anweisungen...', 0.5);
```

### Updating Existing Exercises
Use UPDATE statements:

```sql
UPDATE public.exercises 
SET instructions_en = 'Updated instructions'
WHERE name_en = 'Exercise Name';
```

## Notes

- Calories per rep are estimates and should be adjusted based on user weight
- All exercises have both English and German translations
- The database is designed to be easily extensible
- RLS policies ensure users can only view exercises (public read access)
- Exercise logs are user-specific (users can only see their own logs)


