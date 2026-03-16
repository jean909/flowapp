class NutritionUtils {
  static Map<String, int> calculateTargets({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required String goal,
  }) {
    // 1. Calculate BMR (Mifflin-St Jeor Equation)
    double bmr;
    if (gender.toUpperCase() == 'MALE') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 2. Activity Multiplier
    double multiplier = 1.2;
    switch (activityLevel.toUpperCase()) {
      case 'SEDENTARY':
        multiplier = 1.2;
        break;
      case 'LIGHTLY ACTIVE':
        multiplier = 1.375;
        break;
      case 'MODERATELY ACTIVE':
        multiplier = 1.55;
        break;
      case 'VERY ACTIVE':
        multiplier = 1.725;
        break;
    }

    double tdee = bmr * multiplier;

    // 3. Adjust for Goal
    int calorieTarget;
    int proteinPct = 30;
    int carbsPct = 40;
    int fatPct = 30;

    switch (goal.toUpperCase()) {
      case 'LOSE':
        calorieTarget = (tdee - 500).toInt();
        proteinPct = 35; // Higher protein for muscle preservation
        carbsPct = 35;
        fatPct = 30;
        break;
      case 'GAIN':
        calorieTarget = (tdee + 300).toInt();
        proteinPct = 25;
        carbsPct = 45; // More carbs for energy
        fatPct = 30;
        break;
      case 'MAINTAIN':
      default:
        calorieTarget = tdee.toInt();
        break;
    }

    // Calculate fiber target based on gender and calorie intake
    // Recommended: 25g for women, 30-38g for men (or 14g per 1000 kcal)
    double fiberTarget;
    if (gender.toUpperCase() == 'FEMALE') {
      fiberTarget = 25.0;
    } else if (gender.toUpperCase() == 'MALE') {
      fiberTarget = 30.0;
    } else {
      fiberTarget = 27.5; // Average
    }
    // Adjust based on calorie intake (14g per 1000 kcal)
    fiberTarget = (calorieTarget / 1000.0) * 14.0;
    if (fiberTarget < 25.0) fiberTarget = 25.0; // Minimum
    if (fiberTarget > 38.0) fiberTarget = 38.0; // Maximum

    // Calculate sugar target
    // WHO recommends <50g per day (ideally <25g for added sugars)
    // We'll use 50g as the target limit (user should aim below this)
    double sugarTarget = 50.0;
    // For weight loss goals, recommend lower sugar
    if (goal.toUpperCase() == 'LOSE') {
      sugarTarget = 30.0; // Stricter for weight loss
    }

    // Calculate water target based on weight, gender, and activity level
    // Base formula: 30-35ml per kg body weight
    double baseWater = weight * 35.0; // ml per day
    
    // Gender adjustment
    if (gender.toUpperCase() == 'MALE') {
      baseWater += 500; // Men typically need more water
    } else if (gender.toUpperCase() == 'FEMALE') {
      baseWater += 200; // Women need slightly less
    }
    
    // Activity level adjustment
    switch (activityLevel.toUpperCase()) {
      case 'SEDENTARY':
        baseWater += 0; // No extra water needed
        break;
      case 'LIGHTLY ACTIVE':
        baseWater += 300; // Light activity adds ~300ml
        break;
      case 'MODERATELY ACTIVE':
        baseWater += 500; // Moderate activity adds ~500ml
        break;
      case 'VERY ACTIVE':
        baseWater += 800; // Very active adds ~800ml
        break;
    }
    
    // Round to nearest 50ml for cleaner numbers
    int waterTarget = ((baseWater / 50).round() * 50).toInt();
    
    // Ensure minimum of 1500ml and maximum of 5000ml
    if (waterTarget < 1500) waterTarget = 1500;
    if (waterTarget > 5000) waterTarget = 5000;

    return {
      'calories': calorieTarget,
      'protein': proteinPct,
      'carbs': carbsPct,
      'fat': fatPct,
      'fiber': fiberTarget.round(),
      'sugar': sugarTarget.round(),
      'water': waterTarget,
    };
  }
  
  // Calculate water target separately (can be called independently)
  static int calculateWaterTarget({
    required double weight,
    required String gender,
    required String activityLevel,
  }) {
    // Base formula: 35ml per kg body weight
    double baseWater = weight * 35.0;
    
    // Gender adjustment
    if (gender.toUpperCase() == 'MALE') {
      baseWater += 500;
    } else if (gender.toUpperCase() == 'FEMALE') {
      baseWater += 200;
    }
    
    // Activity level adjustment
    switch (activityLevel.toUpperCase()) {
      case 'SEDENTARY':
        baseWater += 0;
        break;
      case 'LIGHTLY ACTIVE':
        baseWater += 300;
        break;
      case 'MODERATELY ACTIVE':
        baseWater += 500;
        break;
      case 'VERY ACTIVE':
        baseWater += 800;
        break;
    }
    
    int waterTarget = ((baseWater / 50).round() * 50).toInt();
    if (waterTarget < 1500) waterTarget = 1500;
    if (waterTarget > 5000) waterTarget = 5000;
    
    return waterTarget;
  }

  static double calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    final double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static String getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static Map<String, double> get microNutrientRDA => {
    // Vitamins
    'vitamin_a': 900.0, // μg
    'vitamin_c': 90.0, // mg
    'vitamin_d': 15.0, // μg
    'vitamin_e': 15.0, // mg
    'vitamin_k': 120.0, // μg
    'vitamin_b1_thiamine': 1.2, // mg
    'vitamin_b2_riboflavin': 1.3, // mg
    'vitamin_b3_niacin': 16.0, // mg
    'vitamin_b5_pantothenic_acid': 5.0, // mg
    'vitamin_b6': 1.3, // mg
    'vitamin_b7_biotin': 30.0, // μg
    'vitamin_b9_folate': 400.0, // μg
    'vitamin_b12': 2.4, // μg
    
    // Minerals
    'calcium': 1000.0, // mg
    'iron': 18.0, // mg
    'magnesium': 400.0, // mg
    'phosphorus': 700.0, // mg
    'potassium': 3400.0, // mg
    'sodium': 2300.0, // mg (upper limit)
    'zinc': 11.0, // mg
    'copper': 0.9, // mg
    'manganese': 2.3, // mg
    'selenium': 55.0, // μg
    'chromium': 35.0, // μg
    'molybdenum': 45.0, // μg
    'iodine': 150.0, // μg
    
    // Macros & Essential
    'fiber': 30.0, // g
    'omega3': 1.6, // g
    'omega6': 17.0, // g
    'water': 2500.0, // ml (2.5L)
    
    // Amino Acids (Essential - per kg body weight, assuming 70kg person)
    'leucine': 2.7, // g (for 70kg person)
    'isoleucine': 1.4, // g
    'valine': 1.8, // g
    'lysine': 2.1, // g
    'methionine': 1.3, // g (with cysteine)
    'phenylalanine': 1.75, // g (with tyrosine)
    'threonine': 1.05, // g
    'tryptophan': 0.28, // g
    'histidine': 0.98, // g
    
    // Non-essential Amino Acids (typical daily intake)
    'arginine': 2.0, // g
    'tyrosine': 1.0, // g
    'cysteine': 0.5, // g
    'alanine': 1.0, // g
    'aspartic_acid': 1.5, // g
    'glutamic_acid': 2.0, // g
    'serine': 1.0, // g
    'proline': 1.2, // g
    'glycine': 1.0, // g
    
    // Specialized Nutrients (typical daily intake for active individuals)
    'creatine': 3.0, // g (for muscle support)
    'taurine': 0.5, // g
    'beta_alanine': 3.0, // g (for performance)
    'l_carnitine': 0.5, // g
    'glutamine': 5.0, // g (for recovery)
    'bcaa': 5.0, // g (leucine + isoleucine + valine combined)
  };

  static Map<String, Map<String, dynamic>> get nutrientWarningThresholds => {
    'sodium': {
      'limit': 2300.0,
      'message':
          'Sodium is high. Try drinking more water to help flush it out.',
    },
    'sugar': {
      'limit': 50.0,
      'message':
          'You\'ve exceeded the recommended added sugar limit. Watch your energy later!',
    },
    'saturated_fat': {
      'limit': 20.0,
      'message':
          'Saturated fat is over the limit. Monitor cholesterol in the future.',
    },
    'caffeine': {
      'limit': 400.0,
      'message':
          'Caffeine intake is high. Consider reducing to avoid sleep issues.',
    },
  };

  // Critical nutrients that should be monitored daily
  static List<String> get criticalNutrients => [
    'vitamin_c',
    'vitamin_d',
    'vitamin_b12',
    'calcium',
    'iron',
    'magnesium',
    'zinc',
    'protein',
    'fiber',
    'omega3',
    'selenium',
    'iodine',
    'chromium',
    'vitamin_b9_folate',
    'potassium',
  ];

  // Nutrients that need consecutive day tracking (alarm if missing X days)
  static Map<String, int> get consecutiveDayAlarms => {
    'calcium': 3, // Alarm if missing 3 days
    'iron': 3,
    'vitamin_d': 5,
    'vitamin_b12': 7,
    'magnesium': 4,
    'zinc': 5,
    'fiber': 2,
    'protein': 1, // Daily requirement
    'omega3': 5,
    'selenium': 7,
    'iodine': 7,
    'chromium': 7,
    'vitamin_b9_folate': 5,
    'potassium': 2,
    'vitamin_c': 3,
  };
}
