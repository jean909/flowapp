-- ==========================================
-- RECIPES SYSTEM
-- ==========================================

-- Recipes table - stores AI-generated and user-created recipes
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_en TEXT NOT NULL,
    title_de TEXT NOT NULL,
    description_en TEXT,
    description_de TEXT,
    
    -- Recipe metadata
    prep_time_minutes INTEGER NOT NULL,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER NOT NULL,
    servings INTEGER DEFAULT 1,
    
    -- Meal type and diet
    recommended_meal_type TEXT CHECK (recommended_meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
    diet_type TEXT, -- 'vegetarian', 'vegan', 'pescetarian', 'keto', 'paleo', 'gluten-free', etc.
    cuisine_type TEXT, -- 'Italian', 'French', 'Spanish', 'Greek', 'German', 'British', etc.
    
    -- Ingredients (stored as JSONB for flexibility)
    ingredients JSONB NOT NULL, -- Array of {name_en, name_de, amount, unit}
    
    -- Instructions (stored as JSONB - array of steps)
    instructions_en JSONB NOT NULL, -- Array of instruction strings
    instructions_de JSONB NOT NULL, -- Array of instruction strings
    
    -- Nutritional data per serving (per 100g equivalent for consistency)
    -- Macronutrients
    calories DECIMAL(10,2) NOT NULL,
    protein DECIMAL(10,2) NOT NULL,
    carbs DECIMAL(10,2) NOT NULL,
    fat DECIMAL(10,2) NOT NULL,
    fiber DECIMAL(10,2) DEFAULT 0,
    sugar DECIMAL(10,2) DEFAULT 0,
    saturated_fat DECIMAL(10,2) DEFAULT 0,
    
    -- Essential Fats
    omega3 DECIMAL(10,2) DEFAULT 0,
    omega6 DECIMAL(10,2) DEFAULT 0,
    
    -- Vitamins
    vitamin_a DECIMAL(10,2) DEFAULT 0, -- μg
    vitamin_c DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_d DECIMAL(10,2) DEFAULT 0, -- μg
    vitamin_e DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_k DECIMAL(10,2) DEFAULT 0, -- μg
    vitamin_b1_thiamine DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_b2_riboflavin DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_b3_niacin DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_b5_pantothenic_acid DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_b6 DECIMAL(10,2) DEFAULT 0, -- mg
    vitamin_b7_biotin DECIMAL(10,2) DEFAULT 0, -- μg
    vitamin_b9_folate DECIMAL(10,2) DEFAULT 0, -- μg
    vitamin_b12 DECIMAL(10,2) DEFAULT 0, -- μg
    
    -- Minerals
    calcium DECIMAL(10,2) DEFAULT 0, -- mg
    iron DECIMAL(10,2) DEFAULT 0, -- mg
    magnesium DECIMAL(10,2) DEFAULT 0, -- mg
    phosphorus DECIMAL(10,2) DEFAULT 0, -- mg
    potassium DECIMAL(10,2) DEFAULT 0, -- mg
    sodium DECIMAL(10,2) DEFAULT 0, -- mg
    zinc DECIMAL(10,2) DEFAULT 0, -- mg
    copper DECIMAL(10,2) DEFAULT 0, -- mg
    manganese DECIMAL(10,2) DEFAULT 0, -- mg
    selenium DECIMAL(10,2) DEFAULT 0, -- μg
    chromium DECIMAL(10,2) DEFAULT 0, -- μg
    molybdenum DECIMAL(10,2) DEFAULT 0, -- μg
    iodine DECIMAL(10,2) DEFAULT 0, -- μg
    
    -- Other nutrients
    water DECIMAL(10,2) DEFAULT 0, -- g
    caffeine DECIMAL(10,2) DEFAULT 0, -- mg
    
    -- Specialized nutrients (for supplement tracking)
    creatine DECIMAL(10,2) DEFAULT 0, -- g
    taurine DECIMAL(10,2) DEFAULT 0, -- g
    beta_alanine DECIMAL(10,2) DEFAULT 0, -- g
    l_carnitine DECIMAL(10,2) DEFAULT 0, -- g
    glutamine DECIMAL(10,2) DEFAULT 0, -- g
    bcaa DECIMAL(10,2) DEFAULT 0, -- g
    
    -- Essential Amino Acids
    leucine DECIMAL(10,2) DEFAULT 0, -- g
    isoleucine DECIMAL(10,2) DEFAULT 0, -- g
    valine DECIMAL(10,2) DEFAULT 0, -- g
    lysine DECIMAL(10,2) DEFAULT 0, -- g
    methionine DECIMAL(10,2) DEFAULT 0, -- g
    phenylalanine DECIMAL(10,2) DEFAULT 0, -- g
    threonine DECIMAL(10,2) DEFAULT 0, -- g
    tryptophan DECIMAL(10,2) DEFAULT 0, -- g
    histidine DECIMAL(10,2) DEFAULT 0, -- g
    
    -- Non-essential Amino Acids
    arginine DECIMAL(10,2) DEFAULT 0, -- g
    tyrosine DECIMAL(10,2) DEFAULT 0, -- g
    cysteine DECIMAL(10,2) DEFAULT 0, -- g
    alanine DECIMAL(10,2) DEFAULT 0, -- g
    aspartic_acid DECIMAL(10,2) DEFAULT 0, -- g
    glutamic_acid DECIMAL(10,2) DEFAULT 0, -- g
    serine DECIMAL(10,2) DEFAULT 0, -- g
    proline DECIMAL(10,2) DEFAULT 0, -- g
    glycine DECIMAL(10,2) DEFAULT 0, -- g
    
    -- Image
    image_url TEXT,
    
    -- Source and metadata
    source TEXT DEFAULT 'ai_generated', -- 'ai_generated', 'user_created', 'community'
    created_by_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    is_featured BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT TRUE,
    
    -- Stats
    views_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    times_cooked INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipe tags for categorization
CREATE TABLE IF NOT EXISTS recipe_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
    tag TEXT NOT NULL, -- 'high-protein', 'low-carb', 'quick', 'budget-friendly', etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recipe_id, tag)
);

-- User saved recipes (favorites)
CREATE TABLE IF NOT EXISTS user_saved_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

-- Recipe cooking history (when user cooks a recipe)
CREATE TABLE IF NOT EXISTS recipe_cooking_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
    servings_cooked DECIMAL(5,2) DEFAULT 1.0,
    meal_type TEXT CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
    notes TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipe votes/ratings (1-5 stars)
CREATE TABLE IF NOT EXISTS recipe_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_recipes_meal_type ON recipes(recommended_meal_type);
CREATE INDEX IF NOT EXISTS idx_recipes_diet_type ON recipes(diet_type);
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine_type ON recipes(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_recipes_is_featured ON recipes(is_featured);
CREATE INDEX IF NOT EXISTS idx_recipes_is_public ON recipes(is_public);
CREATE INDEX IF NOT EXISTS idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_saved_recipes_user_id ON user_saved_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_cooking_logs_user_id ON recipe_cooking_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_votes_recipe_id ON recipe_votes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_votes_user_id ON recipe_votes(user_id);

-- Enable RLS
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_cooking_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_votes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for recipes
CREATE POLICY "Public recipes are viewable by everyone" 
ON recipes FOR SELECT 
USING (is_public = TRUE OR created_by_user_id = auth.uid());

CREATE POLICY "Users can create their own recipes" 
ON recipes FOR INSERT 
WITH CHECK (auth.uid() = created_by_user_id OR created_by_user_id IS NULL);

CREATE POLICY "Users can update their own recipes" 
ON recipes FOR UPDATE 
USING (created_by_user_id = auth.uid());

CREATE POLICY "Users can delete their own recipes" 
ON recipes FOR DELETE 
USING (created_by_user_id = auth.uid());

-- RLS Policies for recipe_tags
CREATE POLICY "Recipe tags are viewable with recipe" 
ON recipe_tags FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipes.id = recipe_tags.recipe_id 
        AND (recipes.is_public = TRUE OR recipes.created_by_user_id = auth.uid())
    )
);

CREATE POLICY "Users can manage tags for their recipes" 
ON recipe_tags FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipes.id = recipe_tags.recipe_id 
        AND recipes.created_by_user_id = auth.uid()
    )
);

-- RLS Policies for user_saved_recipes
CREATE POLICY "Users can view their saved recipes" 
ON user_saved_recipes FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can save recipes" 
ON user_saved_recipes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unsave recipes" 
ON user_saved_recipes FOR DELETE 
USING (auth.uid() = user_id);

-- RLS Policies for recipe_cooking_logs
CREATE POLICY "Users can view their cooking logs" 
ON recipe_cooking_logs FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can log recipe cooking" 
ON recipe_cooking_logs FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- RLS Policies for recipe_votes
CREATE POLICY "Users can view recipe votes" 
ON recipe_votes FOR SELECT 
USING (true);

CREATE POLICY "Users can vote on recipes" 
ON recipe_votes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their votes" 
ON recipe_votes FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their votes" 
ON recipe_votes FOR DELETE 
USING (auth.uid() = user_id);

-- Storage bucket for recipe images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('recipe_images', 'recipe_images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for recipe images
CREATE POLICY "Recipe images are publicly viewable" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'recipe_images');

CREATE POLICY "Authenticated users can upload recipe images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'recipe_images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete their own recipe images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'recipe_images' AND auth.uid()::text = (storage.foldername(name))[1]);

