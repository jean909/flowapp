import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/meal_tracking/pages/food_search_page.dart';
import 'package:flow/features/recipes/pages/create_recipe_page.dart';
import 'package:flow/features/dashboard/pages/daily_journal_dialog.dart';
import 'package:flow/features/workout/pages/exercise_search_page.dart';
import 'package:flow/features/diets_programs/pages/diets_and_programs_page.dart';
import 'package:flow/services/supabase_service.dart';
import 'dart:ui';

class AddOptionsModal extends StatelessWidget {
  final VoidCallback? onAddWater;
  final Function(String)? onAddFood;

  const AddOptionsModal({
    super.key,
    this.onAddWater,
    this.onAddFood,
  });

  Map<String, String> _getSmartMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return {'label': 'Breakfast', 'type': 'BREAKFAST', 'icon': 'wb_sunny_rounded'};
    if (hour >= 11 && hour < 17) return {'label': 'Lunch', 'type': 'LUNCH', 'icon': 'restaurant'};
    if (hour >= 17 && hour < 22) return {'label': 'Dinner', 'type': 'DINNER', 'icon': 'dinner_dining'};
    return {'label': 'Snack', 'type': 'SNACK', 'icon': 'icecream'};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final smartMeal = _getSmartMealType();
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Top buttons row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton(
                        context: context,
                        icon: Icons.local_drink,
                        label: l10n.addWater,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          if (onAddWater != null) {
                            onAddWater!();
                          } else {
                            // Fallback: show water dialog if no callback provided
                            _showWaterDialog(context);
                          }
                        },
                      ),
                      _buildOptionButton(
                        context: context,
                        icon: _getMealIcon(smartMeal['icon']!),
                        label: smartMeal['label']!,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          if (onAddFood != null) {
                            onAddFood!(smartMeal['type']!);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodSearchPage(mealType: smartMeal['type']!),
                              ),
                            );
                          }
                        },
                      ),
                      _buildOptionButton(
                        context: context,
                        icon: Icons.restaurant_menu,
                        label: l10n.createRecipe,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateRecipePage(),
                            ),
                          );
                        },
                      ),
                      _buildOptionButton(
                        context: context,
                        icon: Icons.fitness_center,
                        label: l10n.addWorkout,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExerciseSearchPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Second row - Diets and Programs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
                  child: _buildOptionButton(
                    context: context,
                    icon: Icons.restaurant_menu,
                    label: l10n.dietsAndPrograms,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DietsAndProgramsPage(),
                        ),
                      );
                    },
                  ),
                ),
                // Center bottom button - Daily Journal
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl, top: AppSpacing.lg),
                  child: _buildOptionButton(
                    context: context,
                    icon: Icons.book_outlined,
                    label: l10n.dailyJournal,
                    color: AppColors.primary,
                    size: 80,
                    isLarge: true,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const DailyJournalDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String iconName) {
    switch (iconName) {
      case 'wb_sunny_rounded':
        return Icons.wb_sunny_rounded;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'icecream':
        return Icons.icecream;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: isLarge ? 32 : 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
              fontSize: isLarge ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showWaterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final supabaseService = SupabaseService();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addWater, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterOption(context, 250, l10n.glass, Icons.local_drink, supabaseService),
                _buildWaterOption(context, 500, l10n.bottle, Icons.local_drink_outlined, supabaseService),
                _buildWaterOption(context, 750, l10n.large, Icons.water_drop, supabaseService),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.enterAmount, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: l10n.ml,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (val) {
                  final amount = int.tryParse(val);
                  if (amount != null && amount > 0) {
                    supabaseService.logWater(amount).then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.waterLogged(l10n.addWater))),
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterOption(BuildContext context, int amount, String label, IconData icon, SupabaseService service) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        service.logWater(amount).then((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.waterLogged(l10n.addWater))),
          );
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 32),
          ),
          const SizedBox(height: 8),
          Text('${amount}ml', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

