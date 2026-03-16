import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/features/meal_tracking/pages/food_detail_page.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'dart:io';

class FoodRecognitionResultPage extends StatefulWidget {
  final File imageFile;
  final String mealType;
  final List<Map<String, dynamic>>? recognizedFoods; // If passed, use these; otherwise recognize

  const FoodRecognitionResultPage({
    super.key,
    required this.imageFile,
    required this.mealType,
    this.recognizedFoods,
  });

  @override
  State<FoodRecognitionResultPage> createState() => _FoodRecognitionResultPageState();
}

class _FoodRecognitionResultPageState extends State<FoodRecognitionResultPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final ReplicateService _replicateService = ReplicateService();
  
  List<Map<String, dynamic>> _recognizedFoods = [];
  bool _isRecognizing = false;
  bool _isProcessing = false;
  String? _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType;
    
    // If foods are already recognized, use them; otherwise recognize now
    if (widget.recognizedFoods != null && widget.recognizedFoods!.isNotEmpty) {
      _recognizedFoods = List.from(widget.recognizedFoods!);
    } else {
      _recognizeFood();
    }
  }

  Future<void> _recognizeFood() async {
    setState(() => _isRecognizing = true);
    
    try {
      // Detect system language
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'de' ? 'de' : 'en';
      
      final foodsList = await _replicateService.recognizeFoodFromImage(
        widget.imageFile,
        language: language,
      );
      
      // foodsList is already a List
      setState(() {
        _recognizedFoods = foodsList;
        _isRecognizing = false;
      });
    } catch (e) {
      debugPrint('Error recognizing food: $e');
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _retakePhoto() async {
    Navigator.pop(context);
  }

  Future<void> _addFood(Map<String, dynamic> foodData, {bool fastAdd = false}) async {
    if (_selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectMealType)),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Save custom food
      final foodId = await _supabaseService.saveCustomFood(
        name: foodData['name'] as String,
        germanName: foodData['german_name'] as String?,
        calories: foodData['calories'] as double,
        protein: foodData['protein'] as double,
        carbs: foodData['carbs'] as double,
        fat: foodData['fat'] as double,
        fiber: foodData['fiber'] as double?,
        sugar: foodData['sugar'] as double?,
        sodium: foodData['sodium'] as double?,
        water: foodData['water'] as double?,
        caffeine: foodData['caffeine'] as double?,
        source: 'camera',
      );

      // Get saved food
      final savedFood = await _supabaseService.getCustomFood(foodId);
      
      if (savedFood == null) {
        throw Exception('Failed to save recognized food');
      }

      if (fastAdd) {
        // Fast add: use estimated weight and add directly
        final estimatedWeight = (foodData['estimated_weight'] as num?)?.toDouble() ?? 100.0;
        final unit = foodData['unit'] as String? ?? 'g';
        final factor = estimatedWeight / 100.0;

        await _supabaseService.logMeal(
          foodId: foodId,
          quantity: estimatedWeight,
          unit: unit,
          mealType: _selectedMealType!,
          calories: ((savedFood['calories'] as num?)?.toDouble() ?? 0.0) * factor,
          protein: ((savedFood['protein'] as num?)?.toDouble() ?? 0.0) * factor,
          carbs: ((savedFood['carbs'] as num?)?.toDouble() ?? 0.0) * factor,
          fat: ((savedFood['fat'] as num?)?.toDouble() ?? 0.0) * factor,
          foodData: savedFood,
          isCustomFood: true,
        );

        // Remove from list
        setState(() {
          _recognizedFoods.remove(foodData);
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.foodAddedTo(
                  foodData['name']?.toString() ?? 'Food',
                  _selectedMealType ?? '')),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // If no more foods, go back
        if (_recognizedFoods.isEmpty) {
          Navigator.pop(context);
        }
      } else {
        // Regular add: go to food details
        if (mounted) {
          setState(() => _isProcessing = false);
          
          // Get estimated weight and unit from recognition
          final estimatedWeight = (foodData['estimated_weight'] as num?)?.toDouble();
          final estimatedUnit = foodData['unit'] as String?;
          
          // Navigate to food details with pre-filled quantity
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetailPage(
                food: savedFood,
                mealType: _selectedMealType!,
                initialQuantity: estimatedWeight,
                initialUnit: estimatedUnit,
              ),
            ),
          );

          // Only remove from list if meal was successfully logged (result == true)
          if (mounted && result == true) {
            setState(() {
              _recognizedFoods.remove(foodData);
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.foodAddedTo(
                    foodData['name']?.toString() ?? 'Food',
                    _selectedMealType ?? '')),
                duration: const Duration(seconds: 1),
              ),
            );
            
            // If no more foods, go back to previous page
            if (_recognizedFoods.isEmpty) {
              Navigator.pop(context);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding food: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recognizedFoods),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Image preview (only if image file exists)
            if (widget.imageFile.path.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Retake button (only if image file exists)
            if (widget.imageFile.path.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.of(context)!.retakePhoto),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Meal type selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectMealType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMealTypeChip('BREAKFAST', AppLocalizations.of(context)!.breakfast),
                        const SizedBox(width: 8),
                        _buildMealTypeChip('LUNCH', AppLocalizations.of(context)!.lunch),
                        const SizedBox(width: 8),
                        _buildMealTypeChip('DINNER', AppLocalizations.of(context)!.dinner),
                        const SizedBox(width: 8),
                        _buildMealTypeChip('SNACK', AppLocalizations.of(context)!.snack),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recognized foods list
            Expanded(
              child: _isRecognizing
                  ? const Center(child: CircularProgressIndicator())
                  : _recognizedFoods.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noFoodsRecognized,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recognizedFoods.length,
                          itemBuilder: (context, index) {
                            final food = _recognizedFoods[index];
                            return _buildFoodCard(food, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeChip(String value, String label) {
    final isSelected = _selectedMealType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food, int index) {
    final name = food['name']?.toString() ?? 'Unknown Food';
    final calories = (food['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (food['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (food['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (food['fat'] as num?)?.toDouble() ?? 0.0;
    final estimatedWeight = (food['estimated_weight'] as num?)?.toDouble() ?? 100.0;
    final unit = food['unit']?.toString() ?? 'g';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Nutrition info
          Row(
            children: [
              _buildNutritionBadge('Cal', '${calories.toStringAsFixed(0)}', Colors.orange),
              const SizedBox(width: 8),
              _buildNutritionBadge('P', '${protein.toStringAsFixed(1)}g', Colors.blue),
              const SizedBox(width: 8),
              _buildNutritionBadge('C', '${carbs.toStringAsFixed(1)}g', Colors.green),
              const SizedBox(width: 8),
              _buildNutritionBadge('F', '${fat.toStringAsFixed(1)}g', Colors.red),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            'Estimated: ${estimatedWeight.toStringAsFixed(0)}$unit',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _addFood(food, fastAdd: false),
                  child: Text(AppLocalizations.of(context)!.addEdit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _addFood(food, fastAdd: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(AppLocalizations.of(context)!.fastAdd),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

