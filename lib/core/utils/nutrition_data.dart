import 'package:flutter/material.dart';
import 'package:flow/l10n/app_localizations.dart';

class NutrientMeta {
  final String key;
  final String name;
  final String unit;
  final String category;
  final String description;
  final IconData icon;

  const NutrientMeta({
    required this.key,
    required this.name,
    required this.unit,
    required this.category,
    required this.description,
    this.icon = Icons.circle,
  });

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return name;
    switch (key) {
      case 'protein':
        return l10n.nutrient_protein;
      case 'carbs':
        return l10n.nutrient_carbs;
      case 'fat':
        return l10n.nutrient_fat;
      case 'fiber':
        return l10n.nutrient_fiber;
      case 'sugar':
        return l10n.nutrient_sugar;
      case 'omega3':
        return l10n.nutrient_omega3;
      case 'saturated_fat':
        return l10n.nutrient_saturated_fat;
      case 'vitamin_c':
        return l10n.nutrient_vitamin_c;
      case 'vitamin_d':
        return l10n.nutrient_vitamin_d;
      case 'vitamin_b12':
        return l10n.nutrient_vitamin_b12;
      case 'calcium':
        return l10n.nutrient_calcium;
      case 'iron':
        return l10n.nutrient_iron;
      case 'magnesium':
        return l10n.nutrient_magnesium;
      case 'potassium':
        return l10n.nutrient_potassium;
      case 'zinc':
        return l10n.nutrient_zinc;
      case 'caffeine':
        return l10n.nutrient_caffeine;
      default:
        return name;
    }
  }

  String getLocalizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return description;
    switch (key) {
      case 'protein':
        return l10n.nutrient_protein_desc;
      case 'carbs':
        return l10n.nutrient_carbs_desc;
      case 'fat':
        return l10n.nutrient_fat_desc;
      case 'fiber':
        return l10n.nutrient_fiber_desc;
      case 'sugar':
        return l10n.nutrient_sugar_desc;
      case 'omega3':
        return l10n.nutrient_omega3_desc;
      case 'saturated_fat':
        return l10n.nutrient_saturated_fat_desc;
      case 'vitamin_c':
        return l10n.nutrient_vitamin_c_desc;
      case 'vitamin_d':
        return l10n.nutrient_vitamin_d_desc;
      case 'vitamin_b12':
        return l10n.nutrient_vitamin_b12_desc;
      case 'calcium':
        return l10n.nutrient_calcium_desc;
      case 'iron':
        return l10n.nutrient_iron_desc;
      case 'magnesium':
        return l10n.nutrient_magnesium_desc;
      case 'potassium':
        return l10n.nutrient_potassium_desc;
      case 'zinc':
        return l10n.nutrient_zinc_desc;
      case 'caffeine':
        return l10n.nutrient_caffeine_desc;
      default:
        return description;
    }
  }
}

class NutritionData {
  static String getLocalizedCategory(BuildContext context, String cat) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return cat;
    switch (cat) {
      case 'Macronutrients':
        return l10n.cat_macro;
      case 'Essential Fats':
        return l10n.cat_essential_fats;
      case 'Vitamins':
        return l10n.cat_vitamins;
      case 'Minerals':
        return l10n.cat_minerals;
      case 'Others':
        return l10n.cat_others;
      default:
        return cat;
    }
  }

  static const List<NutrientMeta> nutrients = [
    // Macros
    NutrientMeta(
      key: 'protein',
      name: 'Protein',
      unit: 'g',
      category: 'Macronutrients',
      description: 'The building blocks of muscle and tissue.',
      icon: Icons.fitness_center,
    ),
    NutrientMeta(
      key: 'carbs',
      name: 'Carbohydrates',
      unit: 'g',
      category: 'Macronutrients',
      description: 'Your body\'s primary energy source.',
      icon: Icons.bolt,
    ),
    NutrientMeta(
      key: 'fat',
      name: 'Fat',
      unit: 'g',
      category: 'Macronutrients',
      description: 'Essential for hormone production and brain health.',
      icon: Icons.opacity,
    ),
    NutrientMeta(
      key: 'fiber',
      name: 'Fiber',
      unit: 'g',
      category: 'Macronutrients',
      description: 'Crucial for digestion and heart health.',
      icon: Icons.grass,
    ),
    NutrientMeta(
      key: 'sugar',
      name: 'Sugar',
      unit: 'g',
      category: 'Macronutrients',
      description: 'Simple carbohydrates that provide quick energy.',
    ),

    // Essential Fats
    NutrientMeta(
      key: 'omega3',
      name: 'Omega-3',
      unit: 'g',
      category: 'Essential Fats',
      description: 'Heart and brain health hero. Reduces inflammation.',
      icon: Icons.set_meal,
    ),
    NutrientMeta(
      key: 'saturated_fat',
      name: 'Saturated Fat',
      unit: 'g',
      category: 'Essential Fats',
      description: 'Found in animal products. Maintain in moderation.',
    ),

    // Essential Fats
    NutrientMeta(
      key: 'omega6',
      name: 'Omega-6',
      unit: 'g',
      category: 'Essential Fats',
      description: 'Essential fatty acid for brain function.',
      icon: Icons.set_meal,
    ),

    // Vitamins - All
    NutrientMeta(
      key: 'vitamin_a',
      name: 'Vitamin A',
      unit: 'μg',
      category: 'Vitamins',
      description: 'Vision, immune function, and cell growth.',
      icon: Icons.visibility,
    ),
    NutrientMeta(
      key: 'vitamin_c',
      name: 'Vitamin C',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Immune support and skin health.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'vitamin_d',
      name: 'Vitamin D',
      unit: 'μg',
      category: 'Vitamins',
      description: 'The "sunshine vitamin" for bone health and mood.',
      icon: Icons.wb_sunny,
    ),
    NutrientMeta(
      key: 'vitamin_e',
      name: 'Vitamin E',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Antioxidant that protects cells from damage.',
      icon: Icons.shield,
    ),
    NutrientMeta(
      key: 'vitamin_k',
      name: 'Vitamin K',
      unit: 'μg',
      category: 'Vitamins',
      description: 'Essential for blood clotting and bone health.',
      icon: Icons.bloodtype,
    ),
    NutrientMeta(
      key: 'vitamin_b1_thiamine',
      name: 'Vitamin B1 (Thiamine)',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Energy metabolism and nerve function.',
      icon: Icons.bolt,
    ),
    NutrientMeta(
      key: 'vitamin_b2_riboflavin',
      name: 'Vitamin B2 (Riboflavin)',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Energy production and cell growth.',
      icon: Icons.energy_savings_leaf,
    ),
    NutrientMeta(
      key: 'vitamin_b3_niacin',
      name: 'Vitamin B3 (Niacin)',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Cholesterol management and energy metabolism.',
      icon: Icons.trending_up,
    ),
    NutrientMeta(
      key: 'vitamin_b5_pantothenic_acid',
      name: 'Vitamin B5 (Pantothenic Acid)',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Hormone and cholesterol production.',
      icon: Icons.science,
    ),
    NutrientMeta(
      key: 'vitamin_b6',
      name: 'Vitamin B6',
      unit: 'mg',
      category: 'Vitamins',
      description: 'Brain development and immune function.',
      icon: Icons.psychology,
    ),
    NutrientMeta(
      key: 'vitamin_b7_biotin',
      name: 'Vitamin B7 (Biotin)',
      unit: 'μg',
      category: 'Vitamins',
      description: 'Hair, skin, and nail health.',
      icon: Icons.face,
    ),
    NutrientMeta(
      key: 'vitamin_b9_folate',
      name: 'Vitamin B9 (Folate)',
      unit: 'μg',
      category: 'Vitamins',
      description: 'DNA synthesis and cell division.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'vitamin_b12',
      name: 'Vitamin B12',
      unit: 'μg',
      category: 'Vitamins',
      description: 'Vital for nerve function and blood cells.',
      icon: Icons.bloodtype,
    ),

    // Minerals - All
    NutrientMeta(
      key: 'calcium',
      name: 'Calcium',
      unit: 'mg',
      category: 'Minerals',
      description: 'Strong bones and teeth.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'iron',
      name: 'Iron',
      unit: 'mg',
      category: 'Minerals',
      description: 'Carries oxygen through your blood.',
      icon: Icons.bloodtype,
    ),
    NutrientMeta(
      key: 'magnesium',
      name: 'Magnesium',
      unit: 'mg',
      category: 'Minerals',
      description: 'Over 300 biochemical reactions in the body.',
      icon: Icons.science,
    ),
    NutrientMeta(
      key: 'phosphorus',
      name: 'Phosphorus',
      unit: 'mg',
      category: 'Minerals',
      description: 'Bone health and energy storage.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'potassium',
      name: 'Potassium',
      unit: 'mg',
      category: 'Minerals',
      description: 'Proper heart and muscle function.',
      icon: Icons.favorite,
    ),
    NutrientMeta(
      key: 'sodium',
      name: 'Sodium',
      unit: 'mg',
      category: 'Minerals',
      description: 'Fluid balance and nerve function.',
      icon: Icons.water_drop,
    ),
    NutrientMeta(
      key: 'zinc',
      name: 'Zinc',
      unit: 'mg',
      category: 'Minerals',
      description: 'Immunity and cell growth.',
      icon: Icons.shield,
    ),
    NutrientMeta(
      key: 'copper',
      name: 'Copper',
      unit: 'mg',
      category: 'Minerals',
      description: 'Iron absorption and energy production.',
      icon: Icons.energy_savings_leaf,
    ),
    NutrientMeta(
      key: 'manganese',
      name: 'Manganese',
      unit: 'mg',
      category: 'Minerals',
      description: 'Bone formation and antioxidant function.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'selenium',
      name: 'Selenium',
      unit: 'μg',
      category: 'Minerals',
      description: 'Antioxidant and thyroid function.',
      icon: Icons.shield,
    ),
    NutrientMeta(
      key: 'chromium',
      name: 'Chromium',
      unit: 'μg',
      category: 'Minerals',
      description: 'Blood sugar regulation and metabolism.',
      icon: Icons.trending_up,
    ),
    NutrientMeta(
      key: 'molybdenum',
      name: 'Molybdenum',
      unit: 'μg',
      category: 'Minerals',
      description: 'Enzyme function and amino acid processing.',
      icon: Icons.science,
    ),
    NutrientMeta(
      key: 'iodine',
      name: 'Iodine',
      unit: 'μg',
      category: 'Minerals',
      description: 'Thyroid hormone production.',
      icon: Icons.health_and_safety,
    ),

    // Other Nutrients
    NutrientMeta(
      key: 'water',
      name: 'Water',
      unit: 'ml',
      category: 'Others',
      description: 'Essential for all bodily functions.',
      icon: Icons.water_drop,
    ),
    NutrientMeta(
      key: 'caffeine',
      name: 'Caffeine',
      unit: 'mg',
      category: 'Others',
      description: 'Stimulant found in coffee and tea.',
      icon: Icons.coffee,
    ),

    // Specialized Nutrients
    NutrientMeta(
      key: 'creatine',
      name: 'Creatine',
      unit: 'g',
      category: 'Specialized',
      description: 'Muscle energy and strength support.',
      icon: Icons.fitness_center,
    ),
    NutrientMeta(
      key: 'taurine',
      name: 'Taurine',
      unit: 'g',
      category: 'Specialized',
      description: 'Heart function and antioxidant.',
      icon: Icons.favorite,
    ),
    NutrientMeta(
      key: 'beta_alanine',
      name: 'Beta-Alanine',
      unit: 'g',
      category: 'Specialized',
      description: 'Muscle endurance and performance.',
      icon: Icons.sports,
    ),
    NutrientMeta(
      key: 'l_carnitine',
      name: 'L-Carnitine',
      unit: 'g',
      category: 'Specialized',
      description: 'Fat metabolism and energy production.',
      icon: Icons.energy_savings_leaf,
    ),
    NutrientMeta(
      key: 'glutamine',
      name: 'Glutamine',
      unit: 'g',
      category: 'Specialized',
      description: 'Muscle recovery and immune support.',
      icon: Icons.healing,
    ),
    NutrientMeta(
      key: 'bcaa',
      name: 'BCAA',
      unit: 'g',
      category: 'Specialized',
      description: 'Branched-chain amino acids for muscle growth.',
      icon: Icons.fitness_center,
    ),

    // Essential Amino Acids
    NutrientMeta(
      key: 'leucine',
      name: 'Leucine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Muscle protein synthesis trigger.',
      icon: Icons.fitness_center,
    ),
    NutrientMeta(
      key: 'isoleucine',
      name: 'Isoleucine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Muscle metabolism and energy.',
      icon: Icons.bolt,
    ),
    NutrientMeta(
      key: 'valine',
      name: 'Valine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Muscle growth and repair.',
      icon: Icons.healing,
    ),
    NutrientMeta(
      key: 'lysine',
      name: 'Lysine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Collagen formation and immune function.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'methionine',
      name: 'Methionine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Protein synthesis and detoxification.',
      icon: Icons.science,
    ),
    NutrientMeta(
      key: 'phenylalanine',
      name: 'Phenylalanine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Neurotransmitter production.',
      icon: Icons.psychology,
    ),
    NutrientMeta(
      key: 'threonine',
      name: 'Threonine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Collagen and elastin production.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'tryptophan',
      name: 'Tryptophan',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Serotonin and melatonin production.',
      icon: Icons.bedtime,
    ),
    NutrientMeta(
      key: 'histidine',
      name: 'Histidine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Histamine production and immune response.',
      icon: Icons.shield,
    ),

    // Non-essential Amino Acids
    NutrientMeta(
      key: 'arginine',
      name: 'Arginine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Blood flow and immune function.',
      icon: Icons.favorite,
    ),
    NutrientMeta(
      key: 'tyrosine',
      name: 'Tyrosine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Neurotransmitter and hormone production.',
      icon: Icons.psychology,
    ),
    NutrientMeta(
      key: 'cysteine',
      name: 'Cysteine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Antioxidant and protein structure.',
      icon: Icons.shield,
    ),
    NutrientMeta(
      key: 'alanine',
      name: 'Alanine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Energy production and glucose metabolism.',
      icon: Icons.bolt,
    ),
    NutrientMeta(
      key: 'aspartic_acid',
      name: 'Aspartic Acid',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Neurotransmitter and energy production.',
      icon: Icons.psychology,
    ),
    NutrientMeta(
      key: 'glutamic_acid',
      name: 'Glutamic Acid',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Brain function and protein synthesis.',
      icon: Icons.psychology,
    ),
    NutrientMeta(
      key: 'serine',
      name: 'Serine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Protein and DNA synthesis.',
      icon: Icons.science,
    ),
    NutrientMeta(
      key: 'proline',
      name: 'Proline',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Collagen formation and joint health.',
      icon: Icons.health_and_safety,
    ),
    NutrientMeta(
      key: 'glycine',
      name: 'Glycine',
      unit: 'g',
      category: 'Amino Acids',
      description: 'Collagen, creatine, and neurotransmitter production.',
      icon: Icons.science,
    ),
  ];

  static Map<String, NutrientMeta> get metaMap => {
    for (var n in nutrients) n.key: n,
  };
}
