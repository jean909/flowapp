-- ============================================
-- UPDATE SCRIPT: DIETS AND PROGRAMS ENHANCEMENT
-- Adds micronutrients, vitamins, and special categories
-- Run this script in Supabase SQL Editor
-- ============================================

-- 1. ADD NEW COLUMNS TO DIETS TABLE
ALTER TABLE diets 
ADD COLUMN IF NOT EXISTS micronutrient_targets JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS vitamin_targets JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS category TEXT CHECK (category IN ('GENERAL', 'PREGNANCY', 'FERTILITY', 'POSTPARTUM', 'MENOPAUSE', 'DIABETES', 'HEART_HEALTH', 'IMMUNE_BOOST')) DEFAULT 'GENERAL',
ADD COLUMN IF NOT EXISTS special_considerations JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS recommended_supplements JSONB DEFAULT '[]'::jsonb;

-- 2. ADD NEW COLUMNS TO FITNESS_PROGRAMS TABLE
ALTER TABLE fitness_programs
ADD COLUMN IF NOT EXISTS category TEXT CHECK (category IN ('GENERAL', 'PREGNANCY', 'POSTPARTUM', 'FERTILITY', 'SENIOR', 'REHABILITATION', 'STRENGTH', 'CARDIO', 'FLEXIBILITY')) DEFAULT 'GENERAL',
ADD COLUMN IF NOT EXISTS special_considerations JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS intensity_level TEXT CHECK (intensity_level IN ('LOW', 'MODERATE', 'HIGH', 'VARIABLE')) DEFAULT 'MODERATE',
ADD COLUMN IF NOT EXISTS equipment_needed JSONB DEFAULT '[]'::jsonb;

-- 3. DELETE OLD SEED DATA (if exists)
DELETE FROM diets WHERE name_en IN ('Keto Diet', 'Mediterranean Diet', 'Vegan Diet', 'High Protein Diet', 'Low Carb Diet');
DELETE FROM fitness_programs WHERE name_en IN ('Push Pull Legs', 'Full Body', 'Upper Lower', 'Cardio Focus', 'Strength Building');

-- 4. INSERT COMPREHENSIVE DIETS WITH MICRONUTRIENTS
INSERT INTO diets (name_en, name_de, description_en, description_de, macro_ratios, difficulty, duration_weeks, daily_calorie_adjustment, category, micronutrient_targets, vitamin_targets, special_considerations, recommended_supplements) VALUES

-- General Health Diets
('Mediterranean Diet', 'Mittelmeer-Diät', 'Heart-healthy diet rich in fruits, vegetables, whole grains, and healthy fats. Supports cardiovascular health and provides essential nutrients.', 'Herzgesunde Diät reich an Obst, Gemüse, Vollkornprodukten und gesunden Fetten. Unterstützt die Herzgesundheit und liefert essentielle Nährstoffe.', '{"protein_percentage": 20, "carbs_percentage": 45, "fat_percentage": 35}'::jsonb, 'BEGINNER', 12, 0, 'HEART_HEALTH', '{"iron": 18, "calcium": 1000, "magnesium": 400, "zinc": 11, "potassium": 3500}'::jsonb, '{"vitamin_c": 90, "vitamin_d": 20, "vitamin_e": 15, "folate": 400, "vitamin_b12": 2.4}'::jsonb, '["Rich in omega-3 from fish", "High in antioxidants", "Supports brain health"]'::jsonb, '["Omega-3 (if not eating fish regularly)", "Vitamin D (if limited sun exposure)"]'::jsonb),

('High Protein Diet', 'Hochprotein-Diät', 'Focus on protein-rich foods to support muscle building and satiety. Ideal for active individuals and muscle maintenance.', 'Fokus auf proteinreiche Lebensmittel zur Unterstützung des Muskelaufbaus und der Sättigung. Ideal für aktive Personen und Muskelaufbau.', '{"protein_percentage": 40, "carbs_percentage": 30, "fat_percentage": 30}'::jsonb, 'BEGINNER', 8, 0, 'GENERAL', '{"iron": 18, "calcium": 1000, "zinc": 11, "magnesium": 400}'::jsonb, '{"vitamin_b12": 2.4, "vitamin_d": 20, "vitamin_b6": 1.7}'::jsonb, '["Supports muscle recovery", "High satiety", "May require more water intake"]'::jsonb, '["B-complex vitamins", "Magnesium for muscle function"]'::jsonb),

('Plant-Based Power', 'Pflanzenbasierte Kraft', 'Complete plant-based nutrition focusing on whole foods, legumes, and nutrient-dense vegetables. Ensures all essential vitamins and minerals.', 'Vollständige pflanzenbasierte Ernährung mit Fokus auf Vollwertkost, Hülsenfrüchte und nährstoffreiches Gemüse. Sichert alle essentiellen Vitamine und Mineralien.', '{"protein_percentage": 15, "carbs_percentage": 60, "fat_percentage": 25}'::jsonb, 'BEGINNER', 12, 0, 'GENERAL', '{"iron": 18, "calcium": 1000, "zinc": 11, "magnesium": 400}'::jsonb, '{"vitamin_b12": 2.4, "vitamin_d": 20, "folate": 400, "vitamin_c": 90}'::jsonb, '["Must combine plant proteins", "Focus on iron absorption with vitamin C", "B12 supplementation essential"]'::jsonb, '["Vitamin B12 (essential)", "Vitamin D", "Iron (if needed)", "Omega-3 (algae-based)"]'::jsonb),

-- Pregnancy Diets
('Pregnancy Nutrition Plan', 'Schwangerschafts-Ernährungsplan', 'Comprehensive nutrition plan designed for expecting mothers. Ensures adequate intake of folate, iron, calcium, and other critical nutrients for healthy fetal development.', 'Umfassender Ernährungsplan für werdende Mütter. Sichert ausreichende Aufnahme von Folsäure, Eisen, Calcium und anderen kritischen Nährstoffen für gesunde fetale Entwicklung.', '{"protein_percentage": 25, "carbs_percentage": 45, "fat_percentage": 30}'::jsonb, 'BEGINNER', 40, 300, 'PREGNANCY', '{"iron": 27, "calcium": 1300, "magnesium": 400, "zinc": 11, "iodine": 220}'::jsonb, '{"folate": 600, "vitamin_d": 20, "vitamin_c": 85, "vitamin_b12": 2.6, "choline": 450}'::jsonb, '["Avoid raw fish and unpasteurized foods", "Small frequent meals recommended", "Stay hydrated", "Monitor iron levels"]'::jsonb, '["Prenatal multivitamin (with folate)", "Iron supplement (if needed)", "DHA/Omega-3 for brain development", "Vitamin D"]'::jsonb),

('Fertility Boost Diet', 'Fruchtbarkeits-Diät', 'Nutrition plan optimized for fertility and reproductive health. Rich in antioxidants, healthy fats, and fertility-supporting nutrients.', 'Ernährungsplan optimiert für Fruchtbarkeit und reproduktive Gesundheit. Reich an Antioxidantien, gesunden Fetten und fruchtbarkeitsfördernden Nährstoffen.', '{"protein_percentage": 20, "carbs_percentage": 45, "fat_percentage": 35}'::jsonb, 'BEGINNER', 12, 0, 'FERTILITY', '{"iron": 18, "zinc": 11, "selenium": 55, "magnesium": 400}'::jsonb, '{"folate": 400, "vitamin_d": 20, "vitamin_e": 15, "vitamin_c": 90, "coenzyme_q10": 200}'::jsonb, '["Focus on whole foods", "Limit processed foods", "Include healthy fats daily", "Support hormonal balance"]'::jsonb, '["Folate/Folic acid", "Vitamin D", "Omega-3", "CoQ10", "Antioxidant complex"]'::jsonb),

-- Postpartum
('Postpartum Recovery', 'Postpartale Erholung', 'Nutrition plan for new mothers focusing on recovery, energy, and breastfeeding support. High in iron, calcium, and B-vitamins.', 'Ernährungsplan für neue Mütter mit Fokus auf Erholung, Energie und Stillunterstützung. Reich an Eisen, Calcium und B-Vitaminen.', '{"protein_percentage": 25, "carbs_percentage": 45, "fat_percentage": 30}'::jsonb, 'BEGINNER', 12, 500, 'POSTPARTUM', '{"iron": 15, "calcium": 1300, "zinc": 12, "magnesium": 400}'::jsonb, '{"vitamin_d": 20, "vitamin_b12": 2.8, "folate": 500, "vitamin_c": 120}'::jsonb, '["Support breastfeeding with extra calories", "Focus on iron-rich foods", "Stay hydrated", "Small frequent meals"]'::jsonb, '["Postnatal multivitamin", "Iron (if needed)", "DHA for breastfeeding", "Calcium supplement"]'::jsonb),

-- Immune Support
('Immune Boost Plan', 'Immunsystem-Stärkung', 'Diet rich in immune-supporting nutrients including vitamin C, zinc, vitamin D, and antioxidants. Designed to strengthen natural defenses.', 'Diät reich an immunstärkenden Nährstoffen wie Vitamin C, Zink, Vitamin D und Antioxidantien. Entwickelt zur Stärkung der natürlichen Abwehrkräfte.', '{"protein_percentage": 25, "carbs_percentage": 40, "fat_percentage": 35}'::jsonb, 'BEGINNER', 8, 0, 'IMMUNE_BOOST', '{"zinc": 11, "selenium": 55, "iron": 18, "magnesium": 400}'::jsonb, '{"vitamin_c": 200, "vitamin_d": 20, "vitamin_e": 15, "vitamin_a": 900, "vitamin_b6": 1.7}'::jsonb, '["Emphasize colorful fruits and vegetables", "Include probiotic foods", "Limit sugar and processed foods", "Stay well-hydrated"]'::jsonb, '["Vitamin C", "Vitamin D", "Zinc", "Probiotics", "Elderberry extract"]'::jsonb),

-- Heart Health
('Heart Health Focus', 'Herzgesundheit-Fokus', 'Low sodium, high fiber diet with emphasis on omega-3 fatty acids and antioxidants. Supports cardiovascular health and blood pressure management.', 'Natriumarme, ballaststoffreiche Diät mit Schwerpunkt auf Omega-3-Fettsäuren und Antioxidantien. Unterstützt Herzgesundheit und Blutdruckmanagement.', '{"protein_percentage": 20, "carbs_percentage": 50, "fat_percentage": 30}'::jsonb, 'BEGINNER', 12, 0, 'HEART_HEALTH', '{"potassium": 4700, "magnesium": 400, "calcium": 1000}'::jsonb, '{"vitamin_d": 20, "vitamin_e": 15, "folate": 400, "vitamin_b6": 1.7}'::jsonb, '["Limit sodium to <2300mg", "Focus on whole grains", "Include fatty fish 2x/week", "Limit saturated fats"]'::jsonb, '["Omega-3", "CoQ10", "Magnesium", "Vitamin D"]'::jsonb);

-- 5. INSERT COMPREHENSIVE FITNESS PROGRAMS
INSERT INTO fitness_programs (name_en, name_de, description_en, description_de, difficulty, duration_weeks, days_per_week, category, intensity_level, equipment_needed, special_considerations, workout_schedule) VALUES

-- General Programs
('Push Pull Legs', 'Push Pull Beine', '6-day split focusing on pushing, pulling, and leg movements for balanced muscle development. Includes progressive overload and recovery days.', '6-Tage-Split mit Fokus auf Drücken, Ziehen und Beinbewegungen für ausgewogene Muskelentwicklung. Enthält progressive Überlastung und Erholungstage.', 'INTERMEDIATE', 12, 6, 'STRENGTH', 'HIGH', '["Dumbbells", "Barbell", "Resistance bands", "Bench"]'::jsonb, '["Rest 48h between same muscle groups", "Focus on form over weight", "Include warm-up and cool-down"]'::jsonb, '[]'::jsonb),

('Full Body Foundation', 'Ganzkörper-Grundlage', '3-day full body workout program perfect for beginners or those with limited time. Builds strength, endurance, and mobility.', '3-Tage-Ganzkörpertraining perfekt für Anfänger oder Personen mit begrenzter Zeit. Baut Kraft, Ausdauer und Mobilität auf.', 'BEGINNER', 8, 3, 'GENERAL', 'MODERATE', '["Dumbbells", "Resistance bands", "Yoga mat"]'::jsonb, '["Perfect for beginners", "Can be done at home", "Focus on proper form", "Rest 1 day between sessions"]'::jsonb, '[]'::jsonb),

('Cardio & Endurance', 'Cardio & Ausdauer', '5-day program emphasizing cardiovascular health and endurance. Mix of HIIT, steady-state cardio, and active recovery.', '5-Tage-Programm mit Schwerpunkt auf Herz-Kreislauf-Gesundheit und Ausdauer. Mix aus HIIT, Ausdauertraining und aktiver Erholung.', 'BEGINNER', 8, 5, 'CARDIO', 'MODERATE', '["None", "Optional: Jump rope", "Optional: Running shoes"]'::jsonb, '["Great for weight loss", "Improves heart health", "Can be done anywhere", "Listen to your body"]'::jsonb, '[]'::jsonb),

-- Pregnancy Programs
('Pregnancy Safe Fitness', 'Schwangerschaftssicheres Training', 'Gentle, safe exercise program designed for expecting mothers. Focuses on maintaining strength, flexibility, and cardiovascular health throughout pregnancy.', 'Sanftes, sicheres Trainingsprogramm für werdende Mütter. Fokus auf Erhaltung von Kraft, Flexibilität und Herzgesundheit während der Schwangerschaft.', 'BEGINNER', 40, 3, 'PREGNANCY', 'LOW', '["Yoga mat", "Resistance bands", "Light dumbbells (optional)"]'::jsonb, '["Avoid exercises on back after 1st trimester", "Stay hydrated", "Listen to your body", "Avoid high-impact activities", "Consult healthcare provider"]'::jsonb, '[]'::jsonb),

('Prenatal Yoga & Strength', 'Pränatales Yoga & Kraft', 'Combines gentle yoga poses with light strength training. Supports posture, reduces back pain, and prepares body for labor.', 'Kombiniert sanfte Yoga-Posen mit leichtem Krafttraining. Unterstützt Haltung, reduziert Rückenschmerzen und bereitet den Körper auf die Geburt vor.', 'BEGINNER', 40, 4, 'PREGNANCY', 'LOW', '["Yoga mat", "Yoga blocks", "Resistance bands"]'::jsonb, '["Modify poses as needed", "Focus on breathing", "Avoid deep twists", "Support belly with props"]'::jsonb, '[]'::jsonb),

-- Postpartum Programs
('Postpartum Recovery', 'Postpartale Erholung', 'Gradual return to fitness after childbirth. Focuses on core restoration, pelvic floor health, and rebuilding strength safely.', 'Schrittweise Rückkehr zum Fitness nach der Geburt. Fokus auf Core-Wiederherstellung, Beckenbodengesundheit und sicherem Kraftaufbau.', 'BEGINNER', 12, 3, 'POSTPARTUM', 'LOW', '["Yoga mat", "Resistance bands", "Light weights"]'::jsonb, '["Wait for medical clearance (usually 6 weeks)", "Start very gently", "Focus on core and pelvic floor", "Listen to your body", "Avoid high-impact initially"]'::jsonb, '[]'::jsonb),

-- Fertility Programs
('Fertility Flow', 'Fruchtbarkeits-Flow', 'Moderate exercise program designed to support reproductive health. Balances strength, flexibility, and stress reduction.', 'Moderates Trainingsprogramm zur Unterstützung der reproduktiven Gesundheit. Balanciert Kraft, Flexibilität und Stressreduktion.', 'BEGINNER', 12, 4, 'FERTILITY', 'MODERATE', '["Yoga mat", "Resistance bands", "Light dumbbells"]'::jsonb, '["Avoid overtraining", "Include stress-reducing activities", "Focus on moderate intensity", "Support hormonal balance"]'::jsonb, '[]'::jsonb),

-- Flexibility & Mobility
('Flexibility & Mobility', 'Flexibilität & Mobilität', 'Daily stretching and mobility program to improve flexibility, reduce stiffness, and prevent injury. Perfect for all fitness levels.', 'Tägliches Dehnungs- und Mobilitätsprogramm zur Verbesserung der Flexibilität, Reduzierung von Steifheit und Verletzungsprävention. Perfekt für alle Fitnesslevel.', 'BEGINNER', 8, 7, 'FLEXIBILITY', 'LOW', '["Yoga mat", "Foam roller", "Stretching strap"]'::jsonb, '["Can be done daily", "Great for recovery", "Improves posture", "Reduces injury risk"]'::jsonb, '[]'::jsonb);

-- ============================================
-- VERIFICATION QUERIES (Optional - run to verify)
-- ============================================

-- Check diets with new columns
-- SELECT name_en, category, micronutrient_targets, vitamin_targets FROM diets LIMIT 5;

-- Check programs with new columns
-- SELECT name_en, category, intensity_level, equipment_needed FROM fitness_programs LIMIT 5;

-- Count by category
-- SELECT category, COUNT(*) FROM diets GROUP BY category;
-- SELECT category, COUNT(*) FROM fitness_programs GROUP BY category;

