import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/widgets/flow_widgets.dart';
import 'package:flow/core/utils/nutrition_data.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';

class FoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> food;
  final String mealType;
  final double? initialQuantity; // Optional: pre-filled quantity from recognition
  final String? initialUnit; // Optional: pre-filled unit from recognition

  const FoodDetailPage({
    super.key,
    required this.food,
    required this.mealType,
    this.initialQuantity,
    this.initialUnit,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _quantityController = TextEditingController();
  double _quantity = 100.0;
  String _unit = 'g'; // Default to grams
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  Map<String, double> _todayTotals = {};
  bool _isLoadingData = true;
  Map<String, dynamic>? _foodHistory;
  List<Map<String, dynamic>> _similarFoods = [];
  Map<String, double>? _averageNutrition;
  final ReplicateService _replicateService = ReplicateService();
  String? _pandaAdvice;
  bool _isLoadingAdvice = false;
  bool _isFavorite = false;
  Map<String, dynamic> _currentFood = {}; // Store current food data for editing

  @override
  void initState() {
    _currentFood = Map<String, dynamic>.from(widget.food);
    super.initState();
    
    // Use initial quantity/unit if provided (from recognition), otherwise detect
    if (widget.initialQuantity != null) {
      _quantity = widget.initialQuantity!;
      _unit = widget.initialUnit ?? 'g';
    } else {
      _detectUnit();
    }
    
    _quantityController.text = _quantity.toStringAsFixed(_quantity == _quantity.toInt() ? 0 : 1);
    _checkIfFavorite();
    _loadUserData();
  }

  Future<void> _checkIfFavorite() async {
    final foodId = _currentFood['id']?.toString();
    if (foodId != null) {
      final isFav = await _supabaseService.isFavoriteFood(foodId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final foodId = _currentFood['id']?.toString();
      if (foodId == null) return;
      
      if (_isFavorite) {
        await _supabaseService.removeFavoriteFood(foodId);
      } else {
        await _supabaseService.addFavoriteFood(foodId);
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? AppLocalizations.of(context)!.addedToFavorites : AppLocalizations.of(context)!.removedFromFavorites),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingFavorites),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareFoodDetails() async {
    try {
      final food = _currentFood;
      final foodName = food['name']?.toString() ?? 'Food';
      final calories = ((food['calories'] as num?)?.toDouble() ?? 0.0) * (_quantity / 100.0);
      final protein = ((food['protein'] as num?)?.toDouble() ?? 0.0) * (_quantity / 100.0);
      final carbs = ((food['carbs'] as num?)?.toDouble() ?? 0.0) * (_quantity / 100.0);
      final fat = ((food['fat'] as num?)?.toDouble() ?? 0.0) * (_quantity / 100.0);
      
      final shareText = '''
🍽️ $foodName
${_quantity.toStringAsFixed(0)}${_unit}

📊 Nutrition per serving:
• Calories: ${calories.toStringAsFixed(0)} kcal
• Protein: ${protein.toStringAsFixed(1)}g
• Carbs: ${carbs.toStringAsFixed(1)}g
• Fat: ${fat.toStringAsFixed(1)}g

Shared from Flow App
''';
      
      await Share.share(shareText, subject: AppLocalizations.of(context)!.foodDetails(foodName));
    } catch (e) {
      print('Error sharing food details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSharingFoodDetails),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog() async {
    final food = _currentFood;
    final foodId = food['id']?.toString();
    if (foodId == null) return;

    final l10n = AppLocalizations.of(context)!;
    
    // Controllers for all fields
    final nameController = TextEditingController(text: food['name']?.toString() ?? '');
    final germanNameController = TextEditingController(text: food['german_name']?.toString() ?? '');
    final caloriesController = TextEditingController(text: (food['calories'] as num?)?.toString() ?? '0');
    final proteinController = TextEditingController(text: (food['protein'] as num?)?.toString() ?? '0');
    final carbsController = TextEditingController(text: (food['carbs'] as num?)?.toString() ?? '0');
    final fatController = TextEditingController(text: (food['fat'] as num?)?.toString() ?? '0');
    final fiberController = TextEditingController(text: (food['fiber'] as num?)?.toString() ?? '0');
    final sugarController = TextEditingController(text: (food['sugar'] as num?)?.toString() ?? '0');
    final sodiumController = TextEditingController(text: (food['sodium'] as num?)?.toString() ?? '0');
    final waterController = TextEditingController(text: (food['water'] as num?)?.toString() ?? '0');
    final caffeineController = TextEditingController(text: (food['caffeine'] as num?)?.toString() ?? '0');

    // Map for additional nutrients (all other fields from NutritionData)
    final Map<String, TextEditingController> additionalControllers = {};
    for (var nutrient in NutritionData.nutrients) {
      if (!['calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'sodium', 'water', 'caffeine'].contains(nutrient.key)) {
        final value = (food[nutrient.key] as num?)?.toDouble() ?? 0.0;
        additionalControllers[nutrient.key] = TextEditingController(text: value > 0 ? value.toString() : '');
      }
    }

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.editFoodDetails),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name fields
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name (EN)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: germanNameController,
                    decoration: InputDecoration(
                      labelText: 'Name (DE)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.macronutrientsPer100g, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fatController,
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fiberController,
                          decoration: const InputDecoration(
                            labelText: 'Fiber (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: sugarController,
                          decoration: const InputDecoration(
                            labelText: 'Sugar (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.otherNutrientsPer100g, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sodiumController,
                    decoration: const InputDecoration(
                      labelText: 'Sodium (mg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: waterController,
                    decoration: const InputDecoration(
                      labelText: 'Water (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: caffeineController,
                    decoration: const InputDecoration(
                      labelText: 'Caffeine (mg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  // Additional nutrients
                  ...additionalControllers.entries.map((entry) {
                    final nutrient = NutritionData.nutrients.firstWhere((n) => n.key == entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: '${nutrient.name} (${nutrient.unit})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context, false),
              child: Text(l10n.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  // Parse all values
                  final name = nameController.text.trim();
                  final germanName = germanNameController.text.trim();
                  final calories = double.tryParse(caloriesController.text) ?? 0.0;
                  final protein = double.tryParse(proteinController.text) ?? 0.0;
                  final carbs = double.tryParse(carbsController.text) ?? 0.0;
                  final fat = double.tryParse(fatController.text) ?? 0.0;
                  final fiber = double.tryParse(fiberController.text);
                  final sugar = double.tryParse(sugarController.text);
                  final sodium = double.tryParse(sodiumController.text);
                  final water = double.tryParse(waterController.text);
                  final caffeine = double.tryParse(caffeineController.text);

                  // Parse additional nutrients
                  final Map<String, dynamic> additionalNutrients = {};
                  for (var entry in additionalControllers.entries) {
                    final value = double.tryParse(entry.value.text);
                    if (value != null && value > 0) {
                      additionalNutrients[entry.key] = value;
                    } else {
                      // Set to 0 if empty or invalid
                      additionalNutrients[entry.key] = 0.0;
                    }
                  }

                  // Update in Supabase
                  await _supabaseService.updateCustomFood(
                    foodId: foodId,
                    name: name.isNotEmpty ? name : null,
                    germanName: germanName.isNotEmpty ? germanName : null,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber,
                    sugar: sugar,
                    sodium: sodium,
                    water: water,
                    caffeine: caffeine,
                    additionalNutrients: additionalNutrients.isNotEmpty ? additionalNutrients : null,
                  );

                  // Update local state
                  setState(() {
                    _currentFood['name'] = name;
                    _currentFood['german_name'] = germanName;
                    _currentFood['calories'] = calories;
                    _currentFood['protein'] = protein;
                    _currentFood['carbs'] = carbs;
                    _currentFood['fat'] = fat;
                    if (fiber != null) _currentFood['fiber'] = fiber;
                    if (sugar != null) _currentFood['sugar'] = sugar;
                    if (sodium != null) _currentFood['sodium'] = sodium;
                    if (water != null) _currentFood['water'] = water;
                    if (caffeine != null) _currentFood['caffeine'] = caffeine;
                    _currentFood.addAll(additionalNutrients);
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.foodUpdated),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error updating food: $e');
                  if (mounted) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers
    nameController.dispose();
    germanNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    fiberController.dispose();
    sugarController.dispose();
    sodiumController.dispose();
    waterController.dispose();
    caffeineController.dispose();
    for (var controller in additionalControllers.values) {
      controller.dispose();
    }
  }

  void _detectUnit() {
    // Priority 0: Check if it's water based on water field in database
    final waterValue = (_currentFood['water'] as num?)?.toDouble() ?? 0.0;
    final foodName = (_currentFood['name']?.toString() ?? '').toLowerCase();
    final germanName = (_currentFood['german_name']?.toString() ?? '').toLowerCase();
    final allText = '$foodName $germanName';
    
    // Exclude solid foods that might have high water content
    final solidFoodExclusions = [
      'pasta', 'noodles', 'nudeln', 'spaghetti', 'macaroni', 'penne', 'fusilli',
      'rice', 'reis', 'bread', 'brot', 'cake', 'kuchen', 'cookie', 'kekse',
      'potato', 'potatoes', 'kartoffel', 'pommes', 'fries', 'chips',
      'fruit', 'frucht', 'vegetable', 'gemüse', 'salad', 'salat',
      'meat', 'fleisch', 'chicken', 'huhn', 'fish', 'fisch', 'beef', 'rind',
      'cheese', 'käse', 'yogurt', 'joghurt', 'milk', 'milch'
    ];
    
    final isSolidFood = solidFoodExclusions.any((exclusion) => allText.contains(exclusion));
    
    // Only detect as water if:
    // 1. Name explicitly contains water/wasser AND it's not a solid food
    // 2. OR water field is very high (>95%) AND name indicates it's a drink/liquid
    final hasWaterInName = (foodName.contains('water') && !foodName.contains('melon')) ||
                           (germanName.contains('wasser') && !germanName.contains('melone')) ||
                           allText.contains('mineral water') ||
                           allText.contains('mineralwasser') ||
                           allText.contains('drinking water') ||
                           allText.contains('trinkwasser');
    
    final isLiquidDrink = allText.contains('juice') || allText.contains('saft') ||
                         allText.contains('soda') || allText.contains('cola') ||
                         allText.contains('drink') || allText.contains('getränk') ||
                         allText.contains('beverage') || allText.contains('tea') ||
                         allText.contains('tee') || allText.contains('coffee') ||
                         allText.contains('kaffee');
    
    final isWater = !isSolidFood && (
      hasWaterInName || 
      (waterValue > 95.0 && isLiquidDrink) ||
      (waterValue > 98.0 && !isSolidFood) // Only if water is >98% AND not a solid food
    );
    
    if (isWater) {
      _unit = 'ml';
      _quantity = 500.0; // Default to 500ml for water
      return;
    }
    
    // Priority 1: Check if food has a unit field in database (most reliable)
    final foodUnit = _currentFood['unit']?.toString().trim().toLowerCase() ?? '';
    
    if (foodUnit.isNotEmpty) {
      // Explicit unit from database
      if (foodUnit == 'ml' || foodUnit == 'milliliter' || foodUnit == 'millilitre' || 
          foodUnit == 'l' || foodUnit == 'liter' || foodUnit == 'litre') {
        _unit = 'ml';
        _quantity = 250.0;
        return;
      } else if (foodUnit == 'g' || foodUnit == 'gram' || foodUnit == 'grams' || 
                 foodUnit == 'kg' || foodUnit == 'kilogram' || foodUnit == 'kilogramme') {
        _unit = 'g';
        _quantity = 100.0;
        return;
      }
    }
    
    // Priority 2: Check if there's a serving_unit or similar field
    final servingUnit = _currentFood['serving_unit']?.toString().trim().toLowerCase() ?? 
                       _currentFood['serving_size_unit']?.toString().trim().toLowerCase() ?? '';
    
    if (servingUnit.isNotEmpty) {
      if (servingUnit == 'ml' || servingUnit == 'milliliter' || servingUnit == 'millilitre' || 
          servingUnit == 'l' || servingUnit == 'liter') {
        _unit = 'ml';
        _quantity = 250.0;
        return;
      } else if (servingUnit == 'g' || servingUnit == 'gram' || servingUnit == 'grams') {
        _unit = 'g';
        _quantity = 100.0;
        return;
      }
    }
    
    // Priority 3: Very conservative detection from food name (only obvious liquids)
    
    // Extended list of solid foods to exclude (including pasta)
    final extendedSolidExclusions = [
      'pasta', 'noodles', 'nudeln', 'spaghetti', 'macaroni', 'penne', 'fusilli',
      'pommes', 'potato', 'potatoes', 'kartoffel', 'fries', 'chips', 
      'bread', 'brot', 'cake', 'kuchen', 'cookie', 'kekse', 'cracker',
      'rice', 'reis', 'grain', 'getreide'
    ];
    
    final isExtendedSolidFood = extendedSolidExclusions.any((exclusion) => allText.contains(exclusion));
    
    if (!isSolidFood && !isExtendedSolidFood) {
      // Very specific liquid keywords only
      final liquidKeywords = [
        'juice', 'saft', 'milk', 'milch', 'water', 'wasser', 'soda', 'cola', 
        'drink', 'getränk', 'beverage', 'tea', 'tee', 'coffee', 'kaffee', 
        'soup', 'suppe', 'broth', 'brühe', 'smoothie', 'shake', 
        'yogurt drink', 'yoghurt drink', 'sauce', 'soße', 'dressing', 
        'oil', 'öl', 'vinegar', 'essig', 'wine', 'wein', 'beer', 'bier'
      ];
      
      // Must contain liquid keyword as a whole word or clear context
      final hasLiquidKeyword = liquidKeywords.any((keyword) {
        final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        return pattern.hasMatch(allText);
      });
      
      if (hasLiquidKeyword) {
        _unit = 'ml';
        _quantity = 250.0;
        return;
      }
    }
    
    // Default: grams for solid foods (safest assumption)
    _unit = 'g';
    _quantity = 100.0;
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _supabaseService.getProfile();
      final today = DateTime.now();
      final logs = await _supabaseService.getDailyMealLogs(today);
      
      Map<String, double> totals = {};
      for (var log in logs) {
        totals['calories'] = (totals['calories'] ?? 0.0) + ((log['calories'] as num?)?.toDouble() ?? 0.0);
        totals['protein'] = (totals['protein'] ?? 0.0) + ((log['protein'] as num?)?.toDouble() ?? 0.0);
        totals['carbs'] = (totals['carbs'] ?? 0.0) + ((log['carbs'] as num?)?.toDouble() ?? 0.0);
        totals['fat'] = (totals['fat'] ?? 0.0) + ((log['fat'] as num?)?.toDouble() ?? 0.0);
      }

      // Load additional data
      final foodId = _currentFood['id']?.toString();
      if (foodId != null) {
        final history = await _supabaseService.getFoodHistory(foodId);
        final similar = await _supabaseService.getSimilarFoods(foodId);
        final foodName = _currentFood['name']?.toString() ?? '';
        final average = await _supabaseService.getAverageNutritionForCategory(foodName);

        if (mounted) {
          setState(() {
            _profile = profile;
            _todayTotals = totals;
            _foodHistory = history;
            _similarFoods = similar;
            _averageNutrition = average;
            _isLoadingData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profile = profile;
            _todayTotals = totals;
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _profile = null;
          _todayTotals = {};
        });
      }
    }
  }

  void _logMeal() async {
    setState(() => _isSaving = true);

    final factor = _quantity / 100.0;
    final foodId = _currentFood['id']?.toString();
    final isCustomFood = _currentFood['source'] != null || _currentFood['is_custom'] == true; // Custom foods have 'source' field

    try {
      await _supabaseService.logMeal(
        foodId: foodId ?? '',
        quantity: _quantity,
        unit: _unit,
        mealType: widget.mealType.toUpperCase(),
        calories: ((_currentFood['calories'] as num?)?.toDouble() ?? 0.0) * factor,
        protein: ((_currentFood['protein'] as num?)?.toDouble() ?? 0.0) * factor,
        carbs: ((_currentFood['carbs'] as num?)?.toDouble() ?? 0.0) * factor,
        fat: ((_currentFood['fat'] as num?)?.toDouble() ?? 0.0) * factor,
        foodData: _currentFood, // Pass food data for water detection
        isCustomFood: isCustomFood,
      );

      if (mounted) {
        // Return true to indicate meal was logged successfully
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mealLogged)),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
      );
      }
    }
  }

  Map<String, dynamic> _calculateImpact() {
    try {
      final factor = _quantity / 100.0;
      final foodCalories = ((_currentFood['calories'] as num?)?.toDouble() ?? 0.0) * factor;
      final foodProtein = ((_currentFood['protein'] as num?)?.toDouble() ?? 0.0) * factor;
      final foodCarbs = ((_currentFood['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
      final foodFat = ((_currentFood['fat'] as num?)?.toDouble() ?? 0.0) * factor;

      final goal = _profile?['goal']?.toString() ?? 'MAINTAIN';
      final calorieTarget = ((_profile?['daily_calorie_target'] as num?)?.toInt() ?? 2000);
      final proteinTarget = (calorieTarget * ((_profile?['protein_target_percentage'] as num?)?.toInt() ?? 30) / 100) / 4;
      final carbsTarget = (calorieTarget * ((_profile?['carbs_target_percentage'] as num?)?.toInt() ?? 40) / 100) / 4;
      final fatTarget = (calorieTarget * ((_profile?['fat_target_percentage'] as num?)?.toInt() ?? 30) / 100) / 9;

      final newCalories = (_todayTotals['calories'] ?? 0) + foodCalories;
      final newProtein = (_todayTotals['protein'] ?? 0) + foodProtein;
      final newCarbs = (_todayTotals['carbs'] ?? 0) + foodCarbs;
      final newFat = (_todayTotals['fat'] ?? 0) + foodFat;

      String impactMessage = '';
      Color impactColor = AppColors.success;
      IconData impactIcon = Icons.check_circle;

      if (goal == 'LOSE') {
        // Check if food is actually good for weight loss
        final isHighCalorie = foodCalories > 500;
        final isLowProtein = foodProtein < 15;
        final isLowFiber = ((_currentFood['fiber'] as num?)?.toDouble() ?? 0.0) * factor < 3;
        
        if (newCalories > calorieTarget * 1.1) {
          impactMessage = 'Warning! This food exceeds your daily target.';
          impactColor = AppColors.error;
          impactIcon = Icons.warning;
        } else if (newCalories > calorieTarget) {
          impactMessage = 'Near daily limit. Monitor the rest of your day.';
          impactColor = AppColors.warning;
          impactIcon = Icons.info;
        } else if (isHighCalorie || (isLowProtein && isLowFiber)) {
          impactMessage = 'Consider lighter options for better weight loss results.';
          impactColor = AppColors.warning;
          impactIcon = Icons.info;
        } else {
          impactMessage = 'Good choice for your weight loss goal!';
          impactColor = AppColors.success;
        }
      } else if (goal == 'GAIN') {
        if (newCalories < calorieTarget * 0.8) {
          impactMessage = 'Good food for weight gain!';
        } else {
          impactMessage = 'Excellent! Helps you reach your daily target.';
        }
      } else {
        if (newCalories > calorieTarget * 1.1) {
          impactMessage = 'Above maintenance target. Adjust the rest of your day.';
          impactColor = AppColors.warning;
          impactIcon = Icons.info;
        } else {
          impactMessage = 'Good for weight maintenance!';
        }
      }

      return {
        'message': impactMessage,
        'color': impactColor,
        'icon': impactIcon,
        'caloriesProgress': (newCalories / calorieTarget).clamp(0.0, 1.0),
        'proteinProgress': (newProtein / proteinTarget).clamp(0.0, 1.0),
        'carbsProgress': (newCarbs / carbsTarget).clamp(0.0, 1.0),
        'fatProgress': (newFat / fatTarget).clamp(0.0, 1.0),
        'calories': newCalories,
        'calorieTarget': calorieTarget.toDouble(),
        'protein': newProtein,
        'proteinTarget': proteinTarget,
        'carbs': newCarbs,
        'carbsTarget': carbsTarget,
        'fat': newFat,
        'fatTarget': fatTarget,
      };
    } catch (e) {
      print('Error in _calculateImpact: $e');
      return {
        'message': 'Analysis available',
        'color': AppColors.primary,
        'icon': Icons.info,
        'caloriesProgress': 0.0,
        'proteinProgress': 0.0,
        'carbsProgress': 0.0,
        'fatProgress': 0.0,
        'calories': 0.0,
        'calorieTarget': 2000.0,
        'protein': 0.0,
        'proteinTarget': 150.0,
        'carbs': 0.0,
        'carbsTarget': 200.0,
        'fat': 0.0,
        'fatTarget': 67.0,
      };
    }
  }

  List<String> _checkAllergies() {
    final allergies = _profile?['onboarding_metadata']?['allergies'] as List<dynamic>? ?? [];
    final foodName = (_currentFood['name']?.toString() ?? '').toLowerCase();
    final foodBrands = (_currentFood['brands']?.toString() ?? '').toLowerCase();
    final allText = '$foodName $foodBrands';
    
    final commonAllergens = {
      'gluten': ['wheat', 'barley', 'rye', 'gluten', 'flour', 'bread', 'pasta'],
      'dairy': ['milk', 'cheese', 'butter', 'yogurt', 'cream', 'dairy', 'lactose'],
      'nuts': ['nut', 'almond', 'peanut', 'walnut', 'hazelnut', 'cashew'],
      'eggs': ['egg', 'mayonnaise'],
      'soy': ['soy', 'soya', 'tofu'],
      'fish': ['fish', 'salmon', 'tuna', 'seafood'],
      'shellfish': ['shrimp', 'crab', 'lobster', 'shellfish'],
    };
    
    final warnings = <String>[];
    for (var allergy in allergies) {
      final allergenKey = allergy.toString().toLowerCase();
      if (commonAllergens.containsKey(allergenKey)) {
        final keywords = commonAllergens[allergenKey]!;
        if (keywords.any((keyword) => allText.contains(keyword))) {
          warnings.add(allergy.toString());
        }
      }
    }
    
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final factor = _quantity / 100.0;

    // Use _currentFood instead of widget.food for dynamic updates
    final food = _currentFood;
    
    if (_isLoadingData) {
    return Scaffold(
        appBar: AppBar(title: Text(l10n.unknownFood)),
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final impact = _calculateImpact();
    final allergies = _checkAllergies();
    final foodCalories = ((food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodProtein = ((food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodCarbs = ((food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodFat = ((food['fat'] as num?)?.toDouble() ?? 0.0) * factor;

    // Check if this is a custom food (has 'source' field or 'is_custom' flag)
    final isCustomFood = _currentFood['source'] != null || _currentFood['is_custom'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(food['name']?.toString() ?? l10n.unknownFood),
        backgroundColor: AppColors.background,
        actions: [
          // Edit button only for custom foods
          if (isCustomFood)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _openEditDialog,
              tooltip: AppLocalizations.of(context)!.editFoodDetailsTooltip,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFoodDetails,
            tooltip: AppLocalizations.of(context)!.shareFoodDetailsTooltip,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppColors.textSecondary,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? AppLocalizations.of(context)!.removeFromFavoritesTooltip : AppLocalizations.of(context)!.addToFavoritesTooltip,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with gradient
            Container(
        padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    food['name']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
                    food['brands']?.toString() ?? l10n.variousBrands,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Visual Portion Guide
                  _buildVisualPortionGuide(factor, l10n),
                  const SizedBox(height: 24),
                  // Quick Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat('Calories', foodCalories, 'kcal', Icons.local_fire_department),
                      _buildQuickStat('Protein', foodProtein, 'g', Icons.fitness_center),
                      _buildQuickStat('Carbs', foodCarbs, 'g', Icons.bolt),
                      _buildQuickStat('Fat', foodFat, 'g', Icons.opacity),
                    ],
                  ),
                ],
              ),
            ),

            // Allergy Warning
            if (allergies.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.allergyWarning,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.thisFoodMayContain}: ${allergies.join(", ")}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Health Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildHealthScore(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Panda AI Advice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPandaAdvice(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Food History
            if (_foodHistory != null && _foodHistory!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFoodHistorySection(l10n),
              ),

            if (_foodHistory != null && _foodHistory!.isNotEmpty)
              const SizedBox(height: 24),

            // Quantity Input
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
                    _unit == 'ml' ? 'Quantity (ml)' : 'Quantity (g)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
                    controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                      suffixText: _unit,
                      hintText: _unit == 'ml' ? '250' : '100',
              ),
              onChanged: (val) {
                setState(() {
                        _quantity = double.tryParse(val) ?? (_unit == 'ml' ? 250.0 : 100.0);
                });
              },
                  ),
                  const SizedBox(height: 16),
                  // Standard size chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildStandardSizeChips(),
                  ),
                  // Portion size recommendation
                  if (_profile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildPortionRecommendation(factor, l10n),
                    ),
                ],
              ),
            ),

            // Impact Analysis Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (impact['color'] as Color).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: impact['color'] as Color,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(impact['icon'] as IconData, color: impact['color'] as Color, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        impact['message'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: impact['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Comparison with Average
            if (_averageNutrition != null && _averageNutrition!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildComparisonWithAverage(factor, l10n),
              ),

            if (_averageNutrition != null && _averageNutrition!.isNotEmpty)
              const SizedBox(height: 24),

            // Macro Distribution Pie Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
                      l10n.macronutrientDistribution,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sections: _buildMacroPieSections(foodProtein, foodCarbs, foodFat),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem('Protein', foodProtein, AppColors.primary),
                                const SizedBox(height: 12),
                                _buildLegendItem('Carbs', foodCarbs, Colors.orange),
                                const SizedBox(height: 12),
                                _buildLegendItem('Fat', foodFat, Colors.purple),
                              ],
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 16),
                    // Macro ratio analysis
                    _buildMacroRatioAnalysis(foodProtein, foodCarbs, foodFat, factor, l10n),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Daily Progress Bars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.dailyProgress,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _buildProgressSummary(impact),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProgressBar('Calories', impact['calories'] as double, impact['calorieTarget'] as double, AppColors.primary),
                    const SizedBox(height: 16),
                    _buildProgressBar('Protein', impact['protein'] as double, impact['proteinTarget'] as double, Colors.blue),
                    const SizedBox(height: 16),
                    _buildProgressBar('Carbs', impact['carbs'] as double, impact['carbsTarget'] as double, Colors.orange),
                    const SizedBox(height: 16),
                    _buildProgressBar('Fat', impact['fat'] as double, impact['fatTarget'] as double, Colors.purple),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Micronutrient Coverage Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildMicronutrientChart(factor, l10n),
            ),

            const SizedBox(height: 24),

            // RDA Comparison Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildRDAComparisonTable(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Body Impact Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildBodyImpactSection(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Timing Recommendations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTimingRecommendations(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Nutritional Density Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildNutritionalDensity(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Satiety Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSatietyScore(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Impact on Goals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildImpactOnGoals(l10n),
            ),

            const SizedBox(height: 24),

            // Similar Foods / Alternatives
            if (_similarFoods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSimilarFoodsSection(l10n),
              ),

            if (_similarFoods.isNotEmpty)
              const SizedBox(height: 24),

            // Meal Pairing Suggestions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildMealPairingSuggestions(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Preparation Tips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPreparationTips(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Nutritional Comparison with Common Foods
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCommonFoodsComparison(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Additional Info Section (Sodium, Cholesterol, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildAdditionalInfoSection(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Extra Details Section (Specialized nutrients)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildExtraDetailsSection(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Ingredients Section
            if (widget.food['ingredients'] != null && widget.food['ingredients'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildIngredientsSection(l10n),
              ),

            if (widget.food['ingredients'] != null && widget.food['ingredients'].toString().isNotEmpty)
              const SizedBox(height: 24),

            // Quick Facts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildQuickFacts(factor, l10n),
            ),

            const SizedBox(height: 24),

            // Detailed Nutrition Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nutritionalBreakdown,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Group by category
                    ..._buildNutritionByCategory(factor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Log Button
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: FlowButton(
                text: '${l10n.logTo} ${widget.mealType}',
              isLoading: _isSaving,
              onPressed: _logMeal,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, double value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 24),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(0)}$unit',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildMacroPieSections(double protein, double carbs, double fat) {
    final total = protein + carbs + fat;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          title: '',
          radius: 60,
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: protein,
        color: AppColors.primary,
        title: '${((protein / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: carbs,
        color: Colors.orange,
        title: '${((carbs / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: fat,
        color: Colors.purple,
        title: '${((fat / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMacroRatioAnalysis(double protein, double carbs, double fat, double factor, AppLocalizations l10n) {
    final total = protein + carbs + fat;
    if (total == 0) return const SizedBox.shrink();
    
    final proteinPercent = (protein / total * 100);
    final carbsPercent = (carbs / total * 100);
    final fatPercent = (fat / total * 100);
    
    String analysis = '';
    Color analysisColor = AppColors.textSecondary;
    
    // High protein
    if (proteinPercent > 40) {
      analysis = 'High protein ratio - great for muscle maintenance';
      analysisColor = AppColors.success;
    }
    // Balanced
    else if (proteinPercent > 25 && carbsPercent > 30 && fatPercent > 15) {
      analysis = 'Well-balanced macro distribution';
      analysisColor = AppColors.primary;
    }
    // High carb
    else if (carbsPercent > 60) {
      analysis = 'High carb ratio - good for energy, watch if low activity';
      analysisColor = AppColors.warning;
    }
    // High fat
    else if (fatPercent > 50) {
      analysis = 'High fat ratio - good for satiety, monitor if weight loss goal';
      analysisColor = AppColors.warning;
    }
    // Low protein
    else if (proteinPercent < 15) {
      analysis = 'Low protein ratio - consider adding protein source';
      analysisColor = AppColors.warning;
    }
    
    if (analysis.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysisColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: analysisColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: analysisColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              analysis,
              style: TextStyle(fontSize: 12, color: analysisColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(Map<String, dynamic> impact) {
    final caloriesProgress = (impact['calories'] as double) / (impact['calorieTarget'] as double);
    final proteinProgress = (impact['protein'] as double) / (impact['proteinTarget'] as double);
    final carbsProgress = (impact['carbs'] as double) / (impact['carbsTarget'] as double);
    final fatProgress = (impact['fat'] as double) / (impact['fatTarget'] as double);
    
    final avgProgress = (caloriesProgress + proteinProgress + carbsProgress + fatProgress) / 4;
    
    String status = '';
    Color statusColor = AppColors.primary;
    
    if (avgProgress >= 1.0) {
      status = 'Complete';
      statusColor = AppColors.success;
    } else if (avgProgress >= 0.8) {
      status = 'Near Target';
      statusColor = AppColors.warning;
    } else if (avgProgress >= 0.5) {
      status = 'On Track';
      statusColor = AppColors.primary;
    } else {
      status = 'Getting Started';
      statusColor = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
      ),
    );
  }

  Widget _buildProgressBar(String label, double current, double target, Color color) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isOver = current > target;
    final percent = (progress * 100).clamp(0.0, 200.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(
            children: [
                Text(
                  '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOver ? AppColors.warning : AppColors.textSecondary,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOver ? AppColors.warning : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.warning : color),
          ),
        ),
        if (isOver)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Exceeds target by ${(current - target).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10, color: AppColors.warning),
            ),
          ),
      ],
    );
  }

  Widget _buildNutritionTableRow(NutrientMeta meta, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (meta.icon != Icons.circle)
            Icon(meta.icon, color: AppColors.primary, size: 20)
          else
              Container(
                width: 12,
                height: 12,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.getLocalizedName(context),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (meta.getLocalizedDescription(context).isNotEmpty)
                  Text(
                    meta.getLocalizedDescription(context),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${value.toStringAsFixed(1)} ${meta.unit}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStandardSizeChips() {
    final sizes = _unit == 'ml' 
        ? [100.0, 150.0, 200.0, 250.0, 300.0, 500.0, 750.0, 1000.0]
        : [50.0, 100.0, 150.0, 200.0, 250.0, 300.0, 400.0, 500.0];
    
    return sizes.map((size) {
      final isSelected = (_quantity - size).abs() < 0.1;
      return GestureDetector(
        onTap: () {
          setState(() {
            _quantity = size;
            _quantityController.text = size.toStringAsFixed(size == size.toInt() ? 0 : 1);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${size.toStringAsFixed(size == size.toInt() ? 0 : 1)}$_unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildHealthScore(double factor, AppLocalizations l10n) {
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
    final saturatedFat = ((widget.food['saturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final sodium = ((widget.food['sodium'] as num?)?.toDouble() ?? 0.0) * factor;
    final vitaminC = ((widget.food['vitamin_c'] as num?)?.toDouble() ?? 0.0) * factor;
    final calcium = ((widget.food['calcium'] as num?)?.toDouble() ?? 0.0) * factor;
    final iron = ((widget.food['iron'] as num?)?.toDouble() ?? 0.0) * factor;
    
    // Calculate health score more accurately (0-100)
    double score = 0;
    
    // Positive factors (max 70 points)
    if (fiber > 0) score += (fiber / 10).clamp(0, 15); // Up to 15 points for fiber
    if (protein > 0) score += (protein / 5).clamp(0, 15); // Up to 15 points for protein
    if (vitaminC > 0) score += (vitaminC / 50).clamp(0, 10); // Up to 10 points for vitamin C
    if (calcium > 0) score += (calcium / 200).clamp(0, 10); // Up to 10 points for calcium
    if (iron > 0) score += (iron / 5).clamp(0, 10); // Up to 10 points for iron
    if (calories > 0 && calories < 400) score += 10; // Bonus for moderate calories
    
    // Negative factors (subtract points, max -30)
    if (sugar > 30) score -= ((sugar - 30) / 10).clamp(0, 15); // Penalty for high sugar
    if (saturatedFat > 15) score -= ((saturatedFat - 15) / 5).clamp(0, 10); // Penalty for high sat fat
    if (sodium > 1000) score -= ((sodium - 1000) / 200).clamp(0, 10); // Penalty for high sodium
    if (calories > 600) score -= ((calories - 600) / 100).clamp(0, 10); // Penalty for very high calories
    
    score = score.clamp(0, 100);
    final color = score >= 75 ? AppColors.success : score >= 50 ? AppColors.warning : AppColors.error;
    final label = score >= 75 ? l10n.excellent : score >= 50 ? l10n.good : l10n.moderate;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.healthScore,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 12,
                        backgroundColor: color.withAlpha(50),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreIndicator('Fiber', fiber, 5, l10n),
                    _buildScoreIndicator('Protein', protein, 20, l10n),
                    _buildScoreIndicator('Sugar', sugar, 20, l10n, isNegative: true),
                    _buildScoreIndicator('Sat. Fat', saturatedFat, 10, l10n, isNegative: true),
                    if (sodium > 0) _buildScoreIndicator('Sodium', sodium, 1000, l10n, isNegative: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double value, double threshold, AppLocalizations l10n, {bool isNegative = false}) {
    final good = isNegative ? value < threshold : value > threshold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            good ? Icons.check_circle : Icons.cancel,
            color: good ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: good ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}${isNegative ? 'mg' : 'g'}',
            style: TextStyle(
              fontSize: 12,
              color: good ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrientChart(double factor, AppLocalizations l10n) {
    final micronutrients = [
      {'key': 'vitamin_c', 'name': 'Vitamin C', 'rda': 90.0},
      {'key': 'vitamin_d', 'name': 'Vitamin D', 'rda': 15.0},
      {'key': 'calcium', 'name': 'Calcium', 'rda': 1000.0},
      {'key': 'iron', 'name': 'Iron', 'rda': 18.0},
      {'key': 'magnesium', 'name': 'Magnesium', 'rda': 400.0},
      {'key': 'zinc', 'name': 'Zinc', 'rda': 11.0},
    ];
    
    final bars = micronutrients.map((nutrient) {
      final val = ((widget.food[nutrient['key']] as num?)?.toDouble() ?? 0.0) * factor;
      final rda = nutrient['rda'] as double;
      final percent = (val / rda * 100).clamp(0.0, 100.0);
      return BarChartGroupData(
        x: micronutrients.indexOf(nutrient),
        barRods: [
          BarChartRodData(
            toY: percent,
            color: percent >= 100 ? AppColors.success : percent >= 50 ? AppColors.warning : AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.micronutrientCoverage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                maxY: 100,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= micronutrients.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            micronutrients[value.toInt()]['name'].toString().split(' ').last,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRDAComparisonTable(double factor, AppLocalizations l10n) {
    final micronutrients = [
      {'key': 'vitamin_c', 'rda': 90.0, 'unit': 'mg'},
      {'key': 'vitamin_d', 'rda': 15.0, 'unit': 'μg'},
      {'key': 'calcium', 'rda': 1000.0, 'unit': 'mg'},
      {'key': 'iron', 'rda': 18.0, 'unit': 'mg'},
      {'key': 'magnesium', 'rda': 400.0, 'unit': 'mg'},
      {'key': 'zinc', 'rda': 11.0, 'unit': 'mg'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rdaComparison,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                children: [
                  _buildTableCell('Nutrient', isHeader: true),
                  _buildTableCell('Amount', isHeader: true, align: TextAlign.center),
                  _buildTableCell('RDA', isHeader: true, align: TextAlign.center),
                  _buildTableCell('Status', isHeader: true, align: TextAlign.center),
                ],
              ),
              ...micronutrients.map((nutrient) {
                final val = ((widget.food[nutrient['key']] as num?)?.toDouble() ?? 0.0) * factor;
                final rda = nutrient['rda'] as double;
                final percent = (val / rda * 100);
                String status;
                Color statusColor;
                if (percent >= 100) {
                  status = l10n.exceedsDailyNeeds;
                  statusColor = AppColors.success;
                } else if (percent >= 50) {
                  status = l10n.meetsDailyNeeds;
                  statusColor = AppColors.warning;
                } else {
                  status = l10n.belowDailyNeeds;
                  statusColor = AppColors.textSecondary;
                }
                
                return TableRow(
                  children: [
                    _buildTableCell(NutritionData.nutrients.firstWhere((n) => n.key == nutrient['key']).getLocalizedName(context)),
                    _buildTableCell('${val.toStringAsFixed(1)} ${nutrient['unit']}', align: TextAlign.center),
                    _buildTableCell('${rda.toStringAsFixed(0)} ${nutrient['unit']}', align: TextAlign.center),
                    _buildTableCell(status, color: statusColor, align: TextAlign.center),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isHeader ? 14 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? AppColors.primary : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildBodyImpactSection(double factor, AppLocalizations l10n) {
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final vitaminC = ((widget.food['vitamin_c'] as num?)?.toDouble() ?? 0.0) * factor;
    final vitaminD = ((widget.food['vitamin_d'] as num?)?.toDouble() ?? 0.0) * factor;
    final vitaminB12 = ((widget.food['vitamin_b12'] as num?)?.toDouble() ?? 0.0) * factor;
    final calcium = ((widget.food['calcium'] as num?)?.toDouble() ?? 0.0) * factor;
    final iron = ((widget.food['iron'] as num?)?.toDouble() ?? 0.0) * factor;
    final magnesium = ((widget.food['magnesium'] as num?)?.toDouble() ?? 0.0) * factor;
    final potassium = ((widget.food['potassium'] as num?)?.toDouble() ?? 0.0) * factor;
    final zinc = ((widget.food['zinc'] as num?)?.toDouble() ?? 0.0) * factor;
    final omega3 = ((widget.food['omega3'] as num?)?.toDouble() ?? 0.0) * factor;
    final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    
    final impacts = <Map<String, dynamic>>[];
    
    // Protein impacts
    if (protein > 25) impacts.add({'icon': Icons.fitness_center, 'text': 'Excellent for muscle building and recovery', 'color': AppColors.primary});
    else if (protein > 15) impacts.add({'icon': Icons.fitness_center, 'text': l10n.supportsMuscleGrowth, 'color': AppColors.primary});
    
    // Fiber impacts
    if (fiber > 8) impacts.add({'icon': Icons.grass, 'text': 'High fiber - great for digestion and satiety', 'color': AppColors.success});
    else if (fiber > 5) impacts.add({'icon': Icons.grass, 'text': l10n.aidsDigestion, 'color': AppColors.success});
    else if (fiber > 3) impacts.add({'icon': Icons.grass, 'text': 'Moderate fiber content', 'color': AppColors.success});
    
    // Vitamin C
    if (vitaminC > 60) impacts.add({'icon': Icons.health_and_safety, 'text': 'Very high in Vitamin C - excellent for immunity', 'color': AppColors.accent});
    else if (vitaminC > 30) impacts.add({'icon': Icons.health_and_safety, 'text': l10n.boostsImmunity, 'color': AppColors.accent});
    
    // Vitamin D
    if (vitaminD > 5) impacts.add({'icon': Icons.wb_sunny, 'text': 'Good source of Vitamin D for bone health', 'color': Colors.orange});
    
    // Vitamin B12
    if (vitaminB12 > 1) impacts.add({'icon': Icons.bloodtype, 'text': 'Rich in B12 - supports energy and nerve function', 'color': Colors.red});
    
    // Calcium
    if (calcium > 300) impacts.add({'icon': Icons.medical_services, 'text': 'Excellent source of calcium for strong bones', 'color': Colors.blue});
    else if (calcium > 150) impacts.add({'icon': Icons.medical_services, 'text': l10n.supportsBoneHealth, 'color': Colors.blue});
    
    // Iron
    if (iron > 3) impacts.add({'icon': Icons.bloodtype, 'text': 'High in iron - supports oxygen transport', 'color': Colors.red});
    else if (iron > 1.5) impacts.add({'icon': Icons.bloodtype, 'text': 'Good iron source for blood health', 'color': Colors.red});
    
    // Magnesium
    if (magnesium > 100) impacts.add({'icon': Icons.battery_charging_full, 'text': 'Rich in magnesium - supports muscle and nerve function', 'color': Colors.green});
    
    // Potassium
    if (potassium > 400) impacts.add({'icon': Icons.favorite, 'text': 'High potassium - helps regulate blood pressure', 'color': Colors.purple});
    
    // Zinc
    if (zinc > 2) impacts.add({'icon': Icons.shield, 'text': 'Good zinc source - supports immune system', 'color': Colors.amber});
    
    // Omega-3
    if (omega3 > 1) impacts.add({'icon': Icons.favorite, 'text': 'Excellent source of Omega-3 for heart and brain health', 'color': Colors.red});
    else if (omega3 > 0.5) impacts.add({'icon': Icons.favorite, 'text': l10n.improvesHeartHealth, 'color': Colors.red});
    
    // Energy/Carbs
    if (carbs > 40 && calories < 300) impacts.add({'icon': Icons.bolt, 'text': 'Good energy source without excess calories', 'color': Colors.orange});
    else if (carbs > 30) impacts.add({'icon': Icons.bolt, 'text': 'Provides sustained energy', 'color': Colors.orange});
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(25), AppColors.secondary.withAlpha(25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.bodyImpact,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...impacts.map((impact) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(impact['icon'] as IconData, color: impact['color'] as Color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    impact['text'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNutritionalDensity(double factor, AppLocalizations l10n) {
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
    final saturatedFat = ((widget.food['saturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    
    final proteinDensity = calories > 0 ? (protein * 4 / calories * 100).toDouble() : 0.0;
    final fiberDensity = calories > 0 ? (fiber / calories * 100).toDouble() : 0.0;
    
    String getDensityLabel(double value, bool isGood) {
      if (isGood) {
        if (value >= 80) return l10n.excellent;
        if (value >= 60) return l10n.good;
        if (value >= 40) return l10n.moderate;
        return l10n.low;
      } else {
        if (value >= 30) return l10n.veryHigh;
        if (value >= 20) return l10n.high;
        if (value >= 10) return l10n.moderate;
        return l10n.low;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.nutritionalDensity,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDensityRow(l10n.proteinQuality, proteinDensity, true),
          _buildDensityRow(l10n.fiberContent, fiberDensity, true),
          _buildDensityRow(l10n.sugarContent, sugar, false),
          _buildDensityRow(l10n.saturatedFatContent, saturatedFat, false),
        ],
      ),
    );
  }

  Widget _buildDensityRow(String label, double value, bool isGood) {
    String getLabel(double val, bool good) {
      if (good) {
        if (val >= 80) return 'Excellent';
        if (val >= 60) return 'Good';
        if (val >= 40) return 'Moderate';
        return 'Low';
      } else {
        if (val >= 30) return 'Very High';
        if (val >= 20) return 'High';
        if (val >= 10) return 'Moderate';
        return 'Low';
      }
    }
    
    final labelText = getLabel(value, isGood);
    final color = isGood 
        ? (value >= 60 ? AppColors.success : value >= 40 ? AppColors.warning : AppColors.textSecondary)
        : (value >= 20 ? AppColors.error : value >= 10 ? AppColors.warning : AppColors.success);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatietyScore(double factor, AppLocalizations l10n) {
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final water = ((widget.food['water'] as num?)?.toDouble() ?? 0.0) * factor;
    
    // Calculate satiety score (0-100)
    // Based on: protein, fiber, fat, water content, and calorie density
    double satietyScore = 0;
    
    // Protein contributes up to 30 points
    if (protein > 0) {
      satietyScore += (protein / 30 * 30).clamp(0, 30);
    }
    
    // Fiber contributes up to 25 points
    if (fiber > 0) {
      satietyScore += (fiber / 10 * 25).clamp(0, 25);
    }
    
    // Fat contributes up to 20 points (moderate fat is good for satiety)
    if (fat > 0 && fat < 30) {
      satietyScore += (fat / 20 * 20).clamp(0, 20);
    }
    
    // Water content contributes up to 15 points
    if (water > 0) {
      satietyScore += (water / 200 * 15).clamp(0, 15);
    }
    
    // Calorie density penalty (lower calories per gram = better satiety)
    if (calories > 0) {
      final density = calories / _quantity;
      if (density < 1.5) {
        satietyScore += 10; // Low calorie density = high volume
      } else if (density < 2.5) {
        satietyScore += 5;
      }
    }
    
    satietyScore = satietyScore.clamp(0, 100);
    
    String satietyLabel = '';
    Color satietyColor = AppColors.textSecondary;
    
    if (satietyScore >= 70) {
      satietyLabel = 'Very Filling';
      satietyColor = AppColors.success;
    } else if (satietyScore >= 50) {
      satietyLabel = 'Moderately Filling';
      satietyColor = AppColors.primary;
    } else if (satietyScore >= 30) {
      satietyLabel = 'Somewhat Filling';
      satietyColor = AppColors.warning;
    } else {
      satietyLabel = 'Not Very Filling';
      satietyColor = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.satietyScore,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: satietyColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: satietyColor),
                ),
                child: Text(
                  satietyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: satietyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${satietyScore.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: satietyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How full you\'ll feel',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: satietyScore / 100,
                  strokeWidth: 8,
                  backgroundColor: satietyColor.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(satietyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (protein > 15) ...[
                _buildSatietyFactor('Protein', protein, 15, Icons.fitness_center),
                const SizedBox(width: 12),
              ],
              if (fiber > 3) ...[
                _buildSatietyFactor('Fiber', fiber, 3, Icons.grass),
                const SizedBox(width: 12),
              ],
              if (fat > 5 && fat < 25) ...[
                _buildSatietyFactor('Fat', fat, 5, Icons.opacity),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSatietyFactor(String label, double value, double threshold, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildQuickFacts(double factor, AppLocalizations l10n) {
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
    final sodium = ((widget.food['sodium'] as num?)?.toDouble() ?? 0.0) * factor;
    final caffeine = ((widget.food['caffeine'] as num?)?.toDouble() ?? 0.0) * factor;
    final water = ((widget.food['water'] as num?)?.toDouble() ?? 0.0) * factor;
    final waterContent = ((widget.food['water_content'] as num?)?.toDouble() ?? 0.0) * factor;
    
    // Calculate water amount - use water field, water_content field, or estimate from unit
    double waterAmount = water;
    if (waterAmount == 0 && waterContent > 0) {
      // If water_content is percentage, calculate from quantity
      waterAmount = (_quantity * waterContent / 100.0);
    } else if (waterAmount == 0 && _unit.toLowerCase() == 'ml') {
      // If unit is ml, assume it's mostly water
      waterAmount = _quantity;
    } else if (waterAmount == 0) {
      // Estimate water content based on food type
      final foodName = (widget.food['name']?.toString() ?? '').toLowerCase();
      if (foodName.contains('water') || foodName.contains('juice') || 
          foodName.contains('soup') || foodName.contains('tea') || 
          foodName.contains('coffee') || foodName.contains('drink')) {
        waterAmount = _unit.toLowerCase() == 'ml' ? _quantity : _quantity * 0.95;
      } else if (foodName.contains('fruit') || foodName.contains('vegetable')) {
        waterAmount = _quantity * 0.85; // Fruits/vegetables are ~85% water
      }
    }
    
    // Calculate energy density (calories per gram)
    final energyDensity = _quantity > 0 ? calories / _quantity : 0.0;
    String densityLabel = '';
    Color densityColor = AppColors.textSecondary;
    
    final l10n = AppLocalizations.of(context)!;
    if (energyDensity < 1.0) {
      densityLabel = l10n.lowEnergyDensity;
      densityColor = AppColors.success;
    } else if (energyDensity < 2.0) {
      densityLabel = l10n.moderateEnergyDensity;
      densityColor = AppColors.primary;
    } else if (energyDensity < 3.0) {
      densityLabel = l10n.highEnergyDensity;
      densityColor = AppColors.warning;
    } else {
      densityLabel = l10n.veryHighEnergyDensity;
      densityColor = AppColors.error;
    }
    
    // Calculate protein percentage
    final totalMacros = protein + carbs + fat;
    final proteinPercent = totalMacros > 0 ? (protein / totalMacros * 100) : 0.0;
    
    // Net carbs
    final netCarbs = carbs - fiber;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.quickFacts,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFactChip('Energy Density', densityLabel, densityColor, Icons.speed),
              if (proteinPercent > 0)
                _buildFactChip('Protein', '${proteinPercent.toStringAsFixed(0)}% of macros', AppColors.primary, Icons.fitness_center),
              if (netCarbs > 0)
                _buildFactChip('Net Carbs', '${netCarbs.toStringAsFixed(1)}g', Colors.orange, Icons.bolt),
              if (fiber > 0)
                _buildFactChip('Fiber', '${fiber.toStringAsFixed(1)}g', AppColors.success, Icons.grass),
              if (sugar > 0)
                _buildFactChip('Sugar', '${sugar.toStringAsFixed(1)}g', sugar > 20 ? AppColors.warning : AppColors.textSecondary, Icons.cake),
              if (sodium > 0)
                _buildFactChip('Sodium', '${sodium.toStringAsFixed(0)}mg', sodium > 800 ? AppColors.warning : AppColors.textSecondary, Icons.water_drop),
              if (caffeine > 0)
                _buildFactChip('Caffeine', '${caffeine.toStringAsFixed(0)}mg', caffeine > 100 ? AppColors.warning : AppColors.primary, Icons.coffee),
              if (waterAmount > 0)
                _buildFactChip('Water', '${waterAmount.toStringAsFixed(0)}${_unit.toLowerCase() == 'ml' ? 'ml' : 'g'}', AppColors.primary, Icons.water_drop),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPortionGuide(double factor, AppLocalizations l10n) {
    final foodName = (widget.food['name']?.toString() ?? '').toLowerCase();
    String portionGuide = '';
    String emoji = '🍽️';
    
    // Generate portion guide based on quantity and unit
    if (_unit == 'g') {
      if (_quantity == 100) {
        portionGuide = '100g is about 1 serving';
        if (foodName.contains('apple')) {
          portionGuide = '100g = 1 medium apple 🍎';
          emoji = '🍎';
        } else if (foodName.contains('banana')) {
          portionGuide = '100g = 1 medium banana 🍌';
          emoji = '🍌';
        } else if (foodName.contains('chicken') || foodName.contains('meat')) {
          portionGuide = '100g = size of a deck of cards 🃏';
          emoji = '🍗';
        } else if (foodName.contains('rice') || foodName.contains('pasta')) {
          portionGuide = '100g = 1/2 cup cooked 🍚';
          emoji = '🍚';
        } else if (foodName.contains('bread')) {
          portionGuide = '100g = 2-3 slices 🍞';
          emoji = '🍞';
        } else if (foodName.contains('cheese')) {
          portionGuide = '100g = 4 dice-sized cubes 🧀';
          emoji = '🧀';
        }
      } else if (_quantity == 200) {
        portionGuide = '200g = 2 servings';
      } else if (_quantity == 50) {
        portionGuide = '50g = 1/2 serving';
      }
    } else if (_unit == 'ml') {
      if (_quantity == 250) {
        portionGuide = '250ml = 1 cup 🥤';
        emoji = '🥤';
      } else if (_quantity == 500) {
        portionGuide = '500ml = 2 cups 🥤';
        emoji = '🥤';
      } else if (_quantity == 100) {
        portionGuide = '100ml = 1/2 cup';
      }
    }
    
    if (portionGuide.isEmpty) {
      portionGuide = '${_quantity.toStringAsFixed(0)}${_unit} portion';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              portionGuide,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPairingSuggestions(double factor, AppLocalizations l10n) {
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPairingSuggestions(protein, carbs, fiber, calories),
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];
        
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                AppLocalizations.of(context)!.completeYourMeal,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...suggestions.take(3).map((food) {
                final foodName = food['name']?.toString() ?? 'Unknown';
                final foodId = food['id']?.toString();
                final foodProtein = ((food['protein'] as num?)?.toDouble() ?? 0.0);
                final foodCalories = ((food['calories'] as num?)?.toDouble() ?? 0.0);
                
                String reason = '';
                String icon = '🍽️';
                
                if (foodProtein > 20) {
                  reason = 'High protein to complete your meal';
                  icon = '🍗';
                } else if (food['fiber'] != null && ((food['fiber'] as num?)?.toDouble() ?? 0.0) > 5) {
                  reason = 'Adds fiber and volume';
                  icon = '🥦';
                } else if (foodCalories < 100) {
                  reason = 'Low calorie, nutrient-dense option';
                  icon = '🥗';
                } else {
                  reason = 'Complements this meal well';
                }
                
                return GestureDetector(
                  onTap: () async {
                    if (foodId != null) {
                      final shouldNavigate = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.viewFoodDetails),
                          content: Text(
                            AppLocalizations.of(context)!.wouldLikeToViewDetails(foodName)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(AppLocalizations.of(context)!.view),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldNavigate == true && mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailPage(
                              food: food,
                              mealType: widget.mealType,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${foodCalories.toStringAsFixed(0)} kcal',
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${foodProtein.toStringAsFixed(1)}g protein',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getPairingSuggestions(
    double protein,
    double carbs,
    double fiber,
    double calories,
  ) async {
    try {
      List<Map<String, dynamic>> suggestions = [];
      
      // If low protein, suggest high protein foods
      if (protein < 15 && calories < 300) {
        final highProtein = await _supabaseService.searchFoodsForPairing(
          minProtein: 20.0,
          maxCalories: 200.0,
          limit: 2,
        );
        suggestions.addAll(highProtein);
      }
      
      // If low fiber, suggest high fiber foods
      if (fiber < 5 && calories < 400) {
        final highFiber = await _supabaseService.searchFoodsForPairing(
          minFiber: 5.0,
          maxCalories: 150.0,
          limit: 2,
        );
        suggestions.addAll(highFiber);
      }
      
      // If low carbs, suggest complex carbs
      if (carbs < 20 && calories < 250) {
        final complexCarbs = await _supabaseService.searchFoodsForPairing(
          maxCalories: 150.0,
          limit: 2,
        );
        suggestions.addAll(complexCarbs);
      }
      
      // Always suggest something
      if (suggestions.isEmpty) {
        final general = await _supabaseService.searchFoodsForPairing(
          maxCalories: 200.0,
          limit: 3,
        );
        suggestions.addAll(general);
      }
      
      // Remove current food if present
      final currentFoodId = widget.food['id']?.toString();
      suggestions.removeWhere((food) => food['id']?.toString() == currentFoodId);
      
      return suggestions.take(3).toList();
    } catch (e) {
      print('Error getting pairing suggestions: $e');
      return [];
    }
  }

  Widget _buildPreparationTips(double factor, AppLocalizations l10n) {
    final foodName = (widget.food['name']?.toString() ?? '').toLowerCase();
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
    
    final tips = <String>[];
    
    // Cooking method tips
    if (foodName.contains('chicken') || foodName.contains('meat') || foodName.contains('fish')) {
      tips.add('💡 Steam or grill instead of frying to reduce calories');
      tips.add('💡 Remove visible fat before cooking');
      tips.add('💡 Use herbs and spices instead of heavy sauces');
    } else if (foodName.contains('vegetable') || foodName.contains('broccoli') || foodName.contains('carrot')) {
      tips.add('💡 Steam or roast to preserve nutrients');
      tips.add('💡 Avoid overcooking to maintain vitamins');
    } else if (foodName.contains('rice') || foodName.contains('pasta')) {
      tips.add('💡 Choose whole grain versions for more fiber');
      tips.add('💡 Cook al dente for lower glycemic index');
    } else if (foodName.contains('potato') || foodName.contains('fries')) {
      tips.add('💡 Bake or air-fry instead of deep-frying');
      tips.add('💡 Keep the skin for extra fiber');
    }
    
    // General tips
    if (fat > 15) {
      tips.add('💡 Consider portion control due to high fat content');
    }
    
    if (calories > 400) {
      tips.add('💡 Pair with low-calorie vegetables to balance the meal');
    }
    
    if (tips.isEmpty) {
      tips.add('💡 Fresh is best - minimal processing preserves nutrients');
      tips.add('💡 Read labels for added sugars and sodium');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.preparationTips,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCommonFoodsComparison(double factor, AppLocalizations l10n) {
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodName = (widget.food['name']?.toString() ?? '').toLowerCase();
    
    // Common foods for comparison (per 100g or standard portion)
    final commonFoods = [
      {'name': 'Apple', 'calories': 52.0, 'protein': 0.3, 'icon': '🍎'},
      {'name': 'Chicken Breast', 'calories': 165.0, 'protein': 31.0, 'icon': '🍗'},
      {'name': 'Brown Rice', 'calories': 111.0, 'protein': 2.6, 'icon': '🍚'},
      {'name': 'Banana', 'calories': 89.0, 'protein': 1.1, 'icon': '🍌'},
      {'name': 'Egg', 'calories': 155.0, 'protein': 13.0, 'icon': '🥚'},
    ];
    
    // Find similar category food for comparison
    Map<String, dynamic>? comparisonFood;
    if (foodName.contains('apple')) {
      comparisonFood = commonFoods[0];
    } else if (foodName.contains('chicken') || foodName.contains('meat')) {
      comparisonFood = commonFoods[1];
    } else if (foodName.contains('rice') || foodName.contains('grain')) {
      comparisonFood = commonFoods[2];
    } else if (foodName.contains('banana')) {
      comparisonFood = commonFoods[3];
    } else {
      // Compare with closest calorie match
      comparisonFood = commonFoods.reduce((a, b) {
        final aDiff = (calories - (a['calories'] as double)).abs();
        final bDiff = (calories - (b['calories'] as double)).abs();
        return aDiff < bDiff ? a : b;
      });
    }
    
    final comparisonCalories = comparisonFood['calories'] as double;
    final comparisonProtein = comparisonFood['calories'] as double;
    final comparisonIcon = comparisonFood['icon'] as String;
    final comparisonName = comparisonFood['name'] as String;
    
    final caloriesDiff = ((calories - comparisonCalories) / comparisonCalories * 100);
    final proteinDiff = protein > 0 && comparisonProtein > 0 
        ? ((protein - comparisonProtein) / comparisonProtein * 100) 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.quickComparison,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.thisFood, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      '${calories.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(AppLocalizations.of(context)!.kcalUnit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${protein.toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    ),
                    Text(AppLocalizations.of(context)!.nutrient_protein, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.compare_arrows, size: 24, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    caloriesDiff > 0 
                        ? '+${caloriesDiff.toStringAsFixed(0)}%'
                        : '${caloriesDiff.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: caloriesDiff > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(comparisonIcon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(comparisonName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${comparisonCalories.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(AppLocalizations.of(context)!.kcalUnit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${comparisonProtein.toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    ),
                    Text(AppLocalizations.of(context)!.nutrient_protein, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactOnGoals(AppLocalizations l10n) {
    final goal = _profile?['goal']?.toString() ?? 'MAINTAIN';
    final factor = _quantity / 100.0;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
    final saturatedFat = ((widget.food['saturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final sodium = ((widget.food['sodium'] as num?)?.toDouble() ?? 0.0) * factor;
    final calorieTarget = ((_profile?['daily_calorie_target'] as num?)?.toInt() ?? 2000);
    final remainingCalories = calorieTarget - (_todayTotals['calories'] ?? 0.0);
    final newTotalCalories = (_todayTotals['calories'] ?? 0.0) + calories;
    final now = DateTime.now();
    final hour = now.hour;
    
    final recommendations = <String>[];
    final warnings = <String>[];
    final tips = <String>[];
    
    if (goal == 'LOSE') {
      // Positive recommendations - comprehensive
      if (protein > 25 && fiber > 6 && calories < 280 && sugar < 15) {
        recommendations.add('🌟 Excellent choice! High protein, high fiber, low calories - perfect for weight loss');
      } else if (protein > 20 && fiber > 5 && calories < 300) {
        recommendations.add('✅ Great for weight loss: high protein and fiber keep you full, low calories');
      } else if (protein > 15 && fiber > 4 && calories < 350 && sugar < 20) {
        recommendations.add('✅ Good choice: balanced nutrition that supports weight loss');
      } else if (calories < 200 && fiber > 4 && protein > 8) {
        recommendations.add('✅ Low calorie, high fiber - excellent for satiety without excess calories');
      } else if (protein > 20 && calories < 250) {
        recommendations.add('✅ High protein, low calorie - helps preserve muscle during weight loss');
      } else if (calories < 150 && fiber > 3) {
        recommendations.add('✅ Very low calorie - great for volume eating');
      }
      
      // Warnings - comprehensive
      if (calories > 700) {
        warnings.add('⚠️ Very high calories - this single item could be 35%+ of your daily budget');
      } else if (calories > 500 && newTotalCalories > calorieTarget * 1.15) {
        warnings.add('⚠️ High calories - will significantly exceed your daily target');
      } else if (calories > 400 && newTotalCalories > calorieTarget * 1.1) {
        warnings.add('⚠️ Will exceed your daily calorie target');
      } else if (calories > 450 && protein < 12) {
        warnings.add('⚠️ High calories with low protein - not very filling for the calories');
      }
      
      if (sugar > 50) {
        warnings.add('⚠️ Very high sugar - may cause blood sugar spikes and energy crashes');
      } else if (sugar > 35 && calories > 300) {
        warnings.add('⚠️ High sugar content - consider timing (better in morning)');
      } else if (sugar > 25 && calories > 250) {
        warnings.add('⚠️ Moderate to high sugar - monitor your daily sugar intake');
      }
      
      if (saturatedFat > 20) {
        warnings.add('⚠️ Very high saturated fat - limit consumption, especially if you have heart concerns');
      } else if (saturatedFat > 15) {
        warnings.add('⚠️ High saturated fat - consume in moderation');
      } else if (saturatedFat > 10 && calories > 300) {
        warnings.add('⚠️ Moderate saturated fat - balance with other meals');
      }
      
      if (calories > 400 && protein < 8) {
        warnings.add('⚠️ Low protein for the calories - won\'t keep you full long');
      }
      
      if (calories > 350 && fiber < 2) {
        warnings.add('⚠️ Low fiber - may not provide lasting satiety');
      }
      
      if (sodium > 1200 && calories > 300) {
        warnings.add('⚠️ Very high sodium - may cause water retention and bloating');
      } else if (sodium > 800) {
        warnings.add('⚠️ High sodium - drink extra water');
      }
      
      // Tips - comprehensive
      if (remainingCalories < 400 && calories > 250) {
        tips.add('💡 Consider a smaller portion (${(_quantity * 0.7).toStringAsFixed(0)}${_unit}) to stay within budget');
      } else if (remainingCalories < 300 && calories > 200) {
        tips.add('💡 You have limited calories left - this might be too much');
      }
      
      if (protein > 18 && calories < 280) {
        tips.add('💡 Excellent protein-to-calorie ratio - great for preserving muscle');
      }
      
      if (fiber > 5 && calories < 300) {
        tips.add('💡 High fiber will keep you full for hours');
      }
      
      if (calories < 200 && protein > 10) {
        tips.add('💡 Perfect snack - low calorie but still nutritious');
      }
      
      if (sugar > 20 && hour < 14) {
        tips.add('💡 High sugar - better consumed in the morning for energy');
      }
      
    } else if (goal == 'GAIN') {
      // Positive recommendations - comprehensive
      if (calories > 500 && protein > 25 && carbs > 40) {
        recommendations.add('🌟 Perfect for weight gain! High calories, protein, and carbs - ideal post-workout');
      } else if (calories > 450 && protein > 20) {
        recommendations.add('✅ Excellent for muscle gain - high calories and protein');
      } else if (calories > 350 && protein > 18 && carbs > 30) {
        recommendations.add('✅ Great choice: supports muscle growth and recovery');
      } else if (calories > 400 && protein > 15) {
        recommendations.add('✅ Good for weight gain - provides calories and protein');
      } else if (calories > 500 && carbs > 50) {
        recommendations.add('✅ High calorie and carbs - good for energy and weight gain');
      } else if (protein > 25 && calories > 300) {
        recommendations.add('✅ High protein content supports muscle building');
      }
      
      // Warnings - comprehensive
      if (calories < 120) {
        warnings.add('⚠️ Very low calories - won\'t contribute meaningfully to weight gain');
      } else if (calories < 200 && protein < 8) {
        warnings.add('⚠️ Too low in calories and protein - not ideal for gaining');
      } else if (calories < 250 && protein < 12) {
        warnings.add('⚠️ Low calories and protein - consider larger portion or different food');
      }
      
      if (calories > 300 && protein < 10) {
        warnings.add('⚠️ Low protein for the calories - prioritize protein for muscle gain');
      }
      
      if (calories > 400 && saturatedFat > 20) {
        warnings.add('⚠️ High saturated fat - while calories are good, balance with healthier fats');
      }
      
      if (sugar > 50 && calories < 300) {
        warnings.add('⚠️ High sugar but low calories - not ideal for sustainable weight gain');
      }
      
      // Tips - comprehensive
      if (calories > 450 && protein > 20) {
        tips.add('💡 Perfect post-workout meal - supports recovery and muscle growth');
      }
      
      if (remainingCalories > 600 && calories < 300) {
        tips.add('💡 You have plenty of room - consider a larger portion (${(_quantity * 1.5).toStringAsFixed(0)}${_unit})');
      }
      
      if (protein > 20 && carbs > 30) {
        tips.add('💡 Great macro balance for muscle gain');
      }
      
      if (calories > 400 && hour < 18) {
        tips.add('💡 High calorie meal - better consumed earlier in the day');
      }
      
      if (calories < 300 && protein > 15) {
        tips.add('💡 Good protein but low calories - pair with calorie-dense foods');
      }
      
    } else { // MAINTAIN
      // Positive recommendations - comprehensive
      if (protein > 18 && fiber > 4 && calories < 450 && sugar < 25 && saturatedFat < 12) {
        recommendations.add('🌟 Excellent balance! High protein, fiber, moderate calories - perfect for maintenance');
      } else if (protein > 15 && fiber > 3 && calories < 500 && sugar < 30) {
        recommendations.add('✅ Well-balanced meal - great for maintaining weight');
      } else if (protein > 12 && fiber > 2 && calories < 550) {
        recommendations.add('✅ Good nutritional balance for maintenance');
      } else if (calories < 400 && protein > 12 && fiber > 3) {
        recommendations.add('✅ Moderate calories with good protein and fiber');
      } else if (protein > 20 && calories < 500) {
        recommendations.add('✅ High protein, moderate calories - supports muscle maintenance');
      }
      
      // Warnings - comprehensive
      if (saturatedFat > 25) {
        warnings.add('⚠️ Very high saturated fat - consume occasionally, not daily');
      } else if (saturatedFat > 18) {
        warnings.add('⚠️ High saturated fat - balance with other meals today');
      } else if (saturatedFat > 15) {
        warnings.add('⚠️ Moderate to high saturated fat - monitor intake');
      }
      
      if (sugar > 60) {
        warnings.add('⚠️ Very high sugar - may cause energy spikes and crashes');
      } else if (sugar > 40) {
        warnings.add('⚠️ High sugar content - better consumed around workouts');
      } else if (sugar > 30) {
        warnings.add('⚠️ Moderate to high sugar - balance with protein and fiber');
      }
      
      if (sodium > 1500) {
        warnings.add('⚠️ Very high sodium - may cause significant water retention');
      } else if (sodium > 1000) {
        warnings.add('⚠️ High sodium - drink extra water and balance with low-sodium meals');
      } else if (sodium > 800) {
        warnings.add('⚠️ Moderate to high sodium - monitor if you\'re sensitive');
      }
      
      if (calories > 700 && newTotalCalories > calorieTarget * 1.25) {
        warnings.add('⚠️ Very high calories - will significantly exceed maintenance target');
      } else if (calories > 600 && newTotalCalories > calorieTarget * 1.2) {
        warnings.add('⚠️ High calories - will exceed your maintenance target');
      } else if (calories > 500 && newTotalCalories > calorieTarget * 1.1) {
        warnings.add('⚠️ Will slightly exceed your maintenance calories');
      }
      
      if (calories > 500 && protein < 10) {
        warnings.add('⚠️ Low protein for the calories - may not be very satisfying');
      }
      
      if (calories > 450 && fiber < 2) {
        warnings.add('⚠️ Low fiber - may not provide lasting fullness');
      }
      
      // Tips - comprehensive
      if (protein > 15 && fiber > 3 && calories < 500) {
        tips.add('💡 Great balance - will keep you satisfied and energized');
      }
      
      if (calories > 500 && remainingCalories < 300) {
        tips.add('💡 High calorie meal - plan lighter meals for the rest of the day');
      }
      
      if (protein > 18 && carbs > 30) {
        tips.add('💡 Good macro balance for sustained energy');
      }
      
      if (saturatedFat > 15) {
        tips.add('💡 High saturated fat - balance with healthy fats in other meals');
      }
      
      if (sugar > 30 && hour > 18) {
        tips.add('💡 High sugar - better consumed earlier in the day');
      }
      
      if (calories < 400 && protein > 12) {
        tips.add('💡 Good portion size for maintenance - satisfying without excess');
      }
    }
    
    // Always show something - even if neutral (after all checks)
    if (recommendations.isEmpty && warnings.isEmpty && tips.isEmpty) {
      // Default neutral message based on goal
      if (goal == 'LOSE') {
        recommendations.add('This food provides ${calories.toStringAsFixed(0)} calories. Monitor portion size to stay within your daily target of ${calorieTarget.toStringAsFixed(0)} kcal.');
      } else if (goal == 'GAIN') {
        recommendations.add('This food provides ${calories.toStringAsFixed(0)} calories. Good for adding to your daily intake of ${calorieTarget.toStringAsFixed(0)} kcal.');
      } else {
        recommendations.add('This food provides ${calories.toStringAsFixed(0)} calories. Balanced portion helps maintain your target of ${calorieTarget.toStringAsFixed(0)} kcal.');
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.impactOnGoals,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recommendations.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.whyThisWorks,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
          if (warnings.isNotEmpty) ...[
            if (recommendations.isNotEmpty) const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Things to Consider',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 13, color: AppColors.warning))),
                ],
              ),
            )),
          ],
          if (tips.isNotEmpty) ...[
            if (recommendations.isNotEmpty || warnings.isNotEmpty) const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tips',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tips.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(double factor, AppLocalizations l10n) {
    final sodium = ((widget.food['sodium'] as num?)?.toDouble() ?? 0.0) * factor;
    final cholesterol = ((widget.food['cholesterol'] as num?)?.toDouble() ?? 0.0) * factor;
    final transFat = ((widget.food['trans_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final monounsaturated = ((widget.food['monounsaturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final polyunsaturated = ((widget.food['polyunsaturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final caffeine = ((widget.food['caffeine'] as num?)?.toDouble() ?? 0.0) * factor;
    final water = ((widget.food['water'] as num?)?.toDouble() ?? 0.0) * factor;
    final waterContent = ((widget.food['water_content'] as num?)?.toDouble() ?? 0.0) * factor;
    
    // Calculate water amount
    double waterAmount = water;
    if (waterAmount == 0 && waterContent > 0) {
      waterAmount = (_quantity * waterContent / 100.0);
    } else if (waterAmount == 0 && _unit.toLowerCase() == 'ml') {
      waterAmount = _quantity;
    } else if (waterAmount == 0) {
      final foodName = (widget.food['name']?.toString() ?? '').toLowerCase();
      if (foodName.contains('water') || foodName.contains('juice') || 
          foodName.contains('soup') || foodName.contains('tea') || 
          foodName.contains('coffee') || foodName.contains('drink')) {
        waterAmount = _unit.toLowerCase() == 'ml' ? _quantity : _quantity * 0.95;
      } else if (foodName.contains('fruit') || foodName.contains('vegetable')) {
        waterAmount = _quantity * 0.85;
      }
    }
    
    final hasAdditionalInfo = sodium > 0 || cholesterol > 0 || transFat > 0 || 
                              monounsaturated > 0 || polyunsaturated > 0 || 
                              caffeine > 0 || waterAmount > 0;
    
    if (!hasAdditionalInfo) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.additionalInformation,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  if (caffeine > 0) _buildInfoRow('Caffeine', caffeine, 'mg', Icons.coffee, caffeine > 100 ? AppColors.warning : AppColors.primary),
                  if (waterAmount > 0) _buildInfoRow(l10n.waterContent, waterAmount, _unit.toLowerCase() == 'ml' ? 'ml' : 'g', Icons.water_drop, AppColors.primary),
                  if (sodium > 0) _buildInfoRow(l10n.sodium, sodium, 'mg', Icons.water_drop, sodium > 1000 ? AppColors.warning : AppColors.primary),
                  if (cholesterol > 0) _buildInfoRow('Cholesterol', cholesterol, 'mg', Icons.bloodtype, cholesterol > 300 ? AppColors.warning : AppColors.primary),
                  if (transFat > 0) _buildInfoRow(l10n.transFat, transFat, 'g', Icons.warning, AppColors.error),
                  if (monounsaturated > 0) _buildInfoRow(l10n.monounsaturatedFat, monounsaturated, 'g', Icons.opacity, AppColors.success),
                  if (polyunsaturated > 0) _buildInfoRow(l10n.polyunsaturatedFat, polyunsaturated, 'g', Icons.opacity, AppColors.success),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDetailsSection(double factor, AppLocalizations l10n) {
    // List of specialized nutrient fields to check
    final specializedNutrients = [
      {'key': 'creatine', 'name': 'Creatine', 'unit': 'g', 'icon': Icons.fitness_center, 'color': AppColors.primary},
      {'key': 'taurine', 'name': 'Taurine', 'unit': 'g', 'icon': Icons.bolt, 'color': Colors.orange},
      {'key': 'caffeine', 'name': 'Caffeine', 'unit': 'mg', 'icon': Icons.coffee, 'color': Colors.brown},
      {'key': 'beta_alanine', 'name': 'Beta-Alanine', 'unit': 'g', 'icon': Icons.speed, 'color': AppColors.primary},
      {'key': 'l_carnitine', 'name': 'L-Carnitine', 'unit': 'g', 'icon': Icons.local_fire_department, 'color': Colors.red},
      {'key': 'glutamine', 'name': 'Glutamine', 'unit': 'g', 'icon': Icons.healing, 'color': AppColors.success},
      {'key': 'bcaa', 'name': 'BCAA', 'unit': 'g', 'icon': Icons.sports_gymnastics, 'color': AppColors.primary},
      {'key': 'leucine', 'name': 'Leucine', 'unit': 'g', 'icon': Icons.trending_up, 'color': AppColors.primary},
      {'key': 'isoleucine', 'name': 'Isoleucine', 'unit': 'g', 'icon': Icons.trending_up, 'color': AppColors.primary},
      {'key': 'valine', 'name': 'Valine', 'unit': 'g', 'icon': Icons.trending_up, 'color': AppColors.primary},
      {'key': 'lysine', 'name': 'Lysine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'methionine', 'name': 'Methionine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'phenylalanine', 'name': 'Phenylalanine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'threonine', 'name': 'Threonine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'tryptophan', 'name': 'Tryptophan', 'unit': 'g', 'icon': Icons.bedtime, 'color': Colors.purple},
      {'key': 'histidine', 'name': 'Histidine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'arginine', 'name': 'Arginine', 'unit': 'g', 'icon': Icons.favorite, 'color': Colors.red},
      {'key': 'tyrosine', 'name': 'Tyrosine', 'unit': 'g', 'icon': Icons.psychology, 'color': AppColors.primary},
      {'key': 'cysteine', 'name': 'Cysteine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'alanine', 'name': 'Alanine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'aspartic_acid', 'name': 'Aspartic Acid', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'glutamic_acid', 'name': 'Glutamic Acid', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'glycine', 'name': 'Glycine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'proline', 'name': 'Proline', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'serine', 'name': 'Serine', 'unit': 'g', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'theobromine', 'name': 'Theobromine', 'unit': 'mg', 'icon': Icons.cake, 'color': Colors.brown},
      {'key': 'theanine', 'name': 'L-Theanine', 'unit': 'mg', 'icon': Icons.self_improvement, 'color': Colors.green},
      {'key': 'betaine', 'name': 'Betaine', 'unit': 'mg', 'icon': Icons.eco, 'color': AppColors.success},
      {'key': 'choline', 'name': 'Choline', 'unit': 'mg', 'icon': Icons.psychology, 'color': AppColors.primary},
      {'key': 'inositol', 'name': 'Inositol', 'unit': 'mg', 'icon': Icons.auto_awesome, 'color': AppColors.primary},
      {'key': 'carnosine', 'name': 'Carnosine', 'unit': 'mg', 'icon': Icons.fitness_center, 'color': AppColors.primary},
      {'key': 'coenzyme_q10', 'name': 'CoQ10', 'unit': 'mg', 'icon': Icons.bolt, 'color': Colors.orange},
      {'key': 'alpha_lipoic_acid', 'name': 'Alpha-Lipoic Acid', 'unit': 'mg', 'icon': Icons.shield, 'color': AppColors.success},
    ];
    
    // Collect nutrients that have values > 0
    final availableNutrients = <Map<String, dynamic>>[];
    
    for (var nutrient in specializedNutrients) {
      final key = nutrient['key'] as String;
      final value = ((widget.food[key] as num?)?.toDouble() ?? 0.0) * factor;
      
      if (value > 0) {
        availableNutrients.add({
          ...nutrient,
          'value': value,
        });
      }
    }
    
    // Don't show section if no specialized nutrients
    if (availableNutrients.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.extraDetails,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...availableNutrients.map((nutrient) {
            return _buildExtraDetailRow(
              nutrient['name'] as String,
              nutrient['value'] as double,
              nutrient['unit'] as String,
              nutrient['icon'] as IconData,
              nutrient['color'] as Color,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExtraDetailRow(String label, double value, String unit, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${value.toStringAsFixed(unit == 'mg' ? 0 : 2)} $unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, double value, String unit, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNutritionByCategory(double factor) {
    final categories = <String, List<NutrientMeta>>{};
    
    for (var meta in NutritionData.nutrients) {
      final val = ((widget.food[meta.key] as num?)?.toDouble() ?? 0.0) * factor;
      if (val > 0 || ['protein', 'carbs', 'fat'].contains(meta.key)) {
        if (!categories.containsKey(meta.category)) {
          categories[meta.category] = [];
        }
        categories[meta.category]!.add(meta);
      }
    }
    
    final widgets = <Widget>[];
    
    categories.forEach((category, nutrients) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NutritionData.getLocalizedCategory(context, category),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...nutrients.map((meta) {
                final val = ((widget.food[meta.key] as num?)?.toDouble() ?? 0.0) * factor;
                if (val == 0 && !['protein', 'carbs', 'fat'].contains(meta.key)) {
                  return const SizedBox.shrink();
                }
                return _buildNutritionTableRow(meta, val);
              }),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  Widget _buildFoodHistorySection(AppLocalizations l10n) {
    if (_foodHistory == null || _foodHistory!.isEmpty) return const SizedBox.shrink();
    
    final daysSince = _foodHistory!['daysSince'] as int? ?? -1;
    final totalTimes = _foodHistory!['totalTimes'] as int? ?? 0;
    final thisMonth = _foodHistory!['thisMonth'] as int? ?? 0;
    final lastMealType = _foodHistory!['lastMealType'] as String? ?? '';

    String historyText = '';
    if (daysSince == 0) {
      historyText = 'Logged today as $lastMealType';
    } else if (daysSince == 1) {
      historyText = 'Last logged yesterday';
    } else if (daysSince > 1 && daysSince < 30) {
      historyText = 'Last logged $daysSince days ago';
    } else if (daysSince >= 30) {
      historyText = 'Last logged ${(daysSince / 30).toStringAsFixed(0)} months ago';
    } else {
      historyText = 'Never logged before';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.consumptionHistory,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(historyText, style: const TextStyle(fontSize: 14)),
          if (totalTimes > 0) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  children: [
                    Text(l10n.totalTimes(totalTimes), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    if (thisMonth > 0) ...[
                      const SizedBox(width: 16),
                      Text(l10n.thisMonth(thisMonth), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonWithAverage(double factor, AppLocalizations l10n) {
    if (_averageNutrition == null || _averageNutrition!.isEmpty) return const SizedBox.shrink();

    final foodCalories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodProtein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodCarbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final foodFiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;

    final avgCalories = _averageNutrition!['calories'] ?? 0.0;
    final avgProtein = _averageNutrition!['protein'] ?? 0.0;
    final avgCarbs = _averageNutrition!['carbs'] ?? 0.0;
    final avgFiber = _averageNutrition!['fiber'] ?? 0.0;

    final caloriesDiff = avgCalories > 0 ? ((foodCalories - avgCalories) / avgCalories * 100) : 0.0;
    final proteinDiff = avgProtein > 0 ? ((foodProtein - avgProtein) / avgProtein * 100) : 0.0;
    final carbsDiff = avgCarbs > 0 ? ((foodCarbs - avgCarbs) / avgCarbs * 100) : 0.0;
    final fiberDiff = avgFiber > 0 ? ((foodFiber - avgFiber) / avgFiber * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'vs. Similar Foods',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Calories', caloriesDiff, foodCalories, avgCalories, 'kcal'),
          _buildComparisonRow('Protein', proteinDiff, foodProtein, avgProtein, 'g'),
          _buildComparisonRow('Carbs', carbsDiff, foodCarbs, avgCarbs, 'g'),
          if (fiberDiff.abs() > 5) _buildComparisonRow('Fiber', fiberDiff, foodFiber, avgFiber, 'g'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double diff, double current, double average, String unit) {
    final isBetter = label == 'Protein' || label == 'Fiber' ? diff > 0 : diff < 0;
    final color = isBetter ? AppColors.success : AppColors.warning;
    final icon = isBetter ? Icons.trending_up : Icons.trending_down;
    final sign = diff > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${current.toStringAsFixed(0)}$unit',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            'vs ${average.toStringAsFixed(0)}$unit',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                '$sign${diff.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarFoodsSection(AppLocalizations l10n) {
    if (_similarFoods.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.healthierAlternatives,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._similarFoods.take(3).map((food) {
            final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
            final protein = (food['protein'] as num?)?.toDouble() ?? 0.0;
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.viewAlternativeFood),
                    content: Text(
                      AppLocalizations.of(context)!.doYouWantToLeave(
                        food['name']?.toString() ?? 'this food')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close current page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailPage(
                                food: food,
                                mealType: widget.mealType,
                              ),
                            ),
                          );
                        },
                        child: Text(AppLocalizations.of(context)!.viewFood),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${calories.toStringAsFixed(0)} kcal • ${protein.toStringAsFixed(1)}g protein',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimingRecommendations(double factor, AppLocalizations l10n) {
    final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
    final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
    final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
    final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
    final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
    final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
    final caffeine = ((widget.food['caffeine'] as num?)?.toDouble() ?? 0.0) * factor;
    
    final now = DateTime.now();
    final hour = now.hour;
    final goal = _profile?['goal']?.toString() ?? 'MAINTAIN';

    String timing = 'Anytime';
    String reason = '';
    IconData icon = Icons.access_time;
    Color color = AppColors.primary;

    // Caffeine-based timing
    if (caffeine > 50) {
      timing = hour < 14 ? 'Morning' : 'Avoid Afternoon';
      reason = hour < 14 
          ? 'Caffeine is best in the morning for energy'
          : 'High caffeine - may affect sleep if consumed late';
      icon = Icons.coffee;
      color = Colors.brown;
    }
    // Post-workout (high protein + carbs)
    else if (protein > 20 && carbs > 30 && calories > 300) {
      timing = 'Post-Workout';
      reason = 'Perfect recovery meal: high protein and carbs replenish energy';
      icon = Icons.fitness_center;
      color = AppColors.success;
    }
    // High carb breakfast
    else if (carbs > 40 && sugar > 15 && calories < 400) {
      timing = 'Morning';
      reason = 'High carbs provide sustained energy for the day';
      icon = Icons.wb_sunny;
      color = Colors.orange;
    }
    // High protein, low calorie dinner
    else if (protein > 20 && calories < 350 && fat < 15) {
      timing = 'Evening';
      reason = 'High protein, low calories - ideal for dinner';
      icon = Icons.nightlight;
      color = Colors.blue;
    }
    // High fiber snack
    else if (fiber > 5 && calories < 250 && protein > 5) {
      timing = 'Snack Time';
      reason = 'High fiber and protein keep you full between meals';
      icon = Icons.restaurant;
      color = AppColors.primary;
    }
    // High fat - avoid late
    else if (fat > 20 && calories > 400) {
      timing = hour < 18 ? 'Lunch' : 'Avoid Evening';
      reason = hour < 18 
          ? 'High fat content - better digested earlier in the day'
          : 'High fat may cause discomfort if eaten too late';
      icon = Icons.lunch_dining;
      color = AppColors.warning;
    }
    // Low calorie, high volume
    else if (calories < 150 && fiber > 3) {
      timing = 'Anytime';
      reason = 'Low calorie, high fiber - great for any time';
      icon = Icons.check_circle;
      color = AppColors.success;
    }
    // Weight loss specific
    else if (goal == 'LOSE' && calories < 300 && protein > 10) {
      timing = 'Lunch or Dinner';
      reason = 'Perfect for weight loss: filling and nutritious';
      icon = Icons.restaurant_menu;
      color = AppColors.success;
    }
    // Weight gain specific
    else if (goal == 'GAIN' && calories > 400 && protein > 15) {
      timing = 'Post-Workout or Main Meal';
      reason = 'High calories and protein support muscle gain';
      icon = Icons.trending_up;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(25), color.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Best Time to Eat',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            timing,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(AppLocalizations l10n) {
    final ingredients = widget.food['ingredients']?.toString() ?? '';
    if (ingredients.isEmpty) return const SizedBox.shrink();

    // Check processing level based on ingredients
    final processedKeywords = ['preservative', 'artificial', 'additive', 'hydrogenated', 'modified', 'starch', 'syrup'];
    final isProcessed = processedKeywords.any((keyword) => ingredients.toLowerCase().contains(keyword));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isProcessed ? Icons.warning_amber : Icons.check_circle,
                color: isProcessed ? AppColors.warning : AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Ingredients',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ingredients,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          if (isProcessed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contains processed ingredients',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPandaAdvice(double factor, AppLocalizations l10n) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/panda.png',
                  height: 60,
                  width: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.pandaAIAdvice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isLoadingAdvice)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_pandaAdvice != null)
                        GestureDetector(
                          onTap: () {
                            // Show full advice in scrollable dialog
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(25),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/panda.png',
                                              height: 40,
                                              width: 40,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Panda AI Advice',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                            _pandaAdvice!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Close',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            _pandaAdvice!.length > 100 
                                ? '${_pandaAdvice!.substring(0, 100)}... Tap to read more'
                                : _pandaAdvice!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _generatePandaAdvice,
                          child: Text(
                            'Tap to get personalized advice about this food',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePandaAdvice() async {
    if (_isLoadingAdvice) return;

    setState(() {
      _isLoadingAdvice = true;
      _pandaAdvice = null;
    });

    try {
      final factor = _quantity / 100.0;
      final foodName = widget.food['name']?.toString() ?? 'this food';
      final calories = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0) * factor;
      final protein = ((widget.food['protein'] as num?)?.toDouble() ?? 0.0) * factor;
      final carbs = ((widget.food['carbs'] as num?)?.toDouble() ?? 0.0) * factor;
      final fat = ((widget.food['fat'] as num?)?.toDouble() ?? 0.0) * factor;
      final fiber = ((widget.food['fiber'] as num?)?.toDouble() ?? 0.0) * factor;
      final sugar = ((widget.food['sugar'] as num?)?.toDouble() ?? 0.0) * factor;
      final saturatedFat = ((widget.food['saturated_fat'] as num?)?.toDouble() ?? 0.0) * factor;
      final sodium = ((widget.food['sodium'] as num?)?.toDouble() ?? 0.0) * factor;

      final goal = _profile?['goal']?.toString() ?? 'MAINTAIN';
      final calorieTarget = ((_profile?['daily_calorie_target'] as num?)?.toInt() ?? 2000);
      final remainingCalories = calorieTarget - (_todayTotals['calories'] ?? 0.0);

      final systemInstruction = '''You are Panda, a friendly nutrition AI coach. 
You give short, practical advice in plain text only. 
NO markdown, NO asterisks, NO bold, NO formatting symbols.
Write like you're texting a friend - simple, direct, friendly.
Maximum 80 words. Be specific and actionable.''';

      // Example response format
      final exampleResponse = goal == 'LOSE' 
          ? 'This is a good choice for weight loss. With ${calories.toStringAsFixed(0)} calories, it fits well in your daily budget. The ${protein.toStringAsFixed(1)}g of protein will help keep you full. Just watch the portion size to stay on track.'
          : goal == 'GAIN'
              ? 'Great for weight gain. This provides ${calories.toStringAsFixed(0)} calories and ${protein.toStringAsFixed(1)}g of protein, which supports muscle growth. Consider pairing it with other calorie-dense foods to maximize your intake.'
              : 'This is a balanced choice. At ${calories.toStringAsFixed(0)} calories, it fits well in your maintenance plan. The ${protein.toStringAsFixed(1)}g protein and ${fiber.toStringAsFixed(1)}g fiber provide good nutrition without excess calories.';

      final prompt = '''You are analyzing a food for a user. Give advice in this EXACT format:

EXAMPLE OF GOOD RESPONSE:
"This is a good choice for weight loss. With 250 calories, it fits well in your daily budget. The 20g of protein will help keep you full. Just watch the portion size to stay on track."

RULES:
- Write in plain text only, no symbols like asterisks or stars
- Maximum 80 words
- Be specific with numbers from the data
- Give one clear recommendation
- Write naturally like talking to a friend
- Start directly with your assessment

FOOD DATA:
Food: $foodName
Portion: ${_quantity.toStringAsFixed(0)}${_unit}
Calories: ${calories.toStringAsFixed(0)} kcal
Protein: ${protein.toStringAsFixed(1)}g
Carbs: ${carbs.toStringAsFixed(1)}g
Fat: ${fat.toStringAsFixed(1)}g
Fiber: ${fiber.toStringAsFixed(1)}g
Sugar: ${sugar.toStringAsFixed(1)}g
Saturated Fat: ${saturatedFat.toStringAsFixed(1)}g
Sodium: ${sodium.toStringAsFixed(0)}mg

USER INFO:
Goal: $goal
Daily target: $calorieTarget kcal
Consumed today: ${(_todayTotals['calories'] ?? 0.0).toStringAsFixed(0)} kcal
Remaining: ${remainingCalories.toStringAsFixed(0)} kcal

Now give your advice following the example format above. Write only plain text, no formatting.''';

      final advice = await _replicateService.generateAdvice(
        prompt: prompt,
        systemInstruction: systemInstruction,
        temperature: 0.8,
        maxOutputTokens: 800, // Increased for complete responses
        dynamicThinking: false,
      );

      // Clean up any markdown or formatting that might slip through
      String cleanedAdvice = advice.trim();
      
      print('Raw advice length: ${cleanedAdvice.length}');
      
      // Remove all markdown formatting
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
      cleanedAdvice = cleanedAdvice.replaceAll('**', '');
      cleanedAdvice = cleanedAdvice.replaceAll('*', '');
      cleanedAdvice = cleanedAdvice.replaceAll('__', '');
      cleanedAdvice = cleanedAdvice.replaceAll('_', '');
      
      // Remove any quotes that might wrap the response
      if (cleanedAdvice.startsWith('"') && cleanedAdvice.endsWith('"')) {
        cleanedAdvice = cleanedAdvice.substring(1, cleanedAdvice.length - 1);
      }
      if (cleanedAdvice.startsWith("'") && cleanedAdvice.endsWith("'")) {
        cleanedAdvice = cleanedAdvice.substring(1, cleanedAdvice.length - 1);
      }
      
      // Clean up multiple spaces but preserve newlines for readability
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'[ \t]+'), ' ');
      cleanedAdvice = cleanedAdvice.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Max 2 newlines
      cleanedAdvice = cleanedAdvice.trim();
      
      print('Cleaned advice length: ${cleanedAdvice.length}');
      
      // DO NOT truncate - show full response in dialog

      if (mounted) {
        setState(() {
          _pandaAdvice = cleanedAdvice;
          _isLoadingAdvice = false;
        });
      }
    } catch (e) {
      print('Error generating panda advice: $e');
      if (mounted) {
        setState(() {
          _pandaAdvice = 'Sorry, I couldn\'t generate advice right now. Please try again later.';
          _isLoadingAdvice = false;
        });
      }
    }
  }

  Widget _buildPortionRecommendation(double factor, AppLocalizations l10n) {
    final goal = _profile?['goal']?.toString() ?? 'MAINTAIN';
    final calorieTarget = ((_profile?['daily_calorie_target'] as num?)?.toInt() ?? 2000);
    final remainingCalories = calorieTarget - (_todayTotals['calories'] ?? 0.0);
    final foodCaloriesPer100 = ((widget.food['calories'] as num?)?.toDouble() ?? 0.0);

    if (foodCaloriesPer100 == 0) return const SizedBox.shrink();

    double recommendedPortion = 100.0;
    String recommendation = '';

    if (goal == 'LOSE') {
      // Recommend portion that fits within remaining calories, max 400 cal
      final maxCalories = remainingCalories < 400 ? remainingCalories : 400.0;
      recommendedPortion = (maxCalories / foodCaloriesPer100 * 100).clamp(50.0, 300.0);
      recommendation = 'Recommended: ${recommendedPortion.toStringAsFixed(0)}${_unit} for weight loss';
    } else if (goal == 'GAIN') {
      // Recommend larger portion if there's room
      final targetCalories = remainingCalories > 0 ? remainingCalories : 500.0;
      recommendedPortion = (targetCalories / foodCaloriesPer100 * 100).clamp(150.0, 500.0);
      recommendation = 'Recommended: ${recommendedPortion.toStringAsFixed(0)}${_unit} for weight gain';
    } else {
      // Maintain - recommend portion that fits remaining calories
      if (remainingCalories > 0) {
        recommendedPortion = (remainingCalories / foodCaloriesPer100 * 100).clamp(100.0, 400.0);
        recommendation = 'Recommended: ${recommendedPortion.toStringAsFixed(0)}${_unit} to meet your daily target';
      }
    }

    if (recommendation.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _quantity = recommendedPortion;
                _quantityController.text = recommendedPortion.toStringAsFixed(recommendedPortion == recommendedPortion.toInt() ? 0 : 1);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
