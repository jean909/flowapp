# Recipes System Setup

## Overview
This system generates complete recipes with comprehensive nutritional data using:
- **Gemini Flash 2.5** for recipe generation (ingredients, instructions, full nutrition)
- **Nano Banana Pro** for beautiful recipe images
- **Supabase** for storage

## Database Setup

1. Run the schema SQL:
```sql
-- Execute supabase_recipes_schema.sql in Supabase SQL Editor
```

2. Create storage bucket:
- Go to Supabase Dashboard > Storage
- Create bucket: `recipe_images`
- Set to public

## Python Script Setup

1. Install dependencies:
```bash
pip install -r requirements_recipes.txt
```

2. Run the script:

### Generate a specific recipe:
```bash
python generate_recipes.py --recipe "High Protein Breakfast Bowl"
```

### Generate multiple random recipes:
```bash
python generate_recipes.py --count 10
```

### Generate recipes for a specific meal type:
```bash
python generate_recipes.py --meal-type BREAKFAST --count 5
```

## Recipe Data Structure

Each recipe includes:

### Basic Info
- Title (EN + DE)
- Description (EN + DE)
- Prep/Cook/Total time
- Servings
- Recommended meal type
- Diet type

### Ingredients
- Array of ingredients with amounts and units (EN + DE)

### Instructions
- Step-by-step instructions (EN + DE)

### Complete Nutrition (per serving)
- **Macronutrients**: calories, protein, carbs, fat, fiber, sugar, saturated_fat
- **Essential Fats**: omega3, omega6
- **Vitamins**: A, C, D, E, K, B1-B12, Folate, Biotin
- **Minerals**: Calcium, Iron, Magnesium, Phosphorus, Potassium, Sodium, Zinc, Copper, Manganese, Selenium, Chromium, Molybdenum, Iodine
- **Other**: Water, Caffeine
- **Specialized**: Creatine, Taurine, Beta-Alanine, L-Carnitine, Glutamine, BCAA
- **Amino Acids**: All 20 essential and non-essential amino acids

### Image
- Beautiful, cozy food photography
- HD quality (1K resolution)
- Compressed before upload

## Integration with App

When a user adds a recipe as a meal:
1. Recipe nutritional data is used to log the meal
2. All micronutrients are tracked
3. This enables accurate supplement recommendations

## Notes

- Recipes are generated with realistic nutritional values
- All nutrients are calculated based on actual ingredients
- Images are optimized for web (compressed, HD)
- Recipes can be featured, saved, and tracked

