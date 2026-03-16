import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/core/utils/food_unit_detector.dart';
import 'package:flow/services/replicate_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Helper to get current user ID
  String? getCurrentUserId() => _client.auth.currentUser?.id;

  // Authentication
  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<Session?> refreshSession() async {
    final response = await _client.auth.refreshSession();
    return response.session;
  }

  /// Clears deactivated_at on profile when user has confirmed email (called after login).
  Future<void> clearDeactivatedIfConfirmed() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.rpc('clear_deactivated_if_confirmed', params: {'p_user_id': userId});
    } catch (_) {}
  }

  // Profile Management
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').upsert({
      'id': userId,
      ...profileData,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> ensureProfileExists() async {
    final profile = await getProfile();
    if (profile == null) {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Try to get metadata from user
      var metadata = user.userMetadata;
      Map<String, dynamic> profileData = {};

      // If metadata is empty or missing required fields, try to recover from SharedPreferences
      if (metadata == null || 
          !metadata.containsKey('goal') || 
          !metadata.containsKey('gender') ||
          !metadata.containsKey('age') ||
          !metadata.containsKey('current_weight') ||
          !metadata.containsKey('height') ||
          !metadata.containsKey('activity_level')) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingEmail = prefs.getString('pending_user_email');
          
          // Only use saved data if email matches (security check)
          if (pendingEmail == user.email) {
            final savedDataStr = prefs.getString('pending_onboarding_data');
            if (savedDataStr != null) {
              final savedData = jsonDecode(savedDataStr) as Map<String, dynamic>;
              // Merge saved data into metadata
              metadata = {...?metadata, ...savedData};
            }
          }
        } catch (e) {
          debugPrint('Error recovering onboarding data from SharedPreferences: $e');
        }
      }

      // Validate that all required fields are present - NO FALLBACKS
      if (metadata == null) {
        throw Exception('Onboarding data is missing. Please complete onboarding again.');
      }

      final requiredFields = ['goal', 'gender', 'age', 'current_weight', 'height', 'activity_level'];
      final missingFields = <String>[];
      
      for (final field in requiredFields) {
        if (!metadata.containsKey(field) || 
            metadata[field] == null || 
            (metadata[field] is String && (metadata[field] as String).isEmpty)) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        throw Exception('Missing required onboarding data: ${missingFields.join(", ")}. Please complete onboarding again.');
      }

      // Extract all required fields - NO FALLBACKS, values must exist
      final gender = metadata['gender'] as String;
      final goal = metadata['goal'] as String;
      final age = (metadata['age'] as num).toInt();
      final currentWeight = (metadata['current_weight'] as num).toDouble();
      final height = (metadata['height'] as num).toDouble();
      final activityLevel = metadata['activity_level'] as String;

      // Validate gender and goal values
      if (!['MALE', 'FEMALE', 'OTHER'].contains(gender.toUpperCase())) {
        throw Exception('Invalid gender value: $gender');
      }
      if (!['LOSE', 'MAINTAIN', 'GAIN'].contains(goal.toUpperCase())) {
        throw Exception('Invalid goal value: $goal');
      }

      // Calculate targets - all data is guaranteed to be present
      final targets = NutritionUtils.calculateTargets(
        gender: gender,
        weight: currentWeight,
        height: height,
        age: age,
        activityLevel: activityLevel,
        goal: goal,
      );

      // Build profile data with all required fields
      profileData = {
        'gender': gender,
        'goal': goal,
        'age': age,
        'current_weight': currentWeight,
        'height': height,
        'activity_level': activityLevel,
        'daily_calorie_target': targets['calories'],
        'protein_target_percentage': targets['protein'],
        'carbs_target_percentage': targets['carbs'],
        'fat_target_percentage': targets['fat'],
        'daily_water_target': targets['water'],
        'coins': 100,
        'plan_type': 'free',
        'email': user.email,
      };

      // Add optional fields if present
      if (metadata.containsKey('target_weight') && metadata['target_weight'] != null) {
        profileData['target_weight'] = (metadata['target_weight'] as num).toDouble();
      }
      if (metadata.containsKey('is_smoker') && metadata['is_smoker'] != null) {
        profileData['is_smoker'] = metadata['is_smoker'] as bool;
      }
      if (metadata.containsKey('onboarding_metadata')) {
        profileData['onboarding_metadata'] = metadata['onboarding_metadata'];
      }

      // Full name from metadata or email
      profileData['full_name'] = metadata['full_name'] ?? user.email?.split('@')[0] ?? 'User';

      await updateProfile(profileData);

      // Record initial bonus transaction
      final newProfile = await getProfile();
      if (newProfile != null) {
        await recordCoinTransaction(
          amount: 100,
          type: 'BONUS',
          description: 'Initial welcome bonus',
        );
        
        // Clear saved onboarding data after successful profile creation
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_onboarding_data');
          await prefs.remove('pending_user_email');
        } catch (e) {
          debugPrint('Error clearing saved onboarding data: $e');
        }
      }
    }
  }

  // Coin & Plan Management
  Future<int> getCoins() async {
    final profile = await getProfile();
    return (profile?['coins'] as num?)?.toInt() ?? 0;
  }

  Future<String> getSubscriptionPlan() async {
    final profile = await getProfile();
    return (profile?['plan_type'] as String?) ?? 'free';
  }

  Future<void> updateSubscriptionPlan(String planType) async {
    await updateProfile({'plan_type': planType});
  }

  Future<void> recordCoinTransaction({
    required int amount,
    required String type,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('coin_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'type': type,
      'description': description,
    });
  }

  Future<bool> purchaseWithCoins(int cost, String description) async {
    final currentCoins = await getCoins();
    if (currentCoins < cost) return false;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Deduct coins
    await updateProfile({'coins': currentCoins - cost});

    // Record transaction
    await recordCoinTransaction(
      amount: -cost,
      type: 'SPEND',
      description: description,
    );

    return true;
  }

  Future<List<Map<String, dynamic>>> getCoinTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('coin_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCoinPackages() async {
    final response = await _client
        .from('coin_packages')
        .select()
        .order('price_value', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final response = await _client
        .from('subscription_plans')
        .select()
        .order('monthly_coin_cost', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Avatar Management
  Future<String?> uploadAvatar() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 50,
    );

    if (image == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final fileName =
        '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await _client.storage
          .from('avatars')
          .upload(
            '$userId/$fileName',
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _client.storage
          .from('avatars')
          .getPublicUrl('$userId/$fileName');

      await updateProfile({'avatar_url': imageUrl});

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // Food Search
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.trim().length < 2) return [];

    final response = await _client
        .from('general_food_flow')
        .select()
        .or('name.ilike.%$query%,german_name.ilike.%$query%')
        .limit(30);
    return List<Map<String, dynamic>>.from(response);
  }

  // Food Search with Filter (All, General, Custom)
  Future<List<Map<String, dynamic>>> searchFoodWithFilter(
    String query, {
    String filter = 'all', // 'all', 'general', 'custom'
  }) async {
    if (query.trim().length < 2) return [];

    final userId = getCurrentUserId();
    final List<Map<String, dynamic>> results = [];

    // Search in general_food_flow if filter is 'all' or 'general'
    if (filter == 'all' || filter == 'general') {
      final generalResponse = await _client
          .from('general_food_flow')
          .select()
          .or('name.ilike.%$query%,german_name.ilike.%$query%')
          .limit(30);
      
      for (var food in generalResponse) {
        final foodMap = Map<String, dynamic>.from(food);
        foodMap['is_custom'] = false;
        results.add(foodMap);
      }
    }

    // Search in user_custom_foods if filter is 'all' or 'custom'
    if (userId != null && (filter == 'all' || filter == 'custom')) {
      final customResponse = await _client
          .from('user_custom_foods')
          .select()
          .eq('user_id', userId)
          .or('name.ilike.%$query%,german_name.ilike.%$query%')
          .limit(30);
      
      for (var food in customResponse) {
        final foodMap = Map<String, dynamic>.from(food);
        foodMap['is_custom'] = true;
        results.add(foodMap);
      }
    }

    return results;
  }

  // Create custom food with AI-generated details
  Future<Map<String, dynamic>> createCustomFoodWithAI(
    String foodName,
    Map<String, dynamic> aiFoodData, {
    String language = 'en',
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Ensure profile exists before inserting custom food
    await ensureProfileExists();

    try {
      // Check if food already exists
      final existing = await _client
          .from('user_custom_foods')
          .select('id')
          .eq('user_id', userId)
          .eq('name', foodName)
          .maybeSingle();

      // Detect unit if not provided
      final unit = aiFoodData['unit'] as String? ?? 
                   FoodUnitDetector.detectUnit(aiFoodData['name'] ?? foodName);
      
      // If unit is 'piece', we need to convert values to per-100g
      Map<String, dynamic> processedData = Map<String, dynamic>.from(aiFoodData);
      if (unit == 'piece') {
        final pieceWeight = FoodUnitDetector.getPieceWeight(aiFoodData['name'] ?? foodName) ?? 100.0;
        // Convert piece-based values to per-100g
        final nutritionKeys = [
          'calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'saturated_fat',
          'omega3', 'omega6', 'vitamin_a', 'vitamin_c', 'vitamin_d', 'vitamin_e', 'vitamin_k',
          'vitamin_b1_thiamine', 'vitamin_b2_riboflavin', 'vitamin_b3_niacin',
          'vitamin_b5_pantothenic_acid', 'vitamin_b6', 'vitamin_b7_biotin',
          'vitamin_b9_folate', 'vitamin_b12', 'calcium', 'iron', 'magnesium',
          'phosphorus', 'potassium', 'sodium', 'zinc', 'copper', 'manganese',
          'selenium', 'choline', 'water', 'caffeine',
        ];
        
        final multiplier = 100.0 / pieceWeight;
        for (var key in nutritionKeys) {
          if (processedData[key] != null) {
            processedData[key] = (processedData[key] as num).toDouble() * multiplier;
          }
        }
        // Store piece weight for later use
        processedData['piece_weight'] = pieceWeight;
      }

      final foodData = {
        'user_id': userId,
        'name': processedData['name'] ?? foodName,
        'german_name': processedData['german_name'] ?? processedData['name'] ?? foodName,
        'calories': processedData['calories'] ?? 0.0,
        'protein': processedData['protein'] ?? 0.0,
        'carbs': processedData['carbs'] ?? 0.0,
        'fat': processedData['fat'] ?? 0.0,
        'fiber': processedData['fiber'] ?? 0.0,
        'sugar': processedData['sugar'] ?? 0.0,
        'sodium': processedData['sodium'] ?? 0.0,
        'water': processedData['water'] ?? 0.0,
        'caffeine': processedData['caffeine'] ?? 0.0,
        'unit': unit, // Save detected unit
        'piece_weight': processedData['piece_weight'], // Save piece weight if applicable
        'source': 'ai_search',
        'updated_at': DateTime.now().toIso8601String(),
      };

      String foodId;
      Map<String, dynamic> createdFood;

      if (existing != null) {
        // Update existing custom food
        foodId = existing['id'] as String;
        await _client
            .from('user_custom_foods')
            .update(foodData)
            .eq('id', foodId)
            .eq('user_id', userId);
        
        // Fetch updated food
        final response = await _client
            .from('user_custom_foods')
            .select()
            .eq('id', foodId)
            .single();
        createdFood = Map<String, dynamic>.from(response);
      } else {
        // Create new custom food
        final response = await _client
            .from('user_custom_foods')
            .insert(foodData)
            .select()
            .single();
        createdFood = Map<String, dynamic>.from(response);
        foodId = createdFood['id'] as String;
      }

      // Mark as custom food
      createdFood['is_custom'] = true;
      return createdFood;
    } catch (e) {
      debugPrint('Error creating custom food with AI: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentFoods({int limit = 10}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. Get food_ids and custom_food_names from recent logs
    final logs = await _client
        .from('daily_logs')
        .select('food_id, custom_food_name, logged_at')
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .limit(50); // Fetch more to ensure distinct items

    if (logs.isEmpty) return [];

    // 2. Separate regular foods and custom foods
    final Set<String> foodIds = {};
    final Set<String> customFoodNames = {};
    final Map<String, DateTime> foodTimestamps = {}; // Track when each food was last logged
    
    for (var log in logs) {
      final loggedAt = DateTime.parse(log['logged_at'] as String);
      
      if (log['food_id'] != null) {
        final foodId = log['food_id'] as String;
        if (!foodIds.contains(foodId)) {
          foodIds.add(foodId);
          foodTimestamps[foodId] = loggedAt;
        }
      } else if (log['custom_food_name'] != null) {
        final customName = log['custom_food_name'] as String;
        if (!customFoodNames.contains(customName)) {
          customFoodNames.add(customName);
          foodTimestamps['custom_$customName'] = loggedAt;
        }
    }

      if (foodIds.length + customFoodNames.length >= limit) break;
    }

    final List<Map<String, dynamic>> allFoods = [];

    // 3. Fetch regular foods from general_food_flow
    if (foodIds.isNotEmpty) {
    final foodResponse = await _client
        .from('general_food_flow')
        .select()
        .filter('id', 'in', foodIds.toList());
      allFoods.addAll(List<Map<String, dynamic>>.from(foodResponse));
    }

    // 4. Fetch custom foods from user_custom_foods
    if (customFoodNames.isNotEmpty) {
      // Get all custom foods for this user
      final allCustomFoods = await _client
          .from('user_custom_foods')
          .select()
          .eq('user_id', userId);
      
      // Match custom foods by name (case-insensitive)
      for (var customName in customFoodNames) {
        final matchedFood = allCustomFoods.firstWhere(
          (food) => (food['name'] as String?)?.toLowerCase() == customName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        
        if (matchedFood.isNotEmpty) {
          // Mark as custom food for identification
          matchedFood['is_custom'] = true;
          allFoods.add(matchedFood);
        }
      }
    }

    // 5. Sort by most recent logged_at timestamp
    allFoods.sort((a, b) {
      final aIsCustom = a['is_custom'] == true;
      final bIsCustom = b['is_custom'] == true;
      
      final aKey = aIsCustom 
          ? 'custom_${a['name']}' 
          : (a['id'] as String? ?? '');
      final bKey = bIsCustom 
          ? 'custom_${b['name']}' 
          : (b['id'] as String? ?? '');
      
      final aTime = foodTimestamps[aKey] ?? DateTime(1970);
      final bTime = foodTimestamps[bKey] ?? DateTime(1970);
      
      return bTime.compareTo(aTime); // Most recent first
    });

    // 6. Return limited results
    return allFoods.take(limit).toList();
  }

  // Log Meal (supports both general_food_flow and user_custom_foods)
  // Now saves ALL nutritional data in nutrition_data JSONB field
  Future<void> logMeal({
    required String foodId,
    required double quantity,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    required String unit,
    Map<String, dynamic>? foodData, // Optional: pass food data to check for water/caffeine
    bool isCustomFood = false, // If true, foodId is from user_custom_foods
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Calculate multiplier based on quantity and unit (intelligent unit handling)
    final foodName = foodData?['name'] as String?;
    final multiplier = FoodUnitDetector.calculateMultiplier(
      quantity: quantity,
      unit: unit,
      foodName: foodName,
    );

    // Extract ALL nutritional data from foodData
    final nutritionData = <String, dynamic>{};
    
    if (foodData != null) {
      // List of all possible nutrient keys (matching recipes schema)
      final nutrientKeys = [
        'calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'saturated_fat',
        'omega3', 'omega6',
        'vitamin_a', 'vitamin_c', 'vitamin_d', 'vitamin_e', 'vitamin_k',
        'vitamin_b1_thiamine', 'vitamin_b2_riboflavin', 'vitamin_b3_niacin',
        'vitamin_b5_pantothenic_acid', 'vitamin_b6', 'vitamin_b7_biotin',
        'vitamin_b9_folate', 'vitamin_b12',
        'calcium', 'iron', 'magnesium', 'phosphorus', 'potassium', 'sodium',
        'zinc', 'copper', 'manganese', 'selenium', 'chromium', 'molybdenum', 'iodine',
        'water', 'caffeine',
        'creatine', 'taurine', 'beta_alanine', 'l_carnitine', 'glutamine', 'bcaa',
        'leucine', 'isoleucine', 'valine', 'lysine', 'methionine', 'phenylalanine',
        'threonine', 'tryptophan', 'histidine', 'arginine', 'tyrosine', 'cysteine',
        'alanine', 'aspartic_acid', 'glutamic_acid', 'serine', 'proline', 'glycine',
      ];

      // Extract all nutrients from foodData and multiply by quantity factor
      for (var key in nutrientKeys) {
        final value = (foodData[key] as num?)?.toDouble();
        if (value != null && value > 0) {
          nutritionData[key] = value * multiplier;
        }
      }
    } else {
      // If no foodData provided, at least store the basic macros
      nutritionData['calories'] = calories;
      nutritionData['protein'] = protein;
      nutritionData['carbs'] = carbs;
      nutritionData['fat'] = fat;
    }

    final logData = <String, dynamic>{
      'user_id': userId,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'meal_type': mealType,
      'unit': unit,
      'nutrition_data': nutritionData, // Store ALL nutritional data in JSONB
      'logged_at': DateTime.now().toIso8601String(),
    };

    if (isCustomFood) {
      // For custom foods, use custom_food_name instead of food_id
      logData['custom_food_name'] = foodData?['name'] ?? 'Custom Food';
    } else {
      // For regular foods, use food_id
      logData['food_id'] = foodId;
    }

    await _client.from('daily_logs').insert(logData);

    // Auto-log water if food contains water
    if (foodData != null) {
      await _autoLogWaterFromFood(foodData, quantity, unit);
    }
  }

  // Auto-log water from food (e.g., water, juice, soup)
  Future<void> _autoLogWaterFromFood(
    Map<String, dynamic> food,
    double quantity,
    String unit,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Priority 1: Check water field in database (most reliable)
      final waterValue = (food['water'] as num?)?.toDouble() ?? 0.0;
      final waterContent = (food['water_content'] as num?)?.toDouble() ?? 0.0;
      
      final foodName = (food['name']?.toString() ?? '').toLowerCase();
      final germanName = (food['german_name']?.toString() ?? '').toLowerCase();
      final allText = '$foodName $germanName';
      
      // Exclude solid foods from auto-logging water
      final solidFoodExclusions = [
        'pasta', 'noodles', 'nudeln', 'spaghetti', 'macaroni', 'penne', 'fusilli',
        'rice', 'reis', 'bread', 'brot', 'cake', 'kuchen', 'cookie', 'kekse',
        'potato', 'potatoes', 'kartoffel', 'pommes', 'fries', 'chips',
        'fruit', 'frucht', 'vegetable', 'gemüse', 'salad', 'salat',
        'meat', 'fleisch', 'chicken', 'huhn', 'fish', 'fisch', 'beef', 'rind',
        'cheese', 'käse', 'yogurt', 'joghurt'
      ];
      
      final isSolidFood = solidFoodExclusions.any((exclusion) => allText.contains(exclusion));
      
      // Only auto-log water for actual liquids/drinks, not solid foods with water content
      final isLiquidDrink = !isSolidFood && (
        allText.contains('water') || 
        allText.contains('wasser') ||
        allText.contains('juice') ||
        allText.contains('saft') ||
        allText.contains('soup') ||
        allText.contains('suppe') ||
        allText.contains('tea') ||
        allText.contains('tee') ||
        allText.contains('coffee') ||
        allText.contains('kaffee') ||
        allText.contains('drink') ||
        allText.contains('getränk') ||
        allText.contains('soda') ||
        allText.contains('cola') ||
        unit.toLowerCase() == 'ml'
      );
      
      if (!isLiquidDrink) {
        // Don't auto-log water for solid foods
        return;
      }
      
      // Calculate water amount
      int waterMl = 0;
      
      if (unit.toLowerCase() == 'ml') {
        // If unit is ml, it's a liquid - use quantity directly
        // But if water field exists, use it to calculate actual water content
        if (waterValue > 0) {
          // water field is typically in g per 100g, so for ml we assume 1ml = 1g
          // Calculate: (waterValue / 100) * quantity
          waterMl = ((waterValue / 100.0) * quantity).toInt();
        } else if (waterContent > 0) {
          // water_content is percentage
          waterMl = ((waterContent / 100.0) * quantity).toInt();
        } else {
          // No water data, assume 100% for pure liquids
          waterMl = quantity.toInt();
        }
      } else if (unit.toLowerCase() == 'g') {
        // If unit is g, calculate based on water field
        if (waterValue > 0) {
          // water field is in g per 100g
          waterMl = ((waterValue / 100.0) * quantity).toInt();
        } else if (waterContent > 0) {
          // water_content is percentage
          waterMl = ((waterContent / 100.0) * quantity).toInt();
        } else {
          // For liquids in grams, assume 1g ≈ 1ml
          waterMl = quantity.toInt();
        }
      }

      // Only log if significant amount (at least 50ml)
      if (waterMl >= 50) {
        await logWater(waterMl);
        debugPrint('Auto-logged $waterMl ml of water from food (water field: $waterValue, unit: $unit, quantity: $quantity)');
      }
    } catch (e) {
      debugPrint('Error auto-logging water: $e');
      // Don't throw - water logging is optional
    }
  }

  // Get food consumption history
  Future<Map<String, dynamic>> getFoodHistory(String foodId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final logs = await _client
          .from('daily_logs')
          .select('logged_at, quantity, meal_type')
          .eq('user_id', userId)
          .eq('food_id', foodId)
          .order('logged_at', ascending: false)
          .limit(100);

      if (logs.isEmpty) return {};

      final now = DateTime.now();
      final lastLog = DateTime.parse(logs[0]['logged_at']);
      final daysSince = now.difference(lastLog).inDays;
      
      final thisMonth = logs.where((log) {
        final logDate = DateTime.parse(log['logged_at']);
        return logDate.month == now.month && logDate.year == now.year;
      }).length;

      final thisWeek = logs.where((log) {
        final logDate = DateTime.parse(log['logged_at']);
        return now.difference(logDate).inDays <= 7;
      }).length;

      return {
        'lastLogged': lastLog,
        'daysSince': daysSince,
        'totalTimes': logs.length,
        'thisMonth': thisMonth,
        'thisWeek': thisWeek,
        'lastQuantity': logs[0]['quantity'],
        'lastMealType': logs[0]['meal_type'],
      };
    } catch (e) {
      debugPrint('Error getting food history: $e');
      return {};
    }
  }

  // Get similar foods (alternatives)
  Future<List<Map<String, dynamic>>> getSimilarFoods(String foodId, {int limit = 5}) async {
    try {
      final currentFood = await _client
          .from('general_food_flow')
          .select()
          .eq('id', foodId)
          .single();

      final currentCalories = (currentFood['calories'] as num?)?.toDouble() ?? 0.0;
      final currentProtein = (currentFood['protein'] as num?)?.toDouble() ?? 0.0;
      
      // Search for foods with similar calories (±30%) and better protein
      final similar = await _client
          .from('general_food_flow')
          .select()
          .neq('id', foodId)
          .gte('calories', currentCalories * 0.7)
          .lte('calories', currentCalories * 1.3)
          .gte('protein', currentProtein * 1.1) // At least 10% more protein
          .limit(limit);

      return List<Map<String, dynamic>>.from(similar);
    } catch (e) {
      debugPrint('Error getting similar foods: $e');
      return [];
    }
  }

  // Favorite Foods Management
  Future<bool> isFavoriteFood(String foodId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('favorite_foods')
          .select('id')
          .eq('user_id', userId)
          .eq('food_id', foodId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  Future<void> addFavoriteFood(String foodId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('favorite_foods').insert({
        'user_id': userId,
        'food_id': foodId,
      });
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavoriteFood(String foodId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('favorite_foods')
          .delete()
          .eq('user_id', userId)
          .eq('food_id', foodId);
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteFoods() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final favorites = await _client
          .from('favorite_foods')
          .select('food_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (favorites.isEmpty) return [];

      final foodIds = favorites.map((f) => f['food_id'] as String).toList();
      
      final foods = await _client
          .from('general_food_flow')
          .select()
          .filter('id', 'in', foodIds);

      return List<Map<String, dynamic>>.from(foods);
    } catch (e) {
      debugPrint('Error getting favorite foods: $e');
      return [];
    }
  }

  // Search foods for meal pairing
  Future<List<Map<String, dynamic>>> searchFoodsForPairing({
    double? minProtein,
    double? maxCalories,
    double? minFiber,
    String? category,
    int limit = 5,
  }) async {
    try {
      var query = _client.from('general_food_flow').select();
      
      if (minProtein != null) {
        query = query.gte('protein', minProtein);
      }
      if (maxCalories != null) {
        query = query.lte('calories', maxCalories);
      }
      if (minFiber != null) {
        query = query.gte('fiber', minFiber);
      }
      
      final results = await query.limit(limit);
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('Error searching foods for pairing: $e');
      return [];
    }
  }

  // Save custom food (from camera, voice, etc.)
  // Uses upsert logic: if a custom food with the same name exists for this user, it updates it
  // Otherwise, creates a new one. This ensures edits persist when the food is added again.
  Future<String> saveCustomFood({
    required String name,
    String? germanName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? water,
    double? caffeine,
    String? imageUrl,
    required String source, // 'camera', 'barcode', 'voice'
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Ensure profile exists before inserting custom food
    await ensureProfileExists();

    try {
      // Check if a custom food with the same name already exists for this user
      final existing = await _client
          .from('user_custom_foods')
          .select('id')
          .eq('user_id', userId)
          .eq('name', name)
          .maybeSingle();

      // Detect unit automatically
      final unit = FoodUnitDetector.detectUnit(name);
      double? pieceWeight;
      if (unit == 'piece') {
        pieceWeight = FoodUnitDetector.getPieceWeight(name);
      }

      final foodData = {
        'user_id': userId,
        'name': name,
        'german_name': germanName ?? name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        if (fiber != null) 'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (sodium != null) 'sodium': sodium,
        if (water != null) 'water': water,
        if (caffeine != null) 'caffeine': caffeine,
        if (imageUrl != null) 'image_url': imageUrl,
        'unit': unit, // Add detected unit
        if (pieceWeight != null) 'piece_weight': pieceWeight, // Add piece weight if applicable
        'source': source,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String foodId;

      if (existing != null) {
        // Update existing custom food
        foodId = existing['id'] as String;
        await _client
            .from('user_custom_foods')
            .update(foodData)
            .eq('id', foodId)
            .eq('user_id', userId);
      } else {
        // Create new custom food
        final response = await _client
            .from('user_custom_foods')
            .insert(foodData)
            .select('id')
            .single();
        foodId = response['id'] as String;
      }

      return foodId;
    } catch (e) {
      debugPrint('Error saving custom food: $e');
      rethrow;
    }
  }

  // Get custom food by ID
  Future<Map<String, dynamic>?> getCustomFood(String foodId) async {
    try {
      final response = await _client
          .from('user_custom_foods')
          .select()
          .eq('id', foodId)
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error getting custom food: $e');
      return null;
    }
  }

  // Update custom food
  Future<void> updateCustomFood({
    required String foodId,
    String? name,
    String? germanName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? water,
    double? caffeine,
    Map<String, dynamic>? additionalNutrients, // For other nutrients
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (germanName != null) updateData['german_name'] = germanName;
      if (calories != null) updateData['calories'] = calories;
      if (protein != null) updateData['protein'] = protein;
      if (carbs != null) updateData['carbs'] = carbs;
      if (fat != null) updateData['fat'] = fat;
      if (fiber != null) updateData['fiber'] = fiber;
      if (sugar != null) updateData['sugar'] = sugar;
      if (sodium != null) updateData['sodium'] = sodium;
      if (water != null) updateData['water'] = water;
      if (caffeine != null) updateData['caffeine'] = caffeine;

      // Add additional nutrients if provided
      if (additionalNutrients != null) {
        updateData.addAll(additionalNutrients);
      }

      await _client
          .from('user_custom_foods')
          .update(updateData)
          .eq('id', foodId)
          .eq('user_id', userId); // Ensure user owns this food
    } catch (e) {
      debugPrint('Error updating custom food: $e');
      rethrow;
    }
  }

  // Get average nutrition for similar foods
  Future<Map<String, double>> getAverageNutritionForCategory(String foodName) async {
    try {
      // Extract category from food name (simple approach)
      final keywords = foodName.toLowerCase().split(' ');
      final searchTerm = keywords.length > 1 ? keywords[0] : foodName.toLowerCase();
      
      final foods = await _client
          .from('general_food_flow')
          .select('calories, protein, carbs, fat, fiber, sugar')
          .or('name.ilike.%$searchTerm%,german_name.ilike.%$searchTerm%')
          .limit(50);

      if (foods.isEmpty) return {};

      double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0, totalFiber = 0, totalSugar = 0;
      int count = 0;

      for (var food in foods) {
        totalCalories += ((food['calories'] as num?)?.toDouble() ?? 0.0);
        totalProtein += ((food['protein'] as num?)?.toDouble() ?? 0.0);
        totalCarbs += ((food['carbs'] as num?)?.toDouble() ?? 0.0);
        totalFat += ((food['fat'] as num?)?.toDouble() ?? 0.0);
        totalFiber += ((food['fiber'] as num?)?.toDouble() ?? 0.0);
        totalSugar += ((food['sugar'] as num?)?.toDouble() ?? 0.0);
        count++;
      }

      if (count == 0) return {};

      return {
        'calories': totalCalories / count,
        'protein': totalProtein / count,
        'carbs': totalCarbs / count,
        'fat': totalFat / count,
        'fiber': totalFiber / count,
        'sugar': totalSugar / count,
      };
    } catch (e) {
      debugPrint('Error getting average nutrition: $e');
      return {};
    }
  }

  // Upload generated text post image
  Future<String> uploadTextPostImage(File imageFile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final fileExt = 'png';
    final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    final storagePath = '$userId/$fileName';

    try {
      await _client.storage.from('posts').upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/png',
            ),
          );

      return _client.storage.from('posts').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading text post image: $e');
      throw Exception('Failed to upload text post image: $e');
    }
  }

  // Username Setup Methods
  Future<bool> hasUsername() async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    final profile = await getProfileById(userId);
    return profile?['username'] != null && 
           profile!['username'].toString().isNotEmpty;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    
    return response == null;
  }

  Future<void> setupSocialProfile({
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');
    
    await _client.from('profiles').update({
      'username': username.toLowerCase(),
      'full_name': displayName,
      'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  // Update profile with social fields
  Future<void> updateSocialProfile({
    String? fullName,
    String? bio,
    String? website,
    String? avatarUrl,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (website != null) updates['website'] = website;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  // Social
  Future<List<Map<String, dynamic>>> getSocialFeed({bool popular = false}) async {
    final userId = getCurrentUserId();
    
    dynamic query = _client
        .from('social_posts')
        .select('*, profiles(id, full_name, username, avatar_url), social_likes(user_id)');
        
    if (popular) {
      query = query.order('likes_count', ascending: false);
    } else {
      query = query.order('created_at', ascending: false);
    }
    
    final response = await query.limit(20);
        
    final List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(response);
    
    // Process posts to add is_liked flag
    if (userId != null) {
      for (var post in posts) {
        final List<dynamic> likes = post['social_likes'] as List<dynamic>? ?? [];
        post['is_liked'] = likes.any((like) => like['user_id'] == userId);
      }
    }
    
    return posts;
  }

  Future<void> createPost(
    String content, {
    String? imageUrl,
    String postType = 'text',
    String? mealId,
    String? workoutId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('social_posts').insert({
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'post_type': postType,
      'meal_id': mealId,
      'workout_id': workoutId,
    });
  }

  // Search users by username or name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select('id, full_name, username, avatar_url')
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserLikes() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    final response = await _client
        .from('social_likes')
        .select('post_id')
        .eq('user_id', userId);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> toggleLike(String postId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Check if already liked to avoid duplication
    final existingLike = await _client
        .from('social_likes')
        .select()
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();

    // Get current likes count
    final currentPost = await _client
        .from('social_posts')
        .select('likes_count')
        .eq('id', postId)
        .maybeSingle();
    
    final currentLikes = (currentPost?['likes_count'] as num?)?.toInt() ?? 0;

    if (existingLike == null) {
      // Like the post
      await _client.from('social_likes').insert({
        'user_id': userId,
        'post_id': postId,
      });
      
      // Update likes_count
      await _client
          .from('social_posts')
          .update({'likes_count': currentLikes + 1})
          .eq('id', postId);
    } else {
      // Unlike the post
      await _client.from('social_likes').delete().match({
        'user_id': userId,
        'post_id': postId,
      });
      
      // Update likes_count
      await _client
          .from('social_posts')
          .update({'likes_count': (currentLikes - 1).clamp(0, double.infinity).toInt()})
          .eq('id', postId);
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    await _client.from('social_posts').delete().eq('id', postId);
  }

  Future<void> addComment(String postId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('social_comments').insert({
      'user_id': userId,
      'post_id': postId,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await _client
        .from('social_comments')
        .select('*, profiles(full_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Messaging System
  Future<String> createChatRoom(String otherUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // 1. Check if room exists
    // This is complex in SQL, for now simplifying: just create new or return existing if we tracked it better
    // Ideally we query chat_participants to find common room
    
    final roomResponse = await _client.from('chat_rooms').insert({}).select().single();
    final roomId = roomResponse['id'];

    await _client.from('chat_participants').insert([
      {'room_id': roomId, 'user_id': userId},
      {'room_id': roomId, 'user_id': otherUserId},
    ]);

    return roomId;
  }

  Future<void> sendMessage(
      String roomId, String content, {
      String messageType = 'text',
      String? audioUrl,
      int? duration,
    }) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': userId,
      'content': content,
      'message_type': messageType,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (duration != null) 'duration_seconds': duration,
    });
    
    // Note: room.last_message and room.last_message_at are now 
    // updated via the database trigger for maximum speed.
  }

  Future<String?> uploadAudioMessage(File audioFile) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.m4a';
    final storagePath = '$userId/$fileName';

    try {
      await _client.storage.from('chat_attachments').upload(
            storagePath,
            audioFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'audio/m4a',
            ),
          );

      return _client.storage.from('chat_attachments').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChatRooms() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch rooms where I am a participant, and also include the profiles of other participants
    final response = await _client
        .from('chat_rooms')
        .select('*, chat_participants!inner(user_id, profiles!inner(*))')
        .order('last_message_at', ascending: false);
        
    final List<Map<String, dynamic>> rooms = [];
    
    for (var room in response) {
      final participants = room['chat_participants'] as List<dynamic>? ?? [];
      // Find the "other" user
      final otherParticipant = participants.firstWhere(
        (p) => p['user_id'] != userId,
        orElse: () => null,
      );
      
      if (otherParticipant != null) {
        room['other_user'] = otherParticipant['profiles'];
        rooms.add(room);
      }
    }
      
    return rooms;
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((maps) => maps);
  }

  // Stories
  Future<List<Map<String, dynamic>>> getStories() async {
    final response = await _client
        .from('social_stories')
        .select('*, profiles(id, full_name, username, avatar_url)')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addStory(String imageUrl) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('social_stories').insert({
      'user_id': userId,
      'image_url': imageUrl,
      'expires_at': DateTime.now().add(const Duration(hours: 24)).toUtc().toIso8601String(),
    });
  }

  // Reposts
  Future<bool> toggleRepost(String postId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    // Check if already reposted
    final existing = await _client
        .from('social_reposts')
        .select()
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      // Remove repost
      await _client
          .from('social_reposts')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
      return false; // Not reposted anymore
    } else {
      // Add repost
      await _client
          .from('social_reposts')
          .insert({
            'user_id': userId,
            'post_id': postId,
          });
      return true; // Reposted
    }
  }

  Future<int> getRepostsCount(String postId) async {
    final response = await _client
        .from('social_posts')
        .select('reposts_count')
        .eq('id', postId)
        .single();
    return response['reposts_count'] ?? 0;
  }

  // Social Profile Methods
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final response = await _client
        .from('social_posts')
        .select('*, profiles(id, full_name, username, avatar_url)')
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get saved posts for current user
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    try {
      final response = await _client
          .from('social_posts')
          .select('*, profiles(id, full_name, username, avatar_url), social_likes(user_id)')
          .eq('saved_by', userId)
          .order('created_at', ascending: false);
      
      final posts = List<Map<String, dynamic>>.from(response);
      // Mark liked posts
      final likes = await getUserLikes();
      final likedPostIds = likes.map((e) => e['post_id'].toString()).toSet();
      
      for (var post in posts) {
        post['is_liked'] = likedPostIds.contains(post['id'].toString());
      }
      
      return posts;
    } catch (e) {
      debugPrint('Error getting saved posts: $e');
      // Fallback: if saved_by column doesn't exist, use a join table approach
      return [];
    }
  }

  // Get archived posts for current user
  Future<List<Map<String, dynamic>>> getArchivedPosts() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    
    try {
      final response = await _client
          .from('social_posts')
          .select('*, profiles(id, full_name, username, avatar_url), social_likes(user_id)')
          .eq('user_id', userId)
          .eq('is_archived', true)
          .order('created_at', ascending: false);
      
      final posts = List<Map<String, dynamic>>.from(response);
      // Mark liked posts
      final likes = await getUserLikes();
      final likedPostIds = likes.map((e) => e['post_id'].toString()).toSet();
      
      for (var post in posts) {
        post['is_liked'] = likedPostIds.contains(post['id'].toString());
      }
      
      return posts;
    } catch (e) {
      debugPrint('Error getting archived posts: $e');
      return [];
    }
  }

  Future<void> followUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    if (userId == targetUserId) {
      throw Exception('You cannot follow yourself');
    }

    await _client.from('social_follows').insert({
      'follower_id': userId,
      'following_id': targetUserId,
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('social_follows').delete().match({
      'follower_id': userId,
      'following_id': targetUserId,
    });
  }

  Future<bool> isFollowing(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('social_follows')
        .select()
        .eq('follower_id', userId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return response != null;
  }

  Future<int> getFollowersCount(String userId) async {
    final response = await _client
        .from('social_follows')
        .select()
        .eq('following_id', userId)
        .count();
    return response.count;
  }

  Future<int> getFollowingCount(String userId) async {
    final response = await _client
        .from('social_follows')
        .select()
        .eq('follower_id', userId)
        .count();
    return response.count;
  }

  Future<String?> uploadPostImage([File? providedFile]) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    File? imageFile = providedFile;

    if (imageFile == null) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;
      imageFile = File(image.path);
    }

    try {
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      // Use jpeg for jpg extension
      final mimeType = fileExt == 'jpg' || fileExt == 'jpeg' ? 'image/jpeg' : 'image/$fileExt';
      
      final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$userId/$fileName';

      await _client.storage
          .from('posts')
          .upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      return _client.storage.from('posts').getPublicUrl(storagePath);
    } on StorageException catch (e) {
      debugPrint('Supabase Storage Error: ${e.message} (${e.statusCode})');
      throw Exception('Storage Error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error uploading post image: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // Water Tracking
  Future<void> logWater(int amountMl) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('water_logs').insert({
      'user_id': userId,
      'amount_ml': amountMl,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setWaterReminder(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await updateProfile({'water_reminders_enabled': enabled});
  }

  Future<List<Map<String, dynamic>>> getDailyWaterLogs(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await _client
        .from('water_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startOfDay)
        .lte('logged_at', endOfDay);

    return List<Map<String, dynamic>>.from(response);
  }

  // Weight Tracking
  Future<void> logWeight(double weight) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('weight_logs').insert({
      'user_id': userId,
      'weight': weight,
    });

    // Also update current weight in profile
    await updateProfile({'current_weight': weight});
  }

  // Get latest weight (from weight_logs or profile)
  Future<double?> getLatestWeight() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // First try to get from weight_logs (most recent)
      final weightLogs = await _client
          .from('weight_logs')
          .select('weight')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (weightLogs != null && weightLogs['weight'] != null) {
        return (weightLogs['weight'] as num).toDouble();
      }

      // Fallback to profile current_weight
      final profile = await getProfile();
      if (profile != null && profile['current_weight'] != null) {
        return (profile['current_weight'] as num).toDouble();
      }

      return null;
    } catch (e) {
      debugPrint('Error getting latest weight: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWeightHistory({int days = 7}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    final response = await _client
        .from('weight_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', cutoff)
        .order('logged_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Analytics
  Future<Map<String, List<double>>> getWeeklyStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'calories': [], 'protein': [], 'carbs': [], 'fat': []};
    }

    final now = DateTime.now();
    final List<double> calories = [];
    final List<double> protein = [];
    final List<double> carbs = [];
    final List<double> fat = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await getDailyMealLogs(date);

      double dayCal = 0, dayP = 0, dayC = 0, dayF = 0;
      for (var log in logs) {
        dayCal += (log['calories'] as num?)?.toDouble() ?? 0;
        dayP += (log['protein'] as num?)?.toDouble() ?? 0;
        dayC += (log['carbs'] as num?)?.toDouble() ?? 0;
        dayF += (log['fat'] as num?)?.toDouble() ?? 0;
      }
      calories.add(dayCal);
      protein.add(dayP);
      carbs.add(dayC);
      fat.add(dayF);
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Future<double?> getInitialWeight() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('weight_logs')
        .select('weight')
        .eq('user_id', userId)
        .order('logged_at', ascending: true)
        .limit(1)
        .maybeSingle();

    return (response?['weight'] as num?)?.toDouble();
  }

  Future<int> getStreakCount([String? userId]) async {
    final targetUserId = userId ?? _client.auth.currentUser?.id;
    if (targetUserId == null) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final startOfDay = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
        23,
        59,
        59,
      ).toIso8601String();

      final response = await _client
          .from('daily_logs')
          .select('id')
          .eq('user_id', targetUserId)
          .gte('logged_at', startOfDay)
          .lte('logged_at', endOfDay)
          .limit(1);

      if (response.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If no log today, it might still be an active streak from yesterday
        if (streak == 0) {
          // Check yesterday
          checkDate = checkDate.subtract(const Duration(days: 1));
          final yesterdayResponse = await _client
              .from('daily_logs')
              .select('id')
              .eq('user_id', targetUserId)
              .gte(
                'logged_at',
                DateTime(
                  checkDate.year,
                  checkDate.month,
                  checkDate.day,
                ).toIso8601String(),
              )
              .lte(
                'logged_at',
                DateTime(
                  checkDate.year,
                  checkDate.month,
                  checkDate.day,
                  23,
                  59,
                  59,
                ).toIso8601String(),
              )
              .limit(1);

          if (yesterdayResponse.isEmpty) {
            break;
          } else {
            // Streak exists from yesterday, but nothing today yet
            // We'll start counting from yesterday
            continue;
          }
        }
        break;
      }

      // Safety break
      if (streak > 365) break;
    }

    return streak;
  }

  // Gamification (Badges = Completed Challenges)
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await _client
          .from('user_challenges')
          .select('*, challenges(*)')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  // Fasting Features
  Future<void> startFast() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Check if there is already an active fast
    final active = await getCurrentFast();
    if (active != null) return;

    await _client.from('fasting_logs').insert({
      'user_id': userId,
      'start_time': DateTime.now().toIso8601String(),
    }).select();
  }

  Future<void> endFast() async {
    final active = await getCurrentFast();
    if (active == null) return;

    final start = DateTime.parse(active['start_time']);
    final end = DateTime.now();
    final duration = end.difference(start).inMinutes;

    await _client
        .from('fasting_logs')
        .update({
          'end_time': end.toIso8601String(),
          'duration_minutes': duration,
        })
        .eq('id', active['id']);
  }

  Future<Map<String, dynamic>?> getCurrentFast() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('fasting_logs')
        .select()
        .eq('user_id', userId)
        .filter('end_time', 'is', null)
        .order('start_time', ascending: false) // Get latest if multiple
        .limit(1)
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getFastingHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('fasting_logs')
        .select()
        .eq('user_id', userId)
        .not('end_time', 'is', null) // Only completed fasts
        .order('end_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get Daily Meal Logs by Type
  Future<List<Map<String, dynamic>>> getDailyMealLogs(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();

    // Get all logs for the day, including nutrition_data and recipe_id
    final logs = await _client
        .from('daily_logs')
        .select('*, recipes(*)')
        .eq('user_id', userId)
        .gte('logged_at', startOfDay)
        .lte('logged_at', endOfDay);

    if (logs.isEmpty) return [];

    final List<Map<String, dynamic>> enrichedLogs = [];

    // Separate logs with food_id and logs with custom_food_name
    final List<String> foodIds = [];
    final List<String> customFoodNames = [];
    
    for (var log in logs) {
      if (log['food_id'] != null) {
        foodIds.add(log['food_id'] as String);
      } else if (log['custom_food_name'] != null) {
        customFoodNames.add(log['custom_food_name'] as String);
      }
    }

    // Fetch regular foods
    Map<String, Map<String, dynamic>> regularFoodsMap = {};
    if (foodIds.isNotEmpty) {
      final regularFoods = await _client
          .from('general_food_flow')
          .select()
          .filter('id', 'in', foodIds);
      
      for (var food in regularFoods) {
        regularFoodsMap[food['id'] as String] = food;
      }
    }

    // Fetch custom foods
    Map<String, Map<String, dynamic>> customFoodsMap = {};
    if (customFoodNames.isNotEmpty) {
      final allCustomFoods = await _client
          .from('user_custom_foods')
          .select()
          .eq('user_id', userId);
      
      // Match by name (case-insensitive)
      for (var customName in customFoodNames) {
        final matchedFood = allCustomFoods.firstWhere(
          (food) => (food['name'] as String?)?.toLowerCase() == customName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        
        if (matchedFood.isNotEmpty) {
          matchedFood['is_custom'] = true;
          customFoodsMap[customName] = matchedFood;
        }
      }
    }

    // Combine logs with food data
    for (var log in logs) {
      final enrichedLog = Map<String, dynamic>.from(log);
      
      if (log['food_id'] != null) {
        // Regular food
        final foodId = log['food_id'] as String;
        if (regularFoodsMap.containsKey(foodId)) {
          enrichedLog['general_food_flow'] = regularFoodsMap[foodId];
        }
      } else if (log['custom_food_name'] != null) {
        // Custom food
        final customName = log['custom_food_name'] as String;
        if (customFoodsMap.containsKey(customName)) {
          // Use 'general_food_flow' key for consistency with existing code
          enrichedLog['general_food_flow'] = customFoodsMap[customName];
        } else {
          // If custom food not found in map, create a basic entry with the name
          enrichedLog['general_food_flow'] = {
            'name': customName,
            'is_custom': true,
          };
        }
      }
      
      enrichedLogs.add(enrichedLog);
    }

    return enrichedLogs;
  }

  // ============ MARKETPLACE & ADD-ONS ============

  Future<List<Map<String, dynamic>>> getAvailableAddons() async {
    final response = await _client
        .from('available_addons')
        .select()
        .eq('is_active', true)
        .order('category');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserAddons() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('user_addons')
        .select('*, available_addons(*)')
        .eq('user_id', userId)
        .eq('is_active', true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> isAddonActive(String addonId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('user_addons')
        .select()
        .eq('user_id', userId)
        .eq('addon_id', addonId)
        .eq('is_active', true)
        .maybeSingle();

    return response != null;
  }

  Future<void> activateAddon(String addonId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_addons').upsert({
      'user_id': userId,
      'addon_id': addonId,
      'is_active': true,
      'activated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,addon_id').select();
  }

  Future<void> deactivateAddon(String addonId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_addons')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('addon_id', addonId);
  }

  // ============= SLEEP TRACKER ============

  Future<void> logSleep({
    required DateTime sleepDate,
    DateTime? bedtime,
    DateTime? wakeTime,
    double? durationHours,
    int? qualityRating,
    Map<String, int>? sleepStages,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('sleep_logs').upsert({
      'user_id': userId,
      'sleep_date': sleepDate.toIso8601String().split('T')[0],
      'bedtime': bedtime?.toIso8601String(),
      'wake_time': wakeTime?.toIso8601String(),
      'duration_hours': durationHours,
      'quality_rating': qualityRating,
      'sleep_stages': sleepStages ?? {},
      'notes': notes,
    }, onConflict: 'user_id,sleep_date');
  }

  Future<List<Map<String, dynamic>>> getSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('sleep_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('sleep_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('sleep_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getSleepLogForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .eq('sleep_date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    return response;
  }

  // ============= MOOD TRACKER ============

  Future<void> logMood({
    required DateTime logDate,
    String? mood,
    int? moodScore,
    int? energyLevel,
    int? stressLevel,
    List<String>? activities,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('mood_logs').upsert({
      'user_id': userId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'mood': mood,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'stress_level': stressLevel,
      'activities': activities ?? [],
      'notes': notes,
    }, onConflict: 'user_id,log_date');
  }

  Future<List<Map<String, dynamic>>> getMoodLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('mood_logs')
        .select()
        .eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('log_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('log_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('log_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getMoodLogForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    return response;
  }

  // ============= ADVANCED ANALYTICS ============

  Future<Map<String, dynamic>?> generateAnalyticsReport({
    required DateTime reportDate,
    required String reportType, // 'daily', 'weekly', 'monthly'
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Collect user data
      final profile = await getProfile();
      if (profile == null) return null;

      // Get date range based on report type
      DateTime startDate;
      if (reportType == 'daily') {
        startDate = reportDate;
      } else if (reportType == 'weekly') {
        startDate = reportDate.subtract(const Duration(days: 7));
      } else {
        startDate = reportDate.subtract(const Duration(days: 30));
      }

      // Collect nutrition data
      final mealLogs = await getDailyMealLogsRange(startDate, reportDate);
      final nutritionData = _aggregateNutritionData(mealLogs);

      // Collect exercise data
      final exerciseLogs = await getDailyExerciseLogsRange(startDate, reportDate);
      final exerciseData = _aggregateExerciseData(exerciseLogs);

      // Collect water data
      final waterLogs = await getWaterLogsRange(startDate, reportDate);
      final waterData = _aggregateWaterData(waterLogs);

      // Collect sleep data (if available)
      Map<String, dynamic>? sleepData;
      try {
        final sleepLogs = await getSleepLogs(startDate: startDate, endDate: reportDate);
        sleepData = _aggregateSleepData(sleepLogs);
      } catch (e) {
        // Sleep tracker might not be activated
        sleepData = null;
      }

      // Collect mood data (if available)
      Map<String, dynamic>? moodData;
      try {
        final moodLogs = await getMoodLogs(startDate: startDate, endDate: reportDate);
        moodData = _aggregateMoodData(moodLogs);
      } catch (e) {
        // Mood tracker might not be activated
        moodData = null;
      }

      // Prepare data for AI
      final userData = {
        'gender': profile['gender'],
        'age': profile['age'],
        'goal': profile['goal'],
        'current_weight': profile['current_weight'],
        'target_weight': profile['target_weight'],
        'activity_level': profile['activity_level'],
        'nutrition': nutritionData,
        'exercise': exerciseData,
        'water': waterData,
        'sleep': sleepData,
        'mood': moodData,
      };

      // Generate insights using AI
      final replicateService = ReplicateService();
      final insights = await replicateService.generateAnalyticsInsights(
        userData: userData,
        reportType: reportType,
      );

      // Save report to database
      final reportData = {
        'user_id': userId,
        'report_date': reportDate.toIso8601String().split('T')[0],
        'report_type': reportType,
        'insights': insights['insights'] ?? {},
        'recommendations': insights['recommendations'] ?? [],
        'trends': insights['trends'] ?? {},
        'summary': insights['summary'] ?? '',
      };

      await _client.from('analytics_reports').upsert(
        reportData,
        onConflict: 'user_id,report_date,report_type',
      );

      return {
        ...insights,
        'report_date': reportDate.toIso8601String().split('T')[0],
        'report_type': reportType,
      };
    } catch (e) {
      debugPrint('Error generating analytics report: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAnalyticsReports({
    String? reportType,
    int? limit,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('analytics_reports')
        .select()
        .eq('user_id', userId);

    if (reportType != null) {
      query = query.eq('report_type', reportType);
    }

    final orderedQuery = query.order('report_date', ascending: false);
    
    final response = limit != null 
        ? await orderedQuery.limit(limit)
        : await orderedQuery;
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getLatestAnalyticsReport({
    String? reportType,
  }) async {
    final reports = await getAnalyticsReports(reportType: reportType, limit: 1);
    if (reports.isEmpty) return null;
    return reports.first;
  }

  // Helper methods for data aggregation
  Map<String, dynamic> _aggregateNutritionData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return {'message': 'No nutrition data available for this period'};
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int mealCount = 0;
    Map<String, int> mealTypeCount = {};

    for (var log in logs) {
      totalCalories += (log['calories'] as num?)?.toDouble() ?? 0;
      totalProtein += (log['protein'] as num?)?.toDouble() ?? 0;
      totalCarbs += (log['carbs'] as num?)?.toDouble() ?? 0;
      totalFat += (log['fat'] as num?)?.toDouble() ?? 0;
      mealCount++;
      final mealType = log['meal_type'] as String? ?? 'UNKNOWN';
      mealTypeCount[mealType] = (mealTypeCount[mealType] ?? 0) + 1;
    }

    return {
      'total_calories': totalCalories,
      'avg_daily_calories': totalCalories / (logs.length / 3.0).clamp(1, double.infinity),
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'meal_count': mealCount,
      'meal_type_distribution': mealTypeCount,
      'days_tracked': (logs.length / 3.0).ceil(),
    };
  }

  Map<String, dynamic> _aggregateExerciseData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return {'message': 'No exercise data available for this period'};
    }

    int totalWorkouts = logs.length;
    double totalCaloriesBurned = 0;
    int totalDuration = 0;
    Map<String, int> exerciseTypeCount = {};

    for (var log in logs) {
      totalCaloriesBurned += (log['calories_burned'] as num?)?.toDouble() ?? 0;
      totalDuration += (log['duration_seconds'] as num?)?.toInt() ?? 0;
      // Exercise type would need to be fetched from exercises table
    }

    return {
      'total_workouts': totalWorkouts,
      'avg_workouts_per_week': (totalWorkouts / 7.0),
      'total_calories_burned': totalCaloriesBurned,
      'total_duration_minutes': (totalDuration / 60.0),
      'avg_duration_per_workout': (totalDuration / 60.0) / totalWorkouts.clamp(1, double.infinity),
    };
  }

  Map<String, dynamic> _aggregateWaterData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return {'message': 'No water data available for this period'};
    }

    int totalWater = 0;
    for (var log in logs) {
      totalWater += (log['amount_ml'] as num?)?.toInt() ?? 0;
    }

    return {
      'total_water_ml': totalWater,
      'avg_daily_water_ml': totalWater / (logs.length / 1.0).clamp(1, double.infinity),
      'days_tracked': logs.length,
    };
  }

  Map<String, dynamic> _aggregateSleepData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return {'message': 'No sleep data available for this period'};
    }

    double totalHours = 0;
    double totalQuality = 0;
    int qualityCount = 0;

    for (var log in logs) {
      totalHours += (log['duration_hours'] as num?)?.toDouble() ?? 0;
      if (log['quality_rating'] != null) {
        totalQuality += (log['quality_rating'] as num).toInt();
        qualityCount++;
      }
    }

    return {
      'total_sleep_hours': totalHours,
      'avg_sleep_hours': totalHours / logs.length.clamp(1, double.infinity),
      'avg_quality_rating': qualityCount > 0 ? totalQuality / qualityCount : null,
      'days_tracked': logs.length,
    };
  }

  Map<String, dynamic> _aggregateMoodData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return {'message': 'No mood data available for this period'};
    }

    double totalMoodScore = 0;
    double totalEnergy = 0;
    double totalStress = 0;
    int moodScoreCount = 0;
    int energyCount = 0;
    int stressCount = 0;
    Map<String, int> moodDistribution = {};

    for (var log in logs) {
      if (log['mood_score'] != null) {
        totalMoodScore += (log['mood_score'] as num).toInt();
        moodScoreCount++;
      }
      if (log['energy_level'] != null) {
        totalEnergy += (log['energy_level'] as num).toInt();
        energyCount++;
      }
      if (log['stress_level'] != null) {
        totalStress += (log['stress_level'] as num).toInt();
        stressCount++;
      }
      final mood = log['mood'] as String? ?? 'unknown';
      moodDistribution[mood] = (moodDistribution[mood] ?? 0) + 1;
    }

    return {
      'avg_mood_score': moodScoreCount > 0 ? totalMoodScore / moodScoreCount : null,
      'avg_energy_level': energyCount > 0 ? totalEnergy / energyCount : null,
      'avg_stress_level': stressCount > 0 ? totalStress / stressCount : null,
      'mood_distribution': moodDistribution,
      'days_tracked': logs.length,
    };
  }

  Future<List<Map<String, dynamic>>> getDailyMealLogsRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.add(const Duration(days: 1)).toIso8601String())
          .order('logged_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting meal logs range: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyExerciseLogsRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('exercise_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.add(const Duration(days: 1)).toIso8601String())
          .order('logged_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting exercise logs range: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWaterLogsRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('water_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.add(const Duration(days: 1)).toIso8601String())
          .order('logged_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting water logs range: $e');
      return [];
    }
  }

  // ============= CHALLENGES & GAMIFICATION ============

  Future<List<Map<String, dynamic>>> getChallenges() async {
    final response = await _client
        .from('challenges')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserChallenges() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('user_challenges')
        .select('*, challenges(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> joinChallenge(String challengeId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_challenges').upsert({
      'user_id': userId,
      'challenge_id': challengeId,
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,challenge_id');
  }

  Future<void> completeChallenge(
    String challengeId,
    String title,
    int reward,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Update status
    await _client
        .from('user_challenges')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('challenge_id', challengeId);

    // 2. Award coins
    final profile = await getProfile();
    final currentCoins = (profile?['coins'] as num?)?.toInt() ?? 0;
    await updateProfile({'coins': currentCoins + reward});

    // 3. Add to achievements (Palmares) - using title as badge
    List<String> achievements = List<String>.from(
      profile?['achievements'] ?? [],
    );
    if (!achievements.contains(title)) {
      achievements.add(title);
      await updateProfile({'achievements': achievements});
    }

    // 4. Record transaction
    await recordCoinTransaction(
      amount: reward,
      type: 'EARN',
      description: 'Completed challenge: $title',
    );
  }

  Future<List<String>> getAchievements() async {
    final profile = await getProfile();
    return List<String>.from(profile?['achievements'] ?? []);
  }

  // Sync achievements from completed challenges (for retroactive fixes)
  Future<void> syncAchievementsFromCompletedChallenges() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get all completed challenges for this user
      final completedChallenges = await _client
          .from('user_challenges')
          .select('*, challenges(title_en)')
          .eq('user_id', userId)
          .eq('status', 'completed');

      if (completedChallenges.isEmpty) return;

      final profile = await getProfile();
      List<String> achievements = List<String>.from(
        profile?['achievements'] ?? [],
      );

      bool updated = false;
      for (var uc in completedChallenges) {
        final challenge = uc['challenges'] as Map<String, dynamic>?;
        if (challenge == null) continue;
        
        final title = challenge['title_en'] as String?;
        if (title != null && !achievements.contains(title)) {
          achievements.add(title);
          updated = true;
        }
      }

      if (updated) {
        await updateProfile({'achievements': achievements});
      }
    } catch (e) {
      debugPrint('Error syncing achievements: $e');
    }
  }

  // ============================================
  // DIETS AND PROGRAMS MANAGEMENT
  // ============================================

  // Get all available diets
  Future<List<Map<String, dynamic>>> getAvailableDiets() async {
    final response = await _client
        .from('diets')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all available fitness programs
  Future<List<Map<String, dynamic>>> getAvailablePrograms() async {
    final response = await _client
        .from('fitness_programs')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get user's active diet
  Future<Map<String, dynamic>?> getActiveDiet() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_active_diets')
          .select('*, diets!inner(*)')
          .eq('user_id', userId)
          .eq('status', 'ACTIVE')
          .maybeSingle();
      
      if (response != null && response['diets'] is List && (response['diets'] as List).isNotEmpty) {
        response['diets'] = (response['diets'] as List).first;
      }
      return response;
    } catch (e) {
      debugPrint('Error getting active diet: $e');
      return null;
    }
  }

  // Get user's active program
  Future<Map<String, dynamic>?> getActiveProgram() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_active_programs')
          .select('*, fitness_programs!inner(*)')
          .eq('user_id', userId)
          .eq('status', 'ACTIVE')
          .maybeSingle();
      
      if (response != null && response['fitness_programs'] is List && (response['fitness_programs'] as List).isNotEmpty) {
        response['fitness_programs'] = (response['fitness_programs'] as List).first;
      }
      return response;
    } catch (e) {
      debugPrint('Error getting active program: $e');
      return null;
    }
  }

  // Activate a diet
  Future<void> activateDiet(String dietId, {int? durationWeeks}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get diet details
      final diet = await _client
          .from('diets')
          .select()
          .eq('id', dietId)
          .single();

      final weeks = durationWeeks ?? (diet['duration_weeks'] as int? ?? 8);
      final targetEndDate = DateTime.now().add(Duration(days: weeks * 7));

      // Deactivate any existing active diet
      await _client
          .from('user_active_diets')
          .update({'status': 'PAUSED'})
          .eq('user_id', userId)
          .eq('status', 'ACTIVE');

      // Insert new active diet
      await _client.from('user_active_diets').upsert({
        'user_id': userId,
        'diet_id': dietId,
        'started_at': DateTime.now().toIso8601String(),
        'target_end_date': targetEndDate.toIso8601String(),
        'current_week': 1,
        'status': 'ACTIVE',
      }, onConflict: 'user_id');

      // Update profile macro targets based on diet
      final macroRatios = diet['macro_ratios'] as Map<String, dynamic>?;
      if (macroRatios != null) {
        final profile = await getProfile();
        if (profile != null) {
          final calorieTarget = (profile['daily_calorie_target'] as int?) ?? 2000;
          final adjustment = (diet['daily_calorie_adjustment'] as int?) ?? 0;
          final newCalorieTarget = (calorieTarget + adjustment).clamp(1200, 5000);

          await updateProfile({
            'protein_target_percentage': (macroRatios['protein_percentage'] as num?)?.toInt() ?? 30,
            'carbs_target_percentage': (macroRatios['carbs_percentage'] as num?)?.toInt() ?? 40,
            'fat_target_percentage': (macroRatios['fat_percentage'] as num?)?.toInt() ?? 30,
            'daily_calorie_target': newCalorieTarget,
          });
        }
      }
    } catch (e) {
      debugPrint('Error activating diet: $e');
      rethrow;
    }
  }

  // Activate a fitness program
  Future<void> activateProgram(String programId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get program details
      final program = await _client
          .from('fitness_programs')
          .select()
          .eq('id', programId)
          .single();

      final weeks = program['duration_weeks'] as int? ?? 12;
      final targetEndDate = DateTime.now().add(Duration(days: weeks * 7));

      // Deactivate any existing active program
      await _client
          .from('user_active_programs')
          .update({'status': 'PAUSED'})
          .eq('user_id', userId)
          .eq('status', 'ACTIVE');

      // Insert new active program
      await _client.from('user_active_programs').upsert({
        'user_id': userId,
        'program_id': programId,
        'started_at': DateTime.now().toIso8601String(),
        'target_end_date': targetEndDate.toIso8601String(),
        'current_week': 1,
        'status': 'ACTIVE',
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error activating program: $e');
      rethrow;
    }
  }

  // Pause active diet
  Future<void> pauseDiet() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_diets')
        .update({'status': 'PAUSED'})
        .eq('user_id', userId)
        .eq('status', 'ACTIVE');
  }

  // Resume paused diet
  Future<void> resumeDiet() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_diets')
        .update({'status': 'ACTIVE'})
        .eq('user_id', userId)
        .eq('status', 'PAUSED');
  }

  // Pause active program
  Future<void> pauseProgram() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_programs')
        .update({'status': 'PAUSED'})
        .eq('user_id', userId)
        .eq('status', 'ACTIVE');
  }

  // Resume paused program
  Future<void> resumeProgram() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_programs')
        .update({'status': 'ACTIVE'})
        .eq('user_id', userId)
        .eq('status', 'PAUSED');
  }

  // Deactivate diet
  Future<void> deactivateDiet() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_diets')
        .update({'status': 'COMPLETED'})
        .eq('user_id', userId)
        .eq('status', 'ACTIVE');
  }

  // Deactivate program
  Future<void> deactivateProgram() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_active_programs')
        .update({'status': 'COMPLETED'})
        .eq('user_id', userId)
        .eq('status', 'ACTIVE');
  }

  // Update diet compliance (called daily)
  Future<void> updateDietCompliance(double complianceScore, {
    int? mealsLogged,
    int? restrictedFoodsCount,
    Map<String, double>? macroCompliance,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final activeDiet = await getActiveDiet();
    if (activeDiet == null) return;

    final dietId = activeDiet['diet_id'] as String;
    final today = DateTime.now();
    final logDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _client.from('diet_compliance_logs').upsert({
      'user_id': userId,
      'diet_id': dietId,
      'log_date': logDate,
      'compliance_score': complianceScore,
      'meals_logged': mealsLogged ?? 0,
      'restricted_foods_count': restrictedFoodsCount ?? 0,
      'macro_compliance': macroCompliance ?? {},
    }, onConflict: 'user_id,diet_id,log_date');

    // Update active diet compliance score (average of last 7 days)
    final last7Days = await _client
        .from('diet_compliance_logs')
        .select('compliance_score')
        .eq('user_id', userId)
        .eq('diet_id', dietId)
        .order('log_date', ascending: false)
        .limit(7);

    if (last7Days.isNotEmpty) {
      final avgScore = last7Days
          .map((log) => (log['compliance_score'] as num?)?.toDouble() ?? 0.0)
          .reduce((a, b) => a + b) /
          last7Days.length;

      await _client
          .from('user_active_diets')
          .update({'compliance_score': avgScore})
          .eq('user_id', userId)
          .eq('diet_id', dietId);
    }
  }

  // Update program progress
  Future<void> updateProgramProgress(int week, int day, {
    String? workoutType,
    int? exercisesCompleted,
    int? totalExercises,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final activeProgram = await getActiveProgram();
    if (activeProgram == null) return;

    final programId = activeProgram['program_id'] as String;

    await _client.from('program_progress_logs').upsert({
      'user_id': userId,
      'program_id': programId,
      'week': week,
      'day': day,
      'workout_type': workoutType,
      'exercises_completed': exercisesCompleted ?? 0,
      'total_exercises': totalExercises ?? 0,
    }, onConflict: 'user_id,program_id,week,day');

    // Calculate overall completion percentage
    final allLogs = await _client
        .from('program_progress_logs')
        .select()
        .eq('user_id', userId)
        .eq('program_id', programId);

    if (allLogs.isNotEmpty) {
      final totalWorkouts = allLogs.length;
      final completedWorkouts = allLogs
          .where((log) => (log['exercises_completed'] as int? ?? 0) > 0)
          .length;

      final completionPercentage = (completedWorkouts / totalWorkouts) * 100;

      await _client
          .from('user_active_programs')
          .update({'completion_percentage': completionPercentage})
          .eq('user_id', userId)
          .eq('program_id', programId);
    }
  }

  Future<void> checkChallengeProgress() async {
    final active = await getUserChallenges();
    final now = DateTime.now();

    for (var uc in active) {
      if (uc['status'] != 'active') continue;

      final challenge = uc['challenges'];
      if (challenge == null) continue;

      final type = challenge['goal_type'];
      final target = (challenge['goal_value'] as num?)?.toDouble() ?? 1.0;
      double currentProgress = 0;

      if (type == 'WATER') {
        final logs = await getDailyWaterLogs(now);
        currentProgress = logs.fold(
          0.0,
          (sum, item) => sum + (item['amount_ml'] as num).toDouble(),
        );
      } else if (type == 'PROTEIN') {
        final logs = await getDailyMealLogs(now);
        currentProgress = logs.fold<double>(
          0.0,
          (sum, item) {
            // Try nutrition_data first
            final nutritionData = item['nutrition_data'] as Map<String, dynamic>?;
            if (nutritionData != null && nutritionData.isNotEmpty) {
              final value = nutritionData['protein'] as num?;
              return sum + (value?.toDouble() ?? 0.0);
            }
            // Fallback to old protein field
            final value = item['protein'] as num?;
            return sum + (value?.toDouble() ?? 0.0);
          },
        );
      } else if (type == 'WORKOUT') {
        final logs = await getDailyExerciseLogs(now);
        currentProgress = logs.length.toDouble();
      } else if (type == 'FASTING') {
        final fasts = await getFastingHistory();
        // Check if any fast completed today meets the requirement
        for (var f in fasts) {
          if (f['end_time'] != null) {
            final end = DateTime.parse(f['end_time']);
            if (end.year == now.year &&
                end.month == now.month &&
                end.day == now.day) {
              final start = DateTime.parse(f['start_time']);
              final hours = end.difference(start).inHours;
              if (hours > currentProgress) currentProgress = hours.toDouble();
            }
          }
        }
      } else if (type == 'STREAK') {
        currentProgress = (await getStreakCount()).toDouble();
      } else {
        // Handle all nutrient-based challenges (CALCIUM, IRON, VITAMIN_D, etc.)
        final logs = await getDailyMealLogs(now);
        final nutrientKey = type.toLowerCase();
        
        currentProgress = logs.fold(
          0.0,
          (sum, item) {
            // Priority 1: nutrition_data JSONB
            final nutritionData = item['nutrition_data'] as Map<String, dynamic>?;
            if (nutritionData != null && nutritionData.isNotEmpty) {
              final value = nutritionData[nutrientKey] as num?;
              if (value != null) return sum + value.toDouble();
            }
            
            // Priority 2: recipe data
            final recipeId = item['recipe_id'] as String?;
            if (recipeId != null) {
              final recipe = item['recipes'] as Map<String, dynamic>?;
              if (recipe != null) {
                final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
                final factor = quantity / servings;
                final value = recipe[nutrientKey] as num?;
                if (value != null) return sum + (value.toDouble() * factor);
              }
            }
            
            // Priority 3: general_food_flow
            final foodData = item['general_food_flow'] as Map<String, dynamic>?;
            if (foodData != null) {
              final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
              final multiplier = quantity / 100.0;
              final value = foodData[nutrientKey] as num?;
              if (value != null) return sum + (value.toDouble() * multiplier);
            }
            
            return sum;
          },
        );
        
        // Special handling for combined challenges
        if (type == 'MICRONUTRIENT_COUNT') {
          // Count how many micronutrients reached RDA
          final logs = await getDailyMealLogs(now);
          final reachedNutrients = <String>{};
          
          // Define RDAs for common nutrients
          final rdas = {
            'calcium': 1000.0,
            'iron': 18.0,
            'vitamin_d': 20.0,
            'vitamin_c': 90.0,
            'magnesium': 400.0,
            'zinc': 11.0,
            'selenium': 55.0,
            'iodine': 150.0,
            'chromium': 35.0,
            'potassium': 3500.0,
            'folate': 400.0,
            'vitamin_b12': 2.4,
          };
          
          for (var log in logs) {
            final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
            if (nutritionData != null) {
              for (var entry in rdas.entries) {
                final value = (nutritionData[entry.key] as num?)?.toDouble() ?? 0.0;
                if (value >= entry.value) {
                  reachedNutrients.add(entry.key);
                }
              }
            }
          }
          
          currentProgress = reachedNutrients.length.toDouble();
        } else if (type == 'PERFECT_DAY' || type == 'PERFECT_WEEK') {
          // This would require checking all RDAs - complex logic
          // For now, set a placeholder that needs manual implementation
          currentProgress = 0.0;
        }
      }

      // Update progress in DB if it changed
      final oldProgress = (uc['current_progress'] as num?)?.toDouble() ?? 0.0;
      if (currentProgress != oldProgress) {
        await _client
            .from('user_challenges')
            .update({
              'current_progress': currentProgress,
              if (currentProgress >= target) 'status': 'completed',
              if (currentProgress >= target)
                'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('id', uc['id']);

        if (currentProgress >= target) {
          // Award reward automatically if completed
          final reward = challenge['reward_coins'] as int? ?? 50;
          final title = challenge['title_en'] as String? ?? 'Challenge';

          final profile = await getProfile();
          final currentCoins = (profile?['coins'] as num?)?.toInt() ?? 0;
          await updateProfile({'coins': currentCoins + reward});

          // Add to achievements if not already present
          List<String> achievements = List<String>.from(
            profile?['achievements'] ?? [],
          );
          if (!achievements.contains(title)) {
            achievements.add(title);
            await updateProfile({'achievements': achievements});
          }

          await recordCoinTransaction(
            amount: reward,
            type: 'EARN',
            description: 'Completed challenge: $title',
          );
        }
      }
    }
  }

  // ============ MENSTRUATION TRACKER ============

  // Setup & Configuration
  Future<Map<String, dynamic>?> getMenstruationSetup() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('menstruation_setup')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  Future<void> saveMenstruationSetup({
    required DateTime lastPeriodStart,
    required int averageCycleLength,
    required int averagePeriodLength,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('menstruation_setup').upsert({
      'user_id': userId,
      'last_period_start': lastPeriodStart.toIso8601String().split('T')[0],
      'average_cycle_length': averageCycleLength,
      'average_period_length': averagePeriodLength,
      'tracking_since': DateTime.now().toIso8601String().split('T')[0],
    }, onConflict: 'user_id').select();
  }

  // Period Logs
  Future<List<Map<String, dynamic>>> getMenstruationLogs({
    int limit = 12,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('menstruation_logs')
        .select()
        .eq('user_id', userId)
        .order('period_start', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> logPeriod({
    required DateTime periodStart,
    DateTime? periodEnd,
    String? flowIntensity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = {
      'user_id': userId,
      'period_start': periodStart.toIso8601String().split('T')[0],
      if (periodEnd != null)
        'period_end': periodEnd.toIso8601String().split('T')[0],
      if (flowIntensity != null) 'flow_intensity': flowIntensity,
      if (notes != null) 'notes': notes,
    };

    await _client.from('menstruation_logs').insert(data).select();
  }

  Future<void> updatePeriodEnd(String logId, DateTime periodEnd) async {
    await _client
        .from('menstruation_logs')
        .update({'period_end': periodEnd.toIso8601String().split('T')[0]})
        .eq('id', logId);
  }

  // Symptoms Tracking
  Future<Map<String, dynamic>?> getSymptomsForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('menstruation_symptoms')
        .select()
        .eq('user_id', userId)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getSymptomsForMonth(DateTime month) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final response = await _client
        .from('menstruation_symptoms')
        .select()
        .eq('user_id', userId)
        .gte('date', startOfMonth.toIso8601String().split('T')[0])
        .lte('date', endOfMonth.toIso8601String().split('T')[0])
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSymptomHistory({int limit = 14}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('menstruation_symptoms')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveSymptoms({
    required DateTime date,
    required List<String> symptoms,
    String? mood,
    int? energyLevel,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('menstruation_symptoms').upsert({
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'symptoms': symptoms,
      if (mood != null) 'mood': mood,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (notes != null) 'notes': notes,
    }, onConflict: 'user_id,date').select();
  }

  // Cycle Calculations
  Map<String, dynamic> calculateCycleInfo(Map<String, dynamic> setup) {
    final lastPeriodStr = setup['last_period_start'] as String?;
    if (lastPeriodStr == null) {
      return {
        'cycleDay': 0,
        'daysUntilNext': 0,
        'currentPhase': 'Unknown',
        'isFertile': false,
      };
    }

    final lastPeriod = DateTime.parse(lastPeriodStr);
    final today = DateTime.now();
    final cycleLength = setup['average_cycle_length'] as int? ?? 28;

    final daysSinceLastPeriod = today.difference(lastPeriod).inDays;
    final cycleDay = (daysSinceLastPeriod % cycleLength) + 1;
    final daysUntilNext = cycleLength - cycleDay;

    // Calculate phase
    String phase;
    bool isFertile = false;

    if (cycleDay <= 5) {
      phase = 'Menstrual';
    } else if (cycleDay <= 13) {
      phase = 'Follicular';
    } else if (cycleDay <= 15) {
      phase = 'Ovulation';
      isFertile = true;
    } else {
      phase = 'Luteal';
    }

    // Fertile window (typically days 11-16)
    if (cycleDay >= 11 && cycleDay <= 16) {
      isFertile = true;
    }

    return {
      'cycleDay': cycleDay,
      'daysUntilNext': daysUntilNext,
      'currentPhase': phase,
      'isFertile': isFertile,
      'ovulationDay': 14,
      'fertileStart': 11,
      'fertileEnd': 16,
    };
  }

  // ============ EXERCISE SYSTEM ============

  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    final userId = getCurrentUserId();
    final List<Map<String, dynamic>> results = [];

    if (query.trim().isEmpty) {
      // If empty query, return all general exercises (limit to 50 for performance)
      final generalResponse = await _client
          .from('exercises')
          .select()
          .order('name_en')
          .limit(50);
      
      for (var exercise in generalResponse) {
        final exerciseMap = Map<String, dynamic>.from(exercise);
        exerciseMap['is_custom'] = false;
        results.add(exerciseMap);
      }

      // Also get user's custom exercises
      if (userId != null) {
        final customResponse = await _client
            .from('user_custom_exercises')
            .select()
            .eq('user_id', userId)
            .order('name_en')
            .limit(50);
        
        for (var exercise in customResponse) {
          final exerciseMap = Map<String, dynamic>.from(exercise);
          exerciseMap['is_custom'] = true;
          results.add(exerciseMap);
        }
      }

      return results;
    }

    // Search in general exercises
    final generalResponse = await _client
        .from('exercises')
        .select()
        .or('name_en.ilike.%$query%,name_de.ilike.%$query%')
        .order('name_en')
        .limit(50);
    
    for (var exercise in generalResponse) {
      final exerciseMap = Map<String, dynamic>.from(exercise);
      exerciseMap['is_custom'] = false;
      results.add(exerciseMap);
    }

    // Search in user's custom exercises
    if (userId != null) {
      final customResponse = await _client
          .from('user_custom_exercises')
          .select()
          .eq('user_id', userId)
          .or('name_en.ilike.%$query%,name_de.ilike.%$query%')
          .order('name_en')
          .limit(50);
      
      for (var exercise in customResponse) {
        final exerciseMap = Map<String, dynamic>.from(exercise);
        exerciseMap['is_custom'] = true;
        results.add(exerciseMap);
      }
    }

    return results;
  }

  // Create custom exercise with AI-generated details
  Future<Map<String, dynamic>> createCustomExerciseWithAI(
    String exerciseName,
    Map<String, dynamic> aiExerciseData, {
    String language = 'en',
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if exercise already exists for this user
      final existing = await _client
          .from('user_custom_exercises')
          .select()
          .eq('user_id', userId)
          .eq('name_en', exerciseName)
          .maybeSingle();

      if (existing != null) {
        debugPrint('Custom exercise already exists: $exerciseName');
        return existing;
      }

      // Insert new custom exercise
      final response = await _client
          .from('user_custom_exercises')
          .insert({
            'user_id': userId,
            'name_en': aiExerciseData['name_en'] ?? exerciseName,
            'name_de': aiExerciseData['name_de'] ?? aiExerciseData['name_en'] ?? exerciseName,
            'muscle_group': aiExerciseData['muscle_group'] ?? 'Full Body',
            'equipment': aiExerciseData['equipment'] ?? 'None',
            'difficulty': aiExerciseData['difficulty'] ?? 'Beginner',
            'instructions_en': aiExerciseData['instructions_en'] ?? '',
            'instructions_de': aiExerciseData['instructions_de'] ?? aiExerciseData['instructions_en'] ?? '',
            'calories_per_rep': aiExerciseData['calories_per_rep'] ?? 0.5,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('Custom exercise created: ${response['name_en']}');
      return response;
    } catch (e) {
      debugPrint('Error creating custom exercise: $e');
      rethrow;
    }
  }

  // Update custom exercise
  Future<void> updateCustomExercise({
    required String exerciseId,
    required String nameEn,
    String? nameDe,
    required String muscleGroup,
    required String equipment,
    required String difficulty,
    required String instructionsEn,
    String? instructionsDe,
    required double caloriesPerRep,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('user_custom_exercises')
          .update({
            'name_en': nameEn,
            'name_de': nameDe ?? nameEn,
            'muscle_group': muscleGroup,
            'equipment': equipment,
            'difficulty': difficulty,
            'instructions_en': instructionsEn,
            'instructions_de': instructionsDe ?? instructionsEn,
            'calories_per_rep': caloriesPerRep,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', exerciseId)
          .eq('user_id', userId); // Ensure user owns this exercise

      debugPrint('Custom exercise updated: $nameEn');
    } catch (e) {
      debugPrint('Error updating custom exercise: $e');
      rethrow;
    }
  }

  // Get exercises filtered by muscle group
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(String muscleGroup) async {
    final response = await _client
        .from('exercises')
        .select()
        .eq('muscle_group', muscleGroup)
        .order('name_en');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get exercises filtered by equipment
  Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipment) async {
    final response = await _client
        .from('exercises')
        .select()
        .eq('equipment', equipment)
        .order('name_en');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get exercises filtered by difficulty
  Future<List<Map<String, dynamic>>> getExercisesByDifficulty(String difficulty) async {
    final response = await _client
        .from('exercises')
        .select()
        .eq('difficulty', difficulty)
        .order('name_en');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all unique muscle groups
  Future<List<String>> getMuscleGroups() async {
    final response = await _client
        .from('exercises')
        .select('muscle_group')
        .order('muscle_group');
    
    final groups = <String>{};
    for (var item in response) {
      final group = item['muscle_group'] as String?;
      if (group != null) groups.add(group);
    }
    return groups.toList()..sort();
  }

  // Get all unique equipment types
  Future<List<String>> getEquipmentTypes() async {
    final response = await _client
        .from('exercises')
        .select('equipment')
        .order('equipment');
    
    final equipment = <String>{};
    for (var item in response) {
      final eq = item['equipment'] as String?;
      if (eq != null) equipment.add(eq);
    }
    return equipment.toList()..sort();
  }

  // Get exercises with multiple filters
  Future<List<Map<String, dynamic>>> getExercisesFiltered({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? searchQuery,
  }) async {
    var query = _client.from('exercises').select();
    
    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      query = query.eq('muscle_group', muscleGroup);
    }
    
    if (equipment != null && equipment.isNotEmpty) {
      query = query.eq('equipment', equipment);
    }
    
    if (difficulty != null && difficulty.isNotEmpty) {
      query = query.eq('difficulty', difficulty);
    }
    
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.or('name_en.ilike.%${searchQuery.trim()}%,name_de.ilike.%${searchQuery.trim()}%');
    }
    
    final response = await query.order('name_en').limit(100);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> logExercise({
    required Map<String, dynamic>
    exercise, // Full exercise object to get calories_per_rep
    int sets = 1,
    int reps = 0,
    double weightKg = 0,
    int durationSeconds = 0,
    double? caloriesBurned, // Optional: pass calculated calories, otherwise use simple formula
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Use provided calories or calculate with simple formula
    final totalBurned = caloriesBurned ?? 
        ((exercise['calories_per_rep'] as num?)?.toDouble() ?? 0.5) * sets * reps + (durationSeconds * 0.1);

    final isCustom = exercise['is_custom'] == true;
    final logData = <String, dynamic>{
      'user_id': userId,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_seconds': durationSeconds,
      'calories_burned': totalBurned,
      'logged_at': DateTime.now().toIso8601String(),
    };

    // Use exercise_id or custom_exercise_id based on type
    if (isCustom) {
      logData['custom_exercise_id'] = exercise['id'];
    } else {
      logData['exercise_id'] = exercise['id'];
    }

    final response = await _client.from('exercise_logs').insert(logData).select().single();

    return {
      'log_id': response['id'],
      'calories_burned': totalBurned,
      'exercise': exercise,
    };
  }

  // Save workout routine
  Future<void> saveWorkoutRoutine({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
    double? totalCalories,
    List<String>? muscleGroups,
    String? difficulty,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _client.from('workout_routines').insert({
      'user_id': userId,
      'name': name,
      'description': description,
      'exercises': exercises,
      'total_calories': totalCalories,
      'muscle_groups': muscleGroups,
      'difficulty': difficulty,
    });
  }

  // Plan workout
  Future<void> planWorkout({
    required DateTime scheduledDate,
    TimeOfDay? scheduledTime,
    required List<Map<String, dynamic>> exercises,
    String? notes,
    String? routineId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final scheduledTimeStr = scheduledTime != null
        ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00'
        : null;

    final dateStr = scheduledDate.toIso8601String().split('T')[0]; // Date only (YYYY-MM-DD)

    await _client.from('planned_workouts').insert({
      'user_id': userId,
      'routine_id': routineId,
      'scheduled_date': dateStr,
      'scheduled_time': scheduledTimeStr,
      'exercises': exercises,
      'notes': notes,
      'status': 'PLANNED',
    });
  }

  // Get workout routines
  Future<List<Map<String, dynamic>>> getWorkoutRoutines() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('workout_routines')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get planned workouts
  Future<List<Map<String, dynamic>>> getPlannedWorkouts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('planned_workouts')
        .select()
        .eq('user_id', userId)
        .eq('status', 'PLANNED');

    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('scheduled_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Delete planned workout
  Future<void> deletePlannedWorkout(String workoutId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _client
        .from('planned_workouts')
        .delete()
        .eq('id', workoutId)
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getDailyExerciseLogs(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();

    // Get all logs for the day
    final response = await _client
        .from('exercise_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_at', startOfDay)
        .lte('logged_at', endOfDay)
        .order('logged_at', ascending: false);

    final logs = List<Map<String, dynamic>>.from(response);
    
    // Collect all IDs to fetch in batch (more efficient than individual queries)
    final exerciseIds = <String>[];
    final customExerciseIds = <String>[];
    
    for (var log in logs) {
      final exerciseId = log['exercise_id'] as String?;
      final customExerciseId = log['custom_exercise_id'] as String?;
      
      if (exerciseId != null) {
        exerciseIds.add(exerciseId);
      }
      if (customExerciseId != null) {
        customExerciseIds.add(customExerciseId);
      }
    }
    
    // Fetch all exercises in batch
    Map<String, Map<String, dynamic>> exercisesMap = {};
    Map<String, Map<String, dynamic>> customExercisesMap = {};
    
    if (exerciseIds.isNotEmpty) {
      try {
        final exercises = await _client
            .from('exercises')
            .select()
            .inFilter('id', exerciseIds);
        for (var ex in exercises) {
          exercisesMap[ex['id'] as String] = ex;
        }
      } catch (e) {
        debugPrint('Error fetching exercises: $e');
      }
    }
    
    if (customExerciseIds.isNotEmpty) {
      try {
        final customExercises = await _client
            .from('user_custom_exercises')
            .select()
            .eq('user_id', userId)
            .inFilter('id', customExerciseIds);
        for (var ex in customExercises) {
          customExercisesMap[ex['id'] as String] = ex;
        }
      } catch (e) {
        debugPrint('Error fetching custom exercises: $e');
      }
    }
    
    // Enrich logs with exercise data
    final List<Map<String, dynamic>> enrichedLogs = [];
    debugPrint('[getDailyExerciseLogs] Processing ${logs.length} logs');
    debugPrint('[getDailyExerciseLogs] Found ${exerciseIds.length} general exercise IDs and ${customExerciseIds.length} custom exercise IDs');
    
    for (var log in logs) {
      final exerciseId = log['exercise_id'] as String?;
      final customExerciseId = log['custom_exercise_id'] as String?;
      
      debugPrint('[getDailyExerciseLogs] Processing log: exercise_id=$exerciseId, custom_exercise_id=$customExerciseId');
      
      Map<String, dynamic>? exerciseData;
      bool isCustom = false;
      
      if (customExerciseId != null && customExercisesMap.containsKey(customExerciseId)) {
        exerciseData = customExercisesMap[customExerciseId];
        isCustom = true;
        debugPrint('[getDailyExerciseLogs] Found custom exercise: ${exerciseData?['name_en']}');
      } else if (exerciseId != null && exercisesMap.containsKey(exerciseId)) {
        exerciseData = exercisesMap[exerciseId];
        isCustom = false;
        debugPrint('[getDailyExerciseLogs] Found general exercise: ${exerciseData?['name_en']}');
      } else {
        debugPrint('[getDailyExerciseLogs] WARNING: Exercise data not found for log! exercise_id=$exerciseId, custom_exercise_id=$customExerciseId');
        debugPrint('[getDailyExerciseLogs] Available exercise IDs: ${exercisesMap.keys}');
        debugPrint('[getDailyExerciseLogs] Available custom exercise IDs: ${customExercisesMap.keys}');
      }
      
      if (exerciseData != null) {
        final enrichedLog = Map<String, dynamic>.from(log);
        enrichedLog['exercises'] = exerciseData;
        enrichedLog['is_custom'] = isCustom;
        enrichedLogs.add(enrichedLog);
      } else {
        debugPrint('[getDailyExerciseLogs] Skipping log because exercise data is missing');
      }
    }

    debugPrint('[getDailyExerciseLogs] Returning ${enrichedLogs.length} enriched logs');
    return enrichedLogs;
  }
    // ============ ADVANCED HEALTH ANALYTICS ============

  Future<Map<String, double>> getDailyMicronutrients(DateTime date) async {
    final logs = await getDailyMealLogs(date);
    final totals = <String, double>{};

    for (var log in logs) {
      // Priority 1: Check nutrition_data JSONB (for recipes and custom foods with full nutrition)
      final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
      if (nutritionData != null && nutritionData.isNotEmpty) {
        // nutrition_data already contains calculated values for the logged quantity
        NutritionUtils.microNutrientRDA.keys.forEach((key) {
          final val = (nutritionData[key] as num?)?.toDouble() ?? 0.0;
          totals[key] = (totals[key] ?? 0.0) + val;
        });
        
        // Also track "Nasties"
        NutritionUtils.nutrientWarningThresholds.keys.forEach((key) {
          final val = (nutritionData[key] as num?)?.toDouble() ?? 0.0;
          totals[key] = (totals[key] ?? 0.0) + val;
        });
        continue;
      }
      
      // Priority 2: Check recipe_id (link to recipes table with full nutrition)
      final recipeId = log['recipe_id'] as String?;
      if (recipeId != null) {
        final recipe = log['recipes'] as Map<String, dynamic>?;
        if (recipe != null) {
          final quantity = (log['quantity'] as num).toDouble();
          final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
          final factor = quantity / servings; // Calculate factor based on servings
          
          NutritionUtils.microNutrientRDA.keys.forEach((key) {
            final val = ((recipe[key] as num?)?.toDouble() ?? 0.0) * factor;
            totals[key] = (totals[key] ?? 0.0) + val;
          });
          
          // Also track "Nasties"
          NutritionUtils.nutrientWarningThresholds.keys.forEach((key) {
            final val = ((recipe[key] as num?)?.toDouble() ?? 0.0) * factor;
            totals[key] = (totals[key] ?? 0.0) + val;
          });
          continue;
        }
      }
      
      // Priority 3: Check general_food_flow (regular foods from database)
      final food = log['general_food_flow'] as Map<String, dynamic>?;
      if (food != null) {
        final quantity = (log['quantity'] as num).toDouble();
        // Normalize: database usually stores per 100g/ml
        // If quantity is in grams, we multiply by quantity/100
        final factor = quantity / 100.0;

        NutritionUtils.microNutrientRDA.keys.forEach((key) {
          final val = (food[key] as num?)?.toDouble() ?? 0.0;
          totals[key] = (totals[key] ?? 0.0) + (val * factor);
        });
        
        // Also track "Nasties"
        NutritionUtils.nutrientWarningThresholds.keys.forEach((key) {
          final val = (food[key] as num?)?.toDouble() ?? 0.0;
          totals[key] = (totals[key] ?? 0.0) + (val * factor);
        });
      }
    }
    
    return totals;
  }

  Future<List<Map<String, dynamic>>> getSmartFoodSuggestions({
    required String targetNutrient, // e.g., 'protein', 'iron', 'vitamin_c'
    required double minAmount,      // Minimum amount of nutrient per 100g
    int limit = 5,
  }) async {
    // Queries foods high in target nutrient but low in sugar/saturated fat
    final response = await _client
        .from('general_food_flow')
        .select()
        .gte(targetNutrient, minAmount)
        .lte('sugar', 10) // Filter out sugary stuff
        .lte('saturated_fat', 5) // Filter out unhealthy fats
        .order(targetNutrient, ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============ RECIPES ============

  Future<List<Map<String, dynamic>>> getRecipes({
    String? query,
    String? mealType,
    String? dietType,
    String? cuisineType,
    String? tag,
    bool featured = false,
    int limit = 50,
  }) async {
    try {
      dynamic recipesQuery = _client.from('recipes').select('''
        *,
        recipe_tags(tag)
      ''').eq('is_public', true);

      if (featured) {
        recipesQuery = recipesQuery.eq('is_featured', true);
      }

      if (query != null && query.isNotEmpty) {
        recipesQuery = recipesQuery.or('title_en.ilike.%$query%,title_de.ilike.%$query%');
      }

      if (mealType != null) {
        recipesQuery = recipesQuery.eq('recommended_meal_type', mealType);
      }

      if (dietType != null) {
        recipesQuery = recipesQuery.eq('diet_type', dietType);
      }

      if (cuisineType != null) {
        recipesQuery = recipesQuery.eq('cuisine_type', cuisineType);
      }

      // Note: Tag filtering needs to be done after fetching, as Supabase doesn't support
      // direct filtering on joined tables easily. We'll filter in memory.
      final response = await recipesQuery
          .order('created_at', ascending: false)
          .limit(limit);

      List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(response);

      // Filter by tag if specified (filter in memory after fetching)
      if (tag != null && tag.isNotEmpty) {
        recipes = recipes.where((recipe) {
          final tags = recipe['recipe_tags'] as List<dynamic>?;
          if (tags == null || tags.isEmpty) return false;
          return tags.any((t) => (t['tag'] as String?)?.toLowerCase() == tag.toLowerCase());
        }).toList();
      }

      // Set default values for ratings
      for (var recipe in recipes) {
        recipe['average_rating'] = 0.0;
        recipe['rating_count'] = 0;
        recipe['likes_count'] = recipe['likes_count'] ?? 0;
        recipe['views_count'] = recipe['views_count'] ?? 0;
        recipe['times_cooked'] = recipe['times_cooked'] ?? 0;
      }
      
      debugPrint('[DEBUG] getRecipes: Found ${recipes.length} recipes');
      return recipes;
    } catch (e) {
      debugPrint('[ERROR] Error in getRecipes: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyRecipes() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final response = await _client
        .from('recipes')
        .select('''
      *,
      recipe_tags(tag),
      recipe_votes(rating)
    ''')
        .eq('created_by_user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getFavoriteRecipes() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final response = await _client
        .from('user_saved_recipes')
        .select('''
      recipe_id,
      recipes:recipe_id (
        *,
        recipe_tags(tag),
        recipe_votes(rating)
      )
    ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> saved = List<Map<String, dynamic>>.from(response);
    return saved.map((s) => s['recipes'] as Map<String, dynamic>).toList();
  }

  Future<void> favoriteRecipe(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Check if already favorited
    final existing = await _client
        .from('user_saved_recipes')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('user_saved_recipes').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    }
  }

  Future<void> unfavoriteRecipe(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _client
        .from('user_saved_recipes')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
  }

  Future<bool> isRecipeFavorited(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final response = await _client
        .from('user_saved_recipes')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    return response != null;
  }

  Future<bool> isRecipeLiked(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final response = await _client
        .from('recipe_votes')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    return response != null;
  }

  Future<void> likeRecipe(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Check if already liked
    final existing = await _client
        .from('recipe_votes')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (existing == null) {
      // Add like (rating 5 = like)
      await _client.from('recipe_votes').insert({
        'user_id': userId,
        'recipe_id': recipeId,
        'rating': 5,
      });

      // Increment likes_count - use update instead of RPC
      final currentRecipe = await _client
          .from('recipes')
          .select('likes_count')
          .eq('id', recipeId)
          .maybeSingle();
      
      final currentLikes = (currentRecipe?['likes_count'] as num?)?.toInt() ?? 0;
      await _client
          .from('recipes')
          .update({'likes_count': currentLikes + 1})
          .eq('id', recipeId);
    }
  }

  Future<void> unlikeRecipe(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _client
        .from('recipe_votes')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);

    // Decrement likes_count - use update instead of RPC
    final currentRecipe = await _client
        .from('recipes')
        .select('likes_count')
        .eq('id', recipeId)
        .maybeSingle();
    
    final currentLikes = (currentRecipe?['likes_count'] as num?)?.toInt() ?? 0;
    await _client
        .from('recipes')
        .update({'likes_count': (currentLikes - 1).clamp(0, double.infinity).toInt()})
        .eq('id', recipeId);
  }

  Future<void> voteRecipe(String recipeId, int rating) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    // Upsert vote
    await _client.from('recipe_votes').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'rating': rating,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int?> getUserRecipeRating(String recipeId) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await _client
        .from('recipe_votes')
        .select('rating')
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    return response?['rating'] as int?;
  }

  Future<void> logRecipeAsMeal({
    required String recipeId,
    required String mealType,
    required double quantity,
    required String unit,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Get recipe with ALL nutritional data
    final recipe = await _client
        .from('recipes')
        .select()
        .eq('id', recipeId)
        .maybeSingle();

    if (recipe == null) return;

    // Calculate nutrition based on quantity
    final servings = recipe['servings'] as num? ?? 1;
    final factor = quantity / servings;

    // Extract ALL nutritional values from recipe and multiply by factor
    // This ensures we track ALL nutrients, not just macros
    final nutritionData = <String, dynamic>{
      'calories': ((recipe['calories'] as num?)?.toDouble() ?? 0.0) * factor,
      'protein': ((recipe['protein'] as num?)?.toDouble() ?? 0.0) * factor,
      'carbs': ((recipe['carbs'] as num?)?.toDouble() ?? 0.0) * factor,
      'fat': ((recipe['fat'] as num?)?.toDouble() ?? 0.0) * factor,
      'fiber': ((recipe['fiber'] as num?)?.toDouble() ?? 0.0) * factor,
      'sugar': ((recipe['sugar'] as num?)?.toDouble() ?? 0.0) * factor,
      'saturated_fat': ((recipe['saturated_fat'] as num?)?.toDouble() ?? 0.0) * factor,
      'omega3': ((recipe['omega3'] as num?)?.toDouble() ?? 0.0) * factor,
      'omega6': ((recipe['omega6'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_a': ((recipe['vitamin_a'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_c': ((recipe['vitamin_c'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_d': ((recipe['vitamin_d'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_e': ((recipe['vitamin_e'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_k': ((recipe['vitamin_k'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b1_thiamine': ((recipe['vitamin_b1_thiamine'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b2_riboflavin': ((recipe['vitamin_b2_riboflavin'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b3_niacin': ((recipe['vitamin_b3_niacin'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b5_pantothenic_acid': ((recipe['vitamin_b5_pantothenic_acid'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b6': ((recipe['vitamin_b6'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b7_biotin': ((recipe['vitamin_b7_biotin'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b9_folate': ((recipe['vitamin_b9_folate'] as num?)?.toDouble() ?? 0.0) * factor,
      'vitamin_b12': ((recipe['vitamin_b12'] as num?)?.toDouble() ?? 0.0) * factor,
      'calcium': ((recipe['calcium'] as num?)?.toDouble() ?? 0.0) * factor,
      'iron': ((recipe['iron'] as num?)?.toDouble() ?? 0.0) * factor,
      'magnesium': ((recipe['magnesium'] as num?)?.toDouble() ?? 0.0) * factor,
      'phosphorus': ((recipe['phosphorus'] as num?)?.toDouble() ?? 0.0) * factor,
      'potassium': ((recipe['potassium'] as num?)?.toDouble() ?? 0.0) * factor,
      'sodium': ((recipe['sodium'] as num?)?.toDouble() ?? 0.0) * factor,
      'zinc': ((recipe['zinc'] as num?)?.toDouble() ?? 0.0) * factor,
      'copper': ((recipe['copper'] as num?)?.toDouble() ?? 0.0) * factor,
      'manganese': ((recipe['manganese'] as num?)?.toDouble() ?? 0.0) * factor,
      'selenium': ((recipe['selenium'] as num?)?.toDouble() ?? 0.0) * factor,
      'chromium': ((recipe['chromium'] as num?)?.toDouble() ?? 0.0) * factor,
      'molybdenum': ((recipe['molybdenum'] as num?)?.toDouble() ?? 0.0) * factor,
      'iodine': ((recipe['iodine'] as num?)?.toDouble() ?? 0.0) * factor,
      'water': ((recipe['water'] as num?)?.toDouble() ?? 0.0) * factor,
      'caffeine': ((recipe['caffeine'] as num?)?.toDouble() ?? 0.0) * factor,
      'creatine': ((recipe['creatine'] as num?)?.toDouble() ?? 0.0) * factor,
      'taurine': ((recipe['taurine'] as num?)?.toDouble() ?? 0.0) * factor,
      'beta_alanine': ((recipe['beta_alanine'] as num?)?.toDouble() ?? 0.0) * factor,
      'l_carnitine': ((recipe['l_carnitine'] as num?)?.toDouble() ?? 0.0) * factor,
      'glutamine': ((recipe['glutamine'] as num?)?.toDouble() ?? 0.0) * factor,
      'bcaa': ((recipe['bcaa'] as num?)?.toDouble() ?? 0.0) * factor,
      'leucine': ((recipe['leucine'] as num?)?.toDouble() ?? 0.0) * factor,
      'isoleucine': ((recipe['isoleucine'] as num?)?.toDouble() ?? 0.0) * factor,
      'valine': ((recipe['valine'] as num?)?.toDouble() ?? 0.0) * factor,
      'lysine': ((recipe['lysine'] as num?)?.toDouble() ?? 0.0) * factor,
      'methionine': ((recipe['methionine'] as num?)?.toDouble() ?? 0.0) * factor,
      'phenylalanine': ((recipe['phenylalanine'] as num?)?.toDouble() ?? 0.0) * factor,
      'threonine': ((recipe['threonine'] as num?)?.toDouble() ?? 0.0) * factor,
      'tryptophan': ((recipe['tryptophan'] as num?)?.toDouble() ?? 0.0) * factor,
      'histidine': ((recipe['histidine'] as num?)?.toDouble() ?? 0.0) * factor,
      'arginine': ((recipe['arginine'] as num?)?.toDouble() ?? 0.0) * factor,
      'tyrosine': ((recipe['tyrosine'] as num?)?.toDouble() ?? 0.0) * factor,
      'cysteine': ((recipe['cysteine'] as num?)?.toDouble() ?? 0.0) * factor,
      'alanine': ((recipe['alanine'] as num?)?.toDouble() ?? 0.0) * factor,
      'aspartic_acid': ((recipe['aspartic_acid'] as num?)?.toDouble() ?? 0.0) * factor,
      'glutamic_acid': ((recipe['glutamic_acid'] as num?)?.toDouble() ?? 0.0) * factor,
      'serine': ((recipe['serine'] as num?)?.toDouble() ?? 0.0) * factor,
      'proline': ((recipe['proline'] as num?)?.toDouble() ?? 0.0) * factor,
      'glycine': ((recipe['glycine'] as num?)?.toDouble() ?? 0.0) * factor,
    };

    // Log as meal - now stores ALL nutritional data in nutrition_data JSONB field
    await _client.from('daily_logs').insert({
      'user_id': userId,
      'custom_food_name': recipe['title_en'],
      'recipe_id': recipeId, // Link to recipes table
      'calories': nutritionData['calories'],
      'protein': nutritionData['protein'],
      'carbs': nutritionData['carbs'],
      'fat': nutritionData['fat'],
      'quantity': quantity,
      'unit': unit,
      'meal_type': mealType,
      'nutrition_data': nutritionData, // Store ALL nutritional data in JSONB
    });

    // Log cooking history with recipe_id - this links to recipes table with ALL nutrition
    await _client.from('recipe_cooking_logs').insert({
      'user_id': userId,
      'recipe_id': recipeId,
      'servings_cooked': quantity,
      'meal_type': mealType,
      // Store all nutrition data in a JSONB field if the schema supports it
      // Otherwise, the full nutrition is always available via recipe_id -> recipes table
    });

    // Increment times_cooked
    await _client
        .from('recipes')
        .update({'times_cooked': (recipe['times_cooked'] as int? ?? 0) + 1})
        .eq('id', recipeId);
  }

  // Get all available recipe tags
  Future<List<String>> getRecipeTags() async {
    try {
      final response = await _client
          .from('recipe_tags')
          .select('tag')
          .order('tag');
      
      final tags = (response as List).map((e) => e['tag'] as String).toSet().toList();
      return tags;
    } catch (e) {
      debugPrint('[ERROR] Error loading recipe tags: $e');
      return [];
    }
  }

  // Upload recipe image to storage
  Future<String?> uploadRecipeImage(File imageFile) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage
          .from('recipe_images')
          .upload(
            '$userId/$fileName',
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _client.storage
          .from('recipe_images')
          .getPublicUrl('$userId/$fileName');

      return imageUrl;
    } catch (e) {
      debugPrint('[ERROR] Error uploading recipe image: $e');
      return null;
    }
  }

  // Create a new recipe
  Future<String> createRecipe({
    required String titleEn,
    required String titleDe,
    String? descriptionEn,
    String? descriptionDe,
    required int prepTimeMinutes,
    int? cookTimeMinutes,
    required int totalTimeMinutes,
    required int servings,
    String? recommendedMealType,
    String? dietType,
    String? cuisineType,
    required List<Map<String, dynamic>> ingredients,
    required List<String> instructionsEn,
    required List<String> instructionsDe,
    required String imageUrl,
    required Map<String, dynamic> nutritionData,
    List<String>? tags,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Not logged in');

    try {
      // Prepare recipe data
      final recipeData = <String, dynamic>{
        'title_en': titleEn,
        'title_de': titleDe,
        'description_en': descriptionEn,
        'description_de': descriptionDe,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes ?? 0,
        'total_time_minutes': totalTimeMinutes,
        'servings': servings,
        'recommended_meal_type': recommendedMealType,
        'diet_type': dietType,
        'cuisine_type': cuisineType,
        'ingredients': ingredients,
        'instructions_en': instructionsEn,
        'instructions_de': instructionsDe,
        'image_url': imageUrl,
        'source': 'user_created',
        'created_by_user_id': userId,
        'is_public': true,
        'is_featured': false,
        'views_count': 0,
        'likes_count': 0,
        'times_cooked': 0,
      };

      // Add all nutrition fields
      for (var entry in nutritionData.entries) {
        recipeData[entry.key] = entry.value;
      }

      // Insert recipe
      final response = await _client
          .from('recipes')
          .insert(recipeData)
          .select('id')
          .single();

      final recipeId = response['id'] as String;

      // Add tags if provided
      if (tags != null && tags.isNotEmpty) {
        final tagData = tags.map((tag) => {
          'recipe_id': recipeId,
          'tag': tag,
        }).toList();

        await _client.from('recipe_tags').insert(tagData);
      }

      return recipeId;
    } catch (e) {
      debugPrint('[ERROR] Error creating recipe: $e');
      rethrow;
    }
  }

  // Save journal entry and process structured data
  // Returns a summary of what was saved
  Future<Map<String, dynamic>> saveJournalEntry({
    required String journalText,
    required Map<String, dynamic> structuredData,
    String language = 'en',
    String? audioUrl,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    // Track what was saved for notifications
    int workoutsSaved = 0;
    int mealsSaved = 0;
    int waterMlSaved = 0;

    try {
      debugPrint('Saving journal entry for user: $userId');
      debugPrint('Structured data: $structuredData');

      // 0. Save raw journal entry to daily_journal_entries table
      final entryDate = DateTime.now().toIso8601String().substring(0, 10);
      await _client.from('daily_journal_entries').insert({
        'user_id': userId,
        'entry_date': entryDate,
        'raw_text': journalText,
        'structured_data': structuredData,
        'language': language,
        'audio_url': audioUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Journal entry saved to daily_journal_entries');

      // 1. Save workouts
      final workouts = structuredData['workouts'] as List<dynamic>? ?? [];
      debugPrint('Found ${workouts.length} workouts');
      
      for (var workout in workouts) {
        final exerciseName = workout['exercise_name'] as String?;
        if (exerciseName == null || exerciseName.isEmpty) {
          debugPrint('Skipping workout with empty exercise_name');
          continue;
        }

        debugPrint('[Journal] Searching for exercise: $exerciseName');
        
        // Use searchExercises for better matching - searches in both general and custom exercises
        final exercises = await searchExercises(exerciseName);
        debugPrint('[Journal] Found ${exercises.length} matching exercises');
        
        Map<String, dynamic>? exerciseData;
        bool isCustomExercise = false;

        if (exercises.isNotEmpty) {
          exerciseData = exercises.first;
          isCustomExercise = exerciseData['is_custom'] == true;
          debugPrint('[Journal] Using existing exercise: ${exerciseData['name_en']} (isCustom: $isCustomExercise, id: ${exerciseData['id']})');
        } else {
          // Try fuzzy matching - normalize the name
          final normalizedName = _normalizeExerciseName(exerciseName);
          if (normalizedName != exerciseName) {
            debugPrint('[Journal] Trying normalized name: $normalizedName');
            final normalizedExercises = await searchExercises(normalizedName);
            debugPrint('[Journal] Found ${normalizedExercises.length} exercises with normalized name');
            if (normalizedExercises.isNotEmpty) {
              exerciseData = normalizedExercises.first;
              isCustomExercise = exerciseData['is_custom'] == true;
              debugPrint('[Journal] Using exercise from normalized search: ${exerciseData['name_en']} (isCustom: $isCustomExercise)');
            }
          }
        }

        // If still not found, create with AI
        if (exerciseData == null) {
          debugPrint('[Journal] Exercise not found in database, creating with AI: $exerciseName');
          try {
            final aiExerciseData = await ReplicateService().generateExerciseDetailsFromName(
              exerciseName,
              language: language,
            );
            exerciseData = await createCustomExerciseWithAI(exerciseName, aiExerciseData, language: language);
            isCustomExercise = true;
            debugPrint('[Journal] Custom exercise created successfully: $exerciseName (id: ${exerciseData['id']})');
          } catch (e) {
            debugPrint('Error creating exercise: $e');
            continue; // Skip this workout but continue with others
          }
        }

        if (exerciseData != null) {
          // Custom exercises are saved in exercise_logs with custom_exercise_id
          // This allows them to be tracked regularly like other exercises
          final exerciseId = exerciseData['id'] as String;
          final sets = (workout['sets'] as num?)?.toInt() ?? 1;
          final reps = (workout['reps'] as num?)?.toInt() ?? 0;
          final weightKg = (workout['weight_kg'] as num?)?.toDouble() ?? 0.0;
          var durationMinutes = (workout['duration_minutes'] as num?)?.toInt() ?? 0;
          
          // Try to extract duration from notes if duration_minutes is 0
          final notes = structuredData['notes'] as String? ?? '';
          if (durationMinutes == 0 && notes.isNotEmpty) {
            final distanceMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:km|kilometer|mi|mile)', caseSensitive: false).firstMatch(notes);
            if (distanceMatch != null) {
              final distance = double.parse(distanceMatch.group(1)!);
              final unit = distanceMatch.group(0)!.toLowerCase();
              final distanceKm = unit.contains('mi') ? distance * 1.60934 : distance;
              
              // Estimate duration based on exercise type and distance
              final exerciseNameLower = exerciseName.toLowerCase();
              if (exerciseNameLower.contains('run') || exerciseNameLower.contains('jog')) {
                // Running: ~6-8 min/km average
                durationMinutes = (distanceKm * 7).round();
              } else if (exerciseNameLower.contains('walk')) {
                // Walking: ~10-12 min/km average
                durationMinutes = (distanceKm * 11).round();
              } else {
                // Other cardio: estimate ~8 min/km
                durationMinutes = (distanceKm * 8).round();
              }
              debugPrint('[Journal] Extracted duration from notes: $distanceKm km = $durationMinutes minutes');
            }
          }
          
          // Calculate calories burned - use AI value if provided, otherwise calculate
          double caloriesBurned = (workout['calories_burned'] as num?)?.toDouble() ?? 0.0;
          
          if (caloriesBurned == 0) {
            // Calculate if not provided by AI
            final caloriesPerRep = (exerciseData['calories_per_rep'] as num?)?.toDouble() ?? 0.5;
            
            if (durationMinutes > 0) {
              // For cardio/timed exercises, calculate based on duration and exercise type
              final exerciseNameLower = exerciseName.toLowerCase();
              if (exerciseNameLower.contains('run') || exerciseNameLower.contains('jog')) {
                // Running: ~10-12 kcal/min (moderate intensity)
                caloriesBurned = durationMinutes * 11.0;
              } else if (exerciseNameLower.contains('walk')) {
                // Walking: ~4-5 kcal/min
                caloriesBurned = durationMinutes * 4.5;
              } else if (exerciseNameLower.contains('bike') || exerciseNameLower.contains('cycling')) {
                // Cycling: ~8-10 kcal/min
                caloriesBurned = durationMinutes * 9.0;
              } else {
                // Other cardio: ~8-10 kcal/min average
                caloriesBurned = durationMinutes * 9.0;
              }
            } else if (reps > 0) {
              // For rep-based exercises, calculate based on reps
              caloriesBurned = reps * sets * caloriesPerRep;
            } else if (sets > 0) {
              // If only sets are provided, estimate based on sets
              caloriesBurned = sets * 10.0; // Rough estimate
            }
          }
          
          // Ensure minimum calories for any exercise
          if (caloriesBurned == 0 && durationMinutes > 0) {
            caloriesBurned = durationMinutes * 5.0; // Minimum fallback
          }
          
          debugPrint('[Journal] Saving exercise log: $exerciseName');
          debugPrint('[Journal]   - sets: $sets, reps: $reps, weight: $weightKg, duration: $durationMinutes');
          debugPrint('[Journal]   - calories: $caloriesBurned, isCustom: $isCustomExercise');
          debugPrint('[Journal]   - exerciseId: ${exerciseData['id']}');
          
          // Insert exercise log - use exercise_id for general exercises, custom_exercise_id for custom
          // Custom exercises are saved in exercise_logs with custom_exercise_id, allowing them to be tracked regularly
          final logData = <String, dynamic>{
            'user_id': userId,
            'sets': sets,
            'reps': reps,
            'weight_kg': weightKg,
            'duration_seconds': durationMinutes * 60,
            'calories_burned': caloriesBurned,
            'logged_at': DateTime.now().toIso8601String(),
          };

          if (isCustomExercise) {
            logData['custom_exercise_id'] = exerciseId;
            // Don't set exercise_id for custom exercises
          } else {
            logData['exercise_id'] = exerciseId;
            // Don't set custom_exercise_id for general exercises
          }

          final insertedLog = await _client.from('exercise_logs').insert(logData).select().single();
          debugPrint('[Journal] Exercise log saved successfully: ${insertedLog['id']}');
          debugPrint('[Journal] Log data: exercise_id=${logData['exercise_id']}, custom_exercise_id=${logData['custom_exercise_id']}, isCustom=$isCustomExercise');
          workoutsSaved++;
        }
      }

      // 2. Save meals
      final meals = structuredData['meals'] as List<dynamic>? ?? [];
      debugPrint('Found ${meals.length} meals');
      
      for (var meal in meals) {
        try {
          final foodName = meal['food_name'] as String?;
          if (foodName == null || foodName.isEmpty) {
            debugPrint('Skipping meal with empty food_name');
            continue;
          }

          // Normalize food name for better matching
          final normalizedFoodName = _normalizeFoodName(foodName);
          debugPrint('Processing meal: $foodName (normalized: $normalizedFoodName)');

          // Search for food - try original name first, then normalized
          var foodResponse = await searchFoodWithFilter(foodName, filter: 'all');
          if (foodResponse.isEmpty && normalizedFoodName != foodName) {
            foodResponse = await searchFoodWithFilter(normalizedFoodName, filter: 'all');
          }
          
          Map<String, dynamic>? foodData;
          bool isCustomFood = false;

          if (foodResponse.isNotEmpty) {
            foodData = foodResponse.first;
            isCustomFood = foodData['is_custom'] == true;
            debugPrint('Found existing food: ${foodData['name']}');
          } else {
            // Create food with AI if not found
            debugPrint('Food not found, creating with AI: $foodName');
            try {
              final aiFoodData = await ReplicateService().generateFoodDetailsFromName(
                foodName,
                language: language,
              );
              foodData = await createCustomFoodWithAI(foodName, aiFoodData, language: language);
              isCustomFood = true;
              debugPrint('Food created successfully: $foodName');
            } catch (e) {
              debugPrint('Error creating food: $e');
              continue; // Skip this meal but continue with others
            }
          }

          if (foodData != null) {
            // Validate and sanitize meal data
            final quantity = ((meal['quantity'] as num?)?.toDouble() ?? 100.0).clamp(1.0, 10000.0);
            final unit = _validateUnit(meal['unit'] as String? ?? 'g');
            final mealType = _validateMealType(meal['meal_type'] as String? ?? 'SNACK');
            
            debugPrint('Logging meal: $foodName, quantity: $quantity $unit, mealType: $mealType');

            await logMeal(
              foodId: foodData['id'] as String,
              quantity: quantity,
              calories: (foodData['calories'] as num?)?.toDouble() ?? 0.0,
              protein: (foodData['protein'] as num?)?.toDouble() ?? 0.0,
              carbs: (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
              fat: (foodData['fat'] as num?)?.toDouble() ?? 0.0,
              mealType: mealType,
              unit: unit,
              foodData: foodData,
              isCustomFood: isCustomFood,
            );
            
            debugPrint('Meal logged successfully');
            mealsSaved++;
          }
        } catch (e) {
          debugPrint('Error processing meal: $e');
          // Continue with next meal instead of failing entire operation
          continue;
        }
      }

      // 3. Save water intake
      final waterMl = (structuredData['water_ml'] as num?)?.toInt() ?? 0;
      if (waterMl > 0) {
        debugPrint('Saving water intake: $waterMl ml');
        await _client.from('water_logs').insert({
          'user_id': userId,
          'amount_ml': waterMl,
          'logged_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Water intake saved successfully');
        waterMlSaved = waterMl;
      } else {
        debugPrint('No water intake to save');
      }
      
      debugPrint('Journal entry saved successfully!');
      
      // Return summary of what was saved
      return {
        'workouts_saved': workoutsSaved,
        'meals_saved': mealsSaved,
        'water_ml_saved': waterMlSaved,
      };
    } catch (e) {
      debugPrint('Error saving journal entry: $e');
      rethrow;
    }
  }

  // Get journal history for current user
  Future<List<Map<String, dynamic>>> getJournalHistory() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await _client
          .from('daily_journal_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting journal history: $e');
      return [];
    }
  }

  // Delete journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    try {
      // First, get the entry to check ownership and get audio_url
      final entry = await _client
          .from('daily_journal_entries')
          .select('audio_url')
          .eq('id', entryId)
          .eq('user_id', userId)
          .maybeSingle();

      if (entry == null) {
        throw Exception('Journal entry not found or access denied');
      }

      // Delete audio file if exists
      final audioUrl = entry['audio_url'] as String?;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        try {
          // Extract file path from URL
          final uri = Uri.parse(audioUrl);
          final pathParts = uri.pathSegments;
          if (pathParts.length >= 3 && pathParts[0] == 'storage' && pathParts[1] == 'v1') {
            final bucket = pathParts[2];
            final filePath = pathParts.sublist(3).join('/');
            await _client.storage.from(bucket).remove([filePath]);
          }
        } catch (e) {
          debugPrint('Error deleting audio file: $e');
          // Continue with entry deletion even if audio deletion fails
        }
      }

      // Delete journal entry
      await _client
          .from('daily_journal_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', userId);
      
      debugPrint('Journal entry deleted successfully');
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
      rethrow;
    }
  }

  // Helper: Normalize exercise name for better matching
  String _normalizeExerciseName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  // Helper: Normalize food name for better matching
  String _normalizeFoodName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  // Helper: Validate and normalize unit
  String _validateUnit(String? unit) {
    if (unit == null) return 'g';
    final normalized = unit.toLowerCase().trim();
    if (normalized == 'g' || normalized == 'gram' || normalized == 'grams') return 'g';
    if (normalized == 'ml' || normalized == 'milliliter' || normalized == 'milliliters') return 'ml';
    if (normalized == 'piece' || normalized == 'pieces' || normalized == 'pcs' || normalized == 'pc') return 'piece';
    return 'g'; // Default to grams
  }

  // Helper: Validate and normalize meal type
  String _validateMealType(String? mealType) {
    if (mealType == null) return 'SNACK';
    final normalized = mealType.toUpperCase().trim();
    const validTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];
    if (validTypes.contains(normalized)) return normalized;
    return 'SNACK'; // Default to snack
  }
}
