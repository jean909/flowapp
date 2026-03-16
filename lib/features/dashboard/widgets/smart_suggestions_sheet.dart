import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/l10n/app_localizations.dart';

class SmartSuggestionsSheet extends StatefulWidget {
  final Map<String, double> currentNutrients;
  final VoidCallback onAddFood;

  const SmartSuggestionsSheet({
    super.key,
    required this.currentNutrients,
    required this.onAddFood,
  });

  @override
  State<SmartSuggestionsSheet> createState() => _SmartSuggestionsSheetState();
}

class _SmartSuggestionsSheetState extends State<SmartSuggestionsSheet> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  String _targetNutrient = '';
  List<Map<String, dynamic>> _suggestions = [];
  String _coachMessage = '';

  @override
  void initState() {
    super.initState();
    _analyzeAndSuggest();
  }

  Future<void> _analyzeAndSuggest() async {
    setState(() => _isLoading = true);

    // 1. Identify biggest gap
    String biggestGapNutrient = 'protein';
    double maxDeficitPercent = 0.0;

    // Check Macros first
    // Simplify: Assume generic targets if not passed. 
    // Ideally we pass targets too, but let's assume Protein is king for now.
    // Let's check Micros too!
    
    final rda = NutritionUtils.microNutrientRDA;
    for (var entry in rda.entries) {
      final current = widget.currentNutrients[entry.key] ?? 0.0;
      final deficit = (entry.value - current) / entry.value;
      if (deficit > maxDeficitPercent && deficit > 0.3) { // Only if >30% gap
        maxDeficitPercent = deficit;
        biggestGapNutrient = entry.key;
      }
    }

    // Heuristic: If protein is low, prioritize it over vitamin C
    final currentProtein = widget.currentNutrients['protein'] ?? 0;
    if (currentProtein < 50) { // Arbitrary low threshold for demo
        biggestGapNutrient = 'protein';
    }

    _targetNutrient = biggestGapNutrient;
    _coachMessage = 'I noticed you\'re running low on ${_formatName(_targetNutrient)}. Here are some smart picks to boost it without high sugar!';

    // 2. Fetch suggestions
    try {
      // Threshold depends on nutrient. 
      double minAmount = 5;
      if (_targetNutrient == 'protein') minAmount = 10;
      if (_targetNutrient == 'iron') minAmount = 2;
      if (_targetNutrient == 'vitamin_c') minAmount = 20;

      final results = await _supabaseService.getSmartFoodSuggestions(
        targetNutrient: _targetNutrient,
        minAmount: minAmount,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coachMessage = 'Couldn\'t load suggestions right now.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatName(String key) {
    return key.replaceAll('_', ' ').capitalize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                AppLocalizations.of(context)!.flowSmartChef,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _coachMessage,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_suggestions.isEmpty)
            Text(AppLocalizations.of(context)!.noPerfectMatches)
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final food = _suggestions[index];
                  return _buildFoodCard(food);
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(AppLocalizations.of(context)!.gotIt),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    final nutrientVal = (food[_targetNutrient] as num?)?.toDouble() ?? 0;
    
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🍎', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 8),
          Text(
            food['name'] ?? 'Unknown',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '${nutrientVal.toStringAsFixed(1)} ${_getUnit(_targetNutrient)}',
             style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const Text(
            'per 100g',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getUnit(String nutrient) {
    if (nutrient == 'protein') return 'g';
    if (nutrient == 'calories') return 'kcal';
    return 'mg'; // Most micros
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
