import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'dart:ui';
import 'dart:convert';

class RecipeDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final SupabaseService supabaseService;

  const RecipeDetailsSheet({
    super.key,
    required this.recipe,
    required this.supabaseService,
  });

  @override
  State<RecipeDetailsSheet> createState() => _RecipeDetailsSheetState();
}

class _RecipeDetailsSheetState extends State<RecipeDetailsSheet> {
  String? _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = _getMealTypeForCurrentTime();
  }

  String _getMealTypeForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'BREAKFAST';
    } else if (hour >= 11 && hour < 15) {
      return 'LUNCH';
    } else if (hour >= 15 && hour < 21) {
      return 'DINNER';
    } else {
      return 'SNACK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final title = recipe['title_en'] as String? ?? 'Untitled Recipe';
    final description = recipe['description_en'] as String? ?? '';
    final imageUrl = recipe['image_url'] as String?;
    final calories = (recipe['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (recipe['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (recipe['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (recipe['fat'] as num?)?.toDouble() ?? 0.0;
    final prepTime = recipe['prep_time_minutes'] as int? ?? 0;
    final cookTime = recipe['cook_time_minutes'] as int? ?? 0;
    final servings = recipe['servings'] as int? ?? 1;
    final cuisine = recipe['cuisine_type'] as String?;
    final dietType = recipe['diet_type'] as String?;
    
    // Parse ingredients and instructions (they might be JSON strings or already parsed)
    List<dynamic> ingredients = [];
    List<dynamic> instructionsEn = [];
    
    try {
      final ingredientsData = recipe['ingredients'];
      if (ingredientsData is String) {
        ingredients = (jsonDecode(ingredientsData) as List<dynamic>?) ?? [];
      } else if (ingredientsData is List) {
        ingredients = ingredientsData;
      }
      
      final instructionsData = recipe['instructions_en'];
      if (instructionsData is String) {
        instructionsEn = (jsonDecode(instructionsData) as List<dynamic>?) ?? [];
      } else if (instructionsData is List) {
        instructionsEn = instructionsData;
      }
    } catch (e) {
      print('[ERROR] Error parsing ingredients/instructions: $e');
    }
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Hero(
                          tag: 'recipe_${recipe['id']}',
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(Icons.restaurant_menu, size: 64),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Title and actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (cuisine != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cuisine,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Share button
                          IconButton(
                            icon: const Icon(Icons.share, color: AppColors.primary),
                            onPressed: () => _shareRecipe(),
                          ),
                        ],
                      ),
                      
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.local_fire_department,
                              'Calories',
                              '${calories.toInt()}',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.access_time,
                              'Prep',
                              '$prepTime min',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.people,
                              'Serves',
                              '$servings',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Macros
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMacroItem('Protein', '${protein.toStringAsFixed(1)}g', Colors.blue),
                            _buildMacroItem('Carbs', '${carbs.toStringAsFixed(1)}g', Colors.orange),
                            _buildMacroItem('Fat', '${fat.toStringAsFixed(1)}g', Colors.purple),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Comprehensive Nutritional Information
                      _buildNutritionalInfo(recipe),
                      
                      const SizedBox(height: 32),
                      
                      // Ingredients
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...ingredients.asMap().entries.map((entry) {
                        final ingredient = entry.value as Map<String, dynamic>;
                        return FadeInLeft(
                          duration: Duration(milliseconds: 200 + (entry.key * 50)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${ingredient['name_en'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${ingredient['amount'] ?? ''} ${ingredient['unit'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 32),
                      
                      // Instructions
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...instructionsEn.asMap().entries.map((entry) {
                        return FadeInRight(
                          duration: Duration(milliseconds: 200 + (entry.key * 50)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  width: 4,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              // Bottom action bar - compact design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Meal type dropdown - compact
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMealType,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'BREAKFAST',
                                  child: Row(
                                    children: [
                                      Icon(Icons.wb_sunny, size: 18, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.breakfast),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'LUNCH',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lunch_dining, size: 18, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.lunch),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'DINNER',
                                  child: Row(
                                    children: [
                                      Icon(Icons.dinner_dining, size: 18, color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.dinner),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'SNACK',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cookie, size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.snack),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedMealType = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add as Meal button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedMealType != null
                              ? () => _addAsMeal()
                              : null,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            'Add as Meal',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _shareRecipe() {
    final title = widget.recipe['title_en'] as String? ?? 'Recipe';
    final description = widget.recipe['description_en'] as String? ?? '';
    Share.share('Check out this recipe: $title\n\n$description');
  }

  Widget _buildNutritionalInfo(Map<String, dynamic> recipe) {
    final servings = recipe['servings'] as int? ?? 1;
    
    // Helper to get nutrient value
    double getNutrient(String key) {
      return ((recipe[key] as num?)?.toDouble() ?? 0.0);
    }
    
    // Helper to format value
    String formatValue(double value, String unit) {
      if (value == 0.0) return '-';
      if (value < 0.01) return '<0.01 $unit';
      if (value < 1.0) return '${value.toStringAsFixed(2)} $unit';
      return '${value.toStringAsFixed(1)} $unit';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.completeNutritionalInformation,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Per serving (${servings} serving${servings > 1 ? 's' : ''} total)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Macronutrients
          _buildNutrientSection(
            'Macronutrients',
            [
              _buildNutrientRow('Calories', formatValue(getNutrient('calories'), 'kcal')),
              _buildNutrientRow('Protein', formatValue(getNutrient('protein'), 'g')),
              _buildNutrientRow('Carbohydrates', formatValue(getNutrient('carbs'), 'g')),
              _buildNutrientRow('Fat', formatValue(getNutrient('fat'), 'g')),
              _buildNutrientRow('Fiber', formatValue(getNutrient('fiber'), 'g')),
              _buildNutrientRow('Sugar', formatValue(getNutrient('sugar'), 'g')),
              _buildNutrientRow('Saturated Fat', formatValue(getNutrient('saturated_fat'), 'g')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Essential Fats
          _buildNutrientSection(
            'Essential Fats',
            [
              _buildNutrientRow('Omega-3', formatValue(getNutrient('omega3'), 'g')),
              _buildNutrientRow('Omega-6', formatValue(getNutrient('omega6'), 'g')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Vitamins
          _buildNutrientSection(
            'Vitamins',
            [
              _buildNutrientRow('Vitamin A', formatValue(getNutrient('vitamin_a'), 'μg')),
              _buildNutrientRow('Vitamin C', formatValue(getNutrient('vitamin_c'), 'mg')),
              _buildNutrientRow('Vitamin D', formatValue(getNutrient('vitamin_d'), 'μg')),
              _buildNutrientRow('Vitamin E', formatValue(getNutrient('vitamin_e'), 'mg')),
              _buildNutrientRow('Vitamin K', formatValue(getNutrient('vitamin_k'), 'μg')),
              _buildNutrientRow('Vitamin B1 (Thiamine)', formatValue(getNutrient('vitamin_b1_thiamine'), 'mg')),
              _buildNutrientRow('Vitamin B2 (Riboflavin)', formatValue(getNutrient('vitamin_b2_riboflavin'), 'mg')),
              _buildNutrientRow('Vitamin B3 (Niacin)', formatValue(getNutrient('vitamin_b3_niacin'), 'mg')),
              _buildNutrientRow('Vitamin B5 (Pantothenic Acid)', formatValue(getNutrient('vitamin_b5_pantothenic_acid'), 'mg')),
              _buildNutrientRow('Vitamin B6', formatValue(getNutrient('vitamin_b6'), 'mg')),
              _buildNutrientRow('Vitamin B7 (Biotin)', formatValue(getNutrient('vitamin_b7_biotin'), 'μg')),
              _buildNutrientRow('Vitamin B9 (Folate)', formatValue(getNutrient('vitamin_b9_folate'), 'μg')),
              _buildNutrientRow('Vitamin B12', formatValue(getNutrient('vitamin_b12'), 'μg')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Minerals
          _buildNutrientSection(
            'Minerals',
            [
              _buildNutrientRow('Calcium', formatValue(getNutrient('calcium'), 'mg')),
              _buildNutrientRow('Iron', formatValue(getNutrient('iron'), 'mg')),
              _buildNutrientRow('Magnesium', formatValue(getNutrient('magnesium'), 'mg')),
              _buildNutrientRow('Phosphorus', formatValue(getNutrient('phosphorus'), 'mg')),
              _buildNutrientRow('Potassium', formatValue(getNutrient('potassium'), 'mg')),
              _buildNutrientRow('Sodium', formatValue(getNutrient('sodium'), 'mg')),
              _buildNutrientRow('Zinc', formatValue(getNutrient('zinc'), 'mg')),
              _buildNutrientRow('Copper', formatValue(getNutrient('copper'), 'mg')),
              _buildNutrientRow('Manganese', formatValue(getNutrient('manganese'), 'mg')),
              _buildNutrientRow('Selenium', formatValue(getNutrient('selenium'), 'μg')),
              _buildNutrientRow('Chromium', formatValue(getNutrient('chromium'), 'μg')),
              _buildNutrientRow('Molybdenum', formatValue(getNutrient('molybdenum'), 'μg')),
              _buildNutrientRow('Iodine', formatValue(getNutrient('iodine'), 'μg')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Other Nutrients
          _buildNutrientSection(
            'Other Nutrients',
            [
              _buildNutrientRow('Water', formatValue(getNutrient('water'), 'g')),
              _buildNutrientRow('Caffeine', formatValue(getNutrient('caffeine'), 'mg')),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Specialized Nutrients
          if (getNutrient('creatine') > 0 || getNutrient('taurine') > 0 || getNutrient('beta_alanine') > 0 ||
              getNutrient('l_carnitine') > 0 || getNutrient('glutamine') > 0 || getNutrient('bcaa') > 0)
            _buildNutrientSection(
              'Specialized Nutrients',
              [
                if (getNutrient('creatine') > 0) _buildNutrientRow('Creatine', formatValue(getNutrient('creatine'), 'g')),
                if (getNutrient('taurine') > 0) _buildNutrientRow('Taurine', formatValue(getNutrient('taurine'), 'g')),
                if (getNutrient('beta_alanine') > 0) _buildNutrientRow('Beta-Alanine', formatValue(getNutrient('beta_alanine'), 'g')),
                if (getNutrient('l_carnitine') > 0) _buildNutrientRow('L-Carnitine', formatValue(getNutrient('l_carnitine'), 'g')),
                if (getNutrient('glutamine') > 0) _buildNutrientRow('Glutamine', formatValue(getNutrient('glutamine'), 'g')),
                if (getNutrient('bcaa') > 0) _buildNutrientRow('BCAA', formatValue(getNutrient('bcaa'), 'g')),
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Amino Acids
          _buildNutrientSection(
            'Amino Acids',
            [
              _buildNutrientRow('Leucine', formatValue(getNutrient('leucine'), 'g')),
              _buildNutrientRow('Isoleucine', formatValue(getNutrient('isoleucine'), 'g')),
              _buildNutrientRow('Valine', formatValue(getNutrient('valine'), 'g')),
              _buildNutrientRow('Lysine', formatValue(getNutrient('lysine'), 'g')),
              _buildNutrientRow('Methionine', formatValue(getNutrient('methionine'), 'g')),
              _buildNutrientRow('Phenylalanine', formatValue(getNutrient('phenylalanine'), 'g')),
              _buildNutrientRow('Threonine', formatValue(getNutrient('threonine'), 'g')),
              _buildNutrientRow('Tryptophan', formatValue(getNutrient('tryptophan'), 'g')),
              _buildNutrientRow('Histidine', formatValue(getNutrient('histidine'), 'g')),
              _buildNutrientRow('Arginine', formatValue(getNutrient('arginine'), 'g')),
              _buildNutrientRow('Tyrosine', formatValue(getNutrient('tyrosine'), 'g')),
              _buildNutrientRow('Cysteine', formatValue(getNutrient('cysteine'), 'g')),
              _buildNutrientRow('Alanine', formatValue(getNutrient('alanine'), 'g')),
              _buildNutrientRow('Aspartic Acid', formatValue(getNutrient('aspartic_acid'), 'g')),
              _buildNutrientRow('Glutamic Acid', formatValue(getNutrient('glutamic_acid'), 'g')),
              _buildNutrientRow('Serine', formatValue(getNutrient('serine'), 'g')),
              _buildNutrientRow('Proline', formatValue(getNutrient('proline'), 'g')),
              _buildNutrientRow('Glycine', formatValue(getNutrient('glycine'), 'g')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientSection(String title, List<Widget> nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...nutrients,
      ],
    );
  }
  
  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _addAsMeal() async {
    if (_selectedMealType == null) return;

    try {
      await widget.supabaseService.logRecipeAsMeal(
        recipeId: widget.recipe['id'] as String,
        mealType: _selectedMealType!,
        quantity: (widget.recipe['servings'] as num?)?.toDouble() ?? 1.0,
        unit: 'serving',
      );

      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recipeAddedAsMeal(_selectedMealType ?? '')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

