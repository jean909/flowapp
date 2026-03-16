-- ============================================
-- ADDITIONAL NUTRIENT-BASED CHALLENGES
-- ============================================
-- These challenges are based on all the nutrients we now track
-- Run this after the base challenges are created

INSERT INTO challenges (title_en, title_de, description_en, description_de, goal_type, goal_value, reward_coins, difficulty, icon)
VALUES 
-- Calcium Challenges
('Calcium Champion', 'Kalzium-Champion', 'Reach 1000mg of calcium today for strong bones.', 'Erreiche heute 1000mg Kalzium für starke Knochen.', 'CALCIUM', 1000, 75, 'MEDIUM', '🦴'),
('Bone Builder', 'Knochen-Bauer', 'Get 1200mg of calcium daily for 3 days.', 'Erreiche 3 Tage lang täglich 1200mg Kalzium.', 'CALCIUM', 1200, 150, 'HARD', '💀'),

-- Iron Challenges
('Iron Warrior', 'Eisen-Krieger', 'Reach 18mg of iron today to prevent deficiency.', 'Erreiche heute 18mg Eisen, um Mangel vorzubeugen.', 'IRON', 18, 75, 'MEDIUM', '⚔️'),
('Iron Master', 'Eisen-Meister', 'Maintain 18mg iron daily for 5 days.', 'Halte 5 Tage lang täglich 18mg Eisen.', 'IRON', 18, 200, 'HARD', '🛡️'),

-- Vitamin D Challenges
('Sunshine Vitamin', 'Sonnenschein-Vitamin', 'Reach 20mcg (800 IU) of vitamin D today.', 'Erreiche heute 20mcg (800 IE) Vitamin D.', 'VITAMIN_D', 20, 100, 'MEDIUM', '☀️'),
('D-Fense Master', 'D-Fense-Meister', 'Get 20mcg vitamin D for 7 consecutive days.', 'Erreiche 7 Tage hintereinander 20mcg Vitamin D.', 'VITAMIN_D', 20, 250, 'HARD', '🌞'),

-- Vitamin C Challenges
('C-Boost', 'C-Boost', 'Reach 90mg of vitamin C today for immunity.', 'Erreiche heute 90mg Vitamin C für die Immunität.', 'VITAMIN_C', 90, 50, 'EASY', '🍊'),
('Immune Hero', 'Immun-Held', 'Get 100mg vitamin C daily for 5 days.', 'Erreiche 5 Tage lang täglich 100mg Vitamin C.', 'VITAMIN_C', 100, 150, 'MEDIUM', '🛡️'),

-- Magnesium Challenges
('Magnesium Master', 'Magnesium-Meister', 'Reach 400mg of magnesium today.', 'Erreiche heute 400mg Magnesium.', 'MAGNESIUM', 400, 75, 'MEDIUM', '⚡'),
('Relaxation Pro', 'Entspannungs-Profi', 'Get 420mg magnesium daily for 3 days.', 'Erreiche 3 Tage lang täglich 420mg Magnesium.', 'MAGNESIUM', 420, 125, 'MEDIUM', '🧘'),

-- Zinc Challenges
('Zinc Power', 'Zink-Power', 'Reach 11mg of zinc today for immune support.', 'Erreiche heute 11mg Zink für die Immununterstützung.', 'ZINC', 11, 75, 'MEDIUM', '⚡'),
('Zinc Warrior', 'Zink-Krieger', 'Maintain 11mg zinc daily for 4 days.', 'Halte 4 Tage lang täglich 11mg Zink.', 'ZINC', 11, 150, 'MEDIUM', '🛡️'),

-- Selenium Challenges
('Selenium Shield', 'Selen-Schild', 'Reach 55mcg of selenium today.', 'Erreiche heute 55mcg Selen.', 'SELENIUM', 55, 75, 'MEDIUM', '🛡️'),
('Antioxidant Master', 'Antioxidans-Meister', 'Get 60mcg selenium daily for 3 days.', 'Erreiche 3 Tage lang täglich 60mcg Selen.', 'SELENIUM', 60, 125, 'MEDIUM', '✨'),

-- Iodine Challenges
('Iodine Intake', 'Jod-Aufnahme', 'Reach 150mcg of iodine today for thyroid health.', 'Erreiche heute 150mcg Jod für die Schilddrüsengesundheit.', 'IODINE', 150, 75, 'MEDIUM', '🧠'),
('Thyroid Guardian', 'Schilddrüsen-Wächter', 'Maintain 150mcg iodine daily for 5 days.', 'Halte 5 Tage lang täglich 150mcg Jod.', 'IODINE', 150, 175, 'HARD', '⚕️'),

-- Chromium Challenges
('Chromium Control', 'Chrom-Kontrolle', 'Reach 35mcg of chromium today for blood sugar.', 'Erreiche heute 35mcg Chrom für den Blutzucker.', 'CHROMIUM', 35, 50, 'EASY', '📊'),
('Sugar Master', 'Zucker-Meister', 'Get 35mcg chromium daily for 4 days.', 'Erreiche 4 Tage lang täglich 35mcg Chrom.', 'CHROMIUM', 35, 100, 'MEDIUM', '🍯'),

-- Potassium Challenges
('Potassium Power', 'Kalium-Power', 'Reach 3500mg of potassium today.', 'Erreiche heute 3500mg Kalium.', 'POTASSIUM', 3500, 75, 'MEDIUM', '⚡'),
('Electrolyte Expert', 'Elektrolyt-Experte', 'Get 3500mg potassium daily for 3 days.', 'Erreiche 3 Tage lang täglich 3500mg Kalium.', 'POTASSIUM', 3500, 125, 'MEDIUM', '💧'),

-- Folate Challenges
('Folate Focus', 'Folsäure-Fokus', 'Reach 400mcg of folate today.', 'Erreiche heute 400mcg Folsäure.', 'FOLATE', 400, 75, 'MEDIUM', '🧬'),
('DNA Defender', 'DNA-Verteidiger', 'Get 400mcg folate daily for 4 days.', 'Erreiche 4 Tage lang täglich 400mcg Folsäure.', 'FOLATE', 400, 150, 'MEDIUM', '🔬'),

-- Vitamin B12 Challenges
('B12 Boost', 'B12-Boost', 'Reach 2.4mcg of vitamin B12 today.', 'Erreiche heute 2.4mcg Vitamin B12.', 'VITAMIN_B12', 2.4, 75, 'MEDIUM', '💊'),
('Energy Master', 'Energie-Meister', 'Get 2.4mcg B12 daily for 5 days.', 'Erreiche 5 Tage lang täglich 2.4mcg B12.', 'VITAMIN_B12', 2.4, 175, 'HARD', '⚡'),

-- Omega-3 Challenges
('Omega Ace', 'Omega-As', 'Reach 1.6g of omega-3 today.', 'Erreiche heute 1.6g Omega-3.', 'OMEGA3', 1.6, 100, 'MEDIUM', '🐟'),
('Brain Booster', 'Gehirn-Booster', 'Get 1.6g omega-3 daily for 3 days.', 'Erreiche 3 Tage lang täglich 1.6g Omega-3.', 'OMEGA3', 1.6, 200, 'HARD', '🧠'),

-- Fiber Challenges
('Fiber Fighter', 'Ballaststoff-Kämpfer', 'Reach 25g of fiber today.', 'Erreiche heute 25g Ballaststoffe.', 'FIBER', 25, 50, 'EASY', '🌾'),
('Digestive Pro', 'Verdauungs-Profi', 'Get 30g fiber daily for 3 days.', 'Erreiche 3 Tage lang täglich 30g Ballaststoffe.', 'FIBER', 30, 125, 'MEDIUM', '🌿'),

-- Amino Acids Challenges
('BCAA Builder', 'BCAA-Bauer', 'Reach 10g of BCAA today for muscle recovery.', 'Erreiche heute 10g BCAA für die Muskelregeneration.', 'BCAA', 10, 100, 'MEDIUM', '💪'),
('Leucine Leader', 'Leucin-Führer', 'Get 3g leucine today for muscle growth.', 'Erreiche heute 3g Leucin für das Muskelwachstum.', 'LEUCINE', 3, 75, 'MEDIUM', '🏋️'),
('Complete Protein', 'Vollständiges Protein', 'Reach 20g of complete protein with all essential amino acids.', 'Erreiche 20g vollständiges Protein mit allen essentiellen Aminosäuren.', 'PROTEIN', 20, 150, 'MEDIUM', '🥩'),

-- Specialized Nutrients
('Creatine Champion', 'Kreatin-Champion', 'Reach 3g of creatine today for performance.', 'Erreiche heute 3g Kreatin für die Leistung.', 'CREATINE', 3, 100, 'MEDIUM', '⚡'),
('Taurine Turbo', 'Taurin-Turbo', 'Get 500mg taurine today for energy.', 'Erreiche heute 500mg Taurin für Energie.', 'TAURINE', 0.5, 75, 'MEDIUM', '🚀'),

-- Combined Challenges
('Micronutrient Master', 'Mikronährstoff-Meister', 'Reach RDA for 10 different vitamins/minerals in one day.', 'Erreiche die RDA für 10 verschiedene Vitamine/Mineralien an einem Tag.', 'MICRONUTRIENT_COUNT', 10, 300, 'HARD', '🏆'),
('Perfect Day', 'Perfekter Tag', 'Reach all macro and micro RDAs in one day.', 'Erreiche alle Makro- und Mikro-RDAs an einem Tag.', 'PERFECT_DAY', 1, 500, 'HARD', '👑'),
('Week Warrior', 'Wochen-Krieger', 'Maintain perfect nutrition for 7 consecutive days.', 'Halte 7 Tage hintereinander eine perfekte Ernährung.', 'PERFECT_WEEK', 7, 1000, 'HARD', '👑');

