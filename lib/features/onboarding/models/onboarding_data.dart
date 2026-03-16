class OnboardingData {
  String? nickname;
  String? goal;
  List<String> secondaryGoals = [];
  String? gender;
  int? age;
  double? currentWeight;
  double? targetWeight;
  double? height;
  String? activityLevel;
  bool? isSmoker;
  List<String> allergies = [];
  String? professionalLife;
  
  // Food preferences
  String? dietType; // Vegetarian, Vegan, Keto, Mediterranean, etc.
  List<String> foodPreferences = []; // Breakfast lover, Snack preferences, etc.
  
  // Additional optional questions
  String? cookingFrequency; // Daily, Few times a week, Rarely, etc.
  int? averageWaterIntake; // ml per day
  String? sleepSchedule; // Early bird, Night owl, Regular
  String? workoutTimePreference; // Morning, Afternoon, Evening
  List<String> healthConditions = []; // Diabetes, Hypertension, etc.

  OnboardingData({
    this.nickname,
    this.goal,
    this.gender,
    this.age,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.activityLevel,
    this.isSmoker,
    this.professionalLife,
    this.dietType,
    this.cookingFrequency,
    this.averageWaterIntake,
    this.sleepSchedule,
    this.workoutTimePreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': nickname,
      'goal': goal,
      'gender': gender,
      'age': age,
      'current_weight': currentWeight,
      'target_weight': targetWeight,
      'height': height,
      'activity_level': activityLevel,
      'is_smoker': isSmoker,
      'professional_life': professionalLife,
      // Metadata fields for future use or specific tables
      'onboarding_metadata': {
        'secondary_goals': secondaryGoals,
        'allergies': allergies,
        'diet_type': dietType,
        'food_preferences': foodPreferences,
        'cooking_frequency': cookingFrequency,
        'average_water_intake': averageWaterIntake,
        'sleep_schedule': sleepSchedule,
        'workout_time_preference': workoutTimePreference,
        'health_conditions': healthConditions,
      },
    };
  }
}
