import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/utils/nutrition_data.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class NutritionDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialLogs;
  final DateTime? initialDate;
  const NutritionDetailsPage({
    super.key,
    this.initialLogs,
    this.initialDate,
  });
  @override
  State<NutritionDetailsPage> createState() => _NutritionDetailsPageState();
}

class _NutritionDetailsPageState extends State<NutritionDetailsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, double> _totals = {};
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  Map<String, int> _consecutiveDaysMissing = {}; // Track consecutive days missing
  List<Map<String, dynamic>> _warnings = [];
  List<Map<String, dynamic>> _criticalAlerts = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _logs = widget.initialLogs ?? [];
    if (_logs.isEmpty) {
      _loadLogsForDate(_selectedDate);
    } else {
      _calculateTotals();
    }
  }

  Future<void> _loadLogsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final logs = await _supabaseService.getDailyMealLogs(date);
      final waterLogs = await _supabaseService.getDailyWaterLogs(date);
      
      // Calculate total water from manual logs (in ml, convert to g for consistency)
      double manualWater = 0.0;
      for (var waterLog in waterLogs) {
        manualWater += (waterLog['amount_ml'] as num?)?.toDouble() ?? 0.0;
      }
      
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
      _calculateTotals(manualWater: manualWater);
      _checkWarnings();
      _checkConsecutiveDays(date);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _checkWarnings() {
    final warnings = <Map<String, dynamic>>[];
    final thresholds = NutritionUtils.nutrientWarningThresholds;
    
    for (var entry in thresholds.entries) {
      final nutrient = entry.key;
      final limit = entry.value['limit'] as double;
      final message = entry.value['message'] as String;
      final value = _totals[nutrient] ?? 0.0;
      
      if (value > limit) {
        warnings.add({
          'nutrient': nutrient,
          'value': value,
          'limit': limit,
          'message': message,
          'severity': value > limit * 1.5 ? 'high' : 'medium',
        });
      }
    }
    
    setState(() => _warnings = warnings);
  }

  Future<void> _checkConsecutiveDays(DateTime currentDate) async {
    final criticalNutrients = NutritionUtils.criticalNutrients;
    final consecutiveAlarms = NutritionUtils.consecutiveDayAlarms;
    final alerts = <Map<String, dynamic>>[];
    final missingDays = <String, int>{};
    
    for (var nutrient in criticalNutrients) {
      int consecutiveMissing = 0;
      
      // Check last 7 days
      for (int i = 0; i < 7; i++) {
        final checkDate = currentDate.subtract(Duration(days: i));
        final logs = await _supabaseService.getDailyMealLogs(checkDate);
        
        double dayTotal = 0.0;
        for (var log in logs) {
          final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
          if (nutritionData != null && nutritionData.isNotEmpty) {
            dayTotal += (nutritionData[nutrient] as num?)?.toDouble() ?? 0.0;
            continue;
          }
          
          final recipeId = log['recipe_id'] as String?;
          if (recipeId != null) {
            final recipe = log['recipes'] as Map<String, dynamic>?;
            if (recipe != null) {
              final quantity = (log['quantity'] as num).toDouble();
              final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
              final factor = quantity / servings;
              dayTotal += ((recipe[nutrient] as num?)?.toDouble() ?? 0.0) * factor;
              continue;
            }
          }
          
          final foodData = log['general_food_flow'] as Map<String, dynamic>?;
          if (foodData != null) {
            final quantity = (log['quantity'] as num).toDouble();
            final multiplier = quantity / 100.0;
            dayTotal += ((foodData[nutrient] as num?)?.toDouble() ?? 0.0) * multiplier;
          }
        }
        
        final rda = NutritionUtils.microNutrientRDA[nutrient] ?? 0.0;
        if (rda > 0 && dayTotal < rda * 0.5) { // Less than 50% of RDA
          consecutiveMissing++;
        } else {
          break; // Stop counting if we find a day with enough
        }
      }
      
      missingDays[nutrient] = consecutiveMissing;
      
      // Check if alarm threshold is reached
      final alarmThreshold = consecutiveAlarms[nutrient];
      if (alarmThreshold != null && consecutiveMissing >= alarmThreshold) {
        final meta = NutritionData.nutrients.firstWhere(
          (n) => n.key == nutrient,
          orElse: () => NutritionData.nutrients.first,
        );
        alerts.add({
          'nutrient': nutrient,
          'name': meta.name,
          'days': consecutiveMissing,
          'threshold': alarmThreshold,
          'severity': consecutiveMissing >= alarmThreshold * 2 ? 'critical' : 'warning',
        });
      }
    }
    
    setState(() {
      _consecutiveDaysMissing = missingDays;
      _criticalAlerts = alerts;
    });
  }

  void _calculateTotals({double manualWater = 0.0}) {
    Map<String, double> temp = {};
    for (var log in _logs) {
      Map<String, dynamic>? foodData;
      double multiplier = 1.0;
      
      // Priority 1: Check nutrition_data JSONB (for recipes and custom foods with full nutrition)
      final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
      if (nutritionData != null && nutritionData.isNotEmpty) {
        // nutrition_data already contains calculated values for the logged quantity
        // No need to multiply, values are already per serving/quantity
        for (var meta in NutritionData.nutrients) {
          final val = (nutritionData[meta.key] as num?)?.toDouble() ?? 0.0;
          temp[meta.key] = (temp[meta.key] ?? 0.0) + val;
        }
        continue; // Skip to next log
      }
      
      // Priority 2: Check recipe_id (link to recipes table with full nutrition)
      final recipeId = log['recipe_id'] as String?;
      if (recipeId != null) {
        final recipe = log['recipes'] as Map<String, dynamic>?;
        if (recipe != null) {
          final quantity = (log['quantity'] as num).toDouble();
          final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
          final factor = quantity / servings; // Calculate factor based on servings
          
          for (var meta in NutritionData.nutrients) {
            final val = ((recipe[meta.key] as num?)?.toDouble() ?? 0.0) * factor;
            temp[meta.key] = (temp[meta.key] ?? 0.0) + val;
          }
          continue; // Skip to next log
        }
      }
      
      // Priority 3: Check general_food_flow (regular foods from database)
      foodData = log['general_food_flow'] as Map<String, dynamic>?;
      if (foodData != null) {
        final quantity = (log['quantity'] as num).toDouble();
        multiplier = quantity / 100.0; // Assuming food data is per 100g
        for (var meta in NutritionData.nutrients) {
          final val = (foodData[meta.key] as num?)?.toDouble() ?? 0.0;
          temp[meta.key] = (temp[meta.key] ?? 0.0) + (val * multiplier);
        }
        continue;
      }
      
      // Priority 4: Check custom_food_name (might have nutrition_data or need to fetch from user_custom_foods)
      final customFoodName = log['custom_food_name'] as String?;
      if (customFoodName != null && foodData == null) {
        // If no nutrition_data, try to get from basic fields (calories, protein, carbs, fat)
        // This is a fallback for old logs that don't have nutrition_data
        final calories = (log['calories'] as num?)?.toDouble() ?? 0.0;
        final protein = (log['protein'] as num?)?.toDouble() ?? 0.0;
        final carbs = (log['carbs'] as num?)?.toDouble() ?? 0.0;
        final fat = (log['fat'] as num?)?.toDouble() ?? 0.0;
        
        // At least add the basic macros
        temp['calories'] = (temp['calories'] ?? 0.0) + calories;
        temp['protein'] = (temp['protein'] ?? 0.0) + protein;
        temp['carbs'] = (temp['carbs'] ?? 0.0) + carbs;
        temp['fat'] = (temp['fat'] ?? 0.0) + fat;
      }
    }
    
    // Add manual water input (convert ml to g - 1ml = 1g for water)
    if (manualWater > 0) {
      temp['water'] = (temp['water'] ?? 0.0) + manualWater;
    }
    
    setState(() => _totals = temp);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<NutrientMeta>>{};
    for (var n in NutritionData.nutrients) {
      grouped.putIfAbsent(n.category, () => []).add(n);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.vitalityBreakdown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: AppLocalizations.of(context)!.selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  if (_criticalAlerts.isNotEmpty) ...[
                    _buildCriticalAlerts(),
                    const SizedBox(height: 16),
                  ],
                  if (_warnings.isNotEmpty) ...[
                    _buildWarningsSection(),
                    const SizedBox(height: 16),
                  ],
                  _buildVitalityShield(),
                  const SizedBox(height: 24),
                  ...grouped.entries.map((entry) {
                    return _buildCategorySection(entry.key, entry.value);
                  }),
                  const SizedBox(height: 100), // Extra padding at bottom
                ],
              ),
            ),
    );
  }

  Widget _buildCriticalAlerts() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade600,
              Colors.orange.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.criticalAlerts,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._criticalAlerts.map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      alert['severity'] == 'critical' ? Icons.error : Icons.warning,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Missing for ${alert['days']} consecutive days',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${alert['days']} days',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsSection() {
    return FadeInDown(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.highIntakeWarnings,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._warnings.map((warning) {
              final meta = NutritionData.nutrients.firstWhere(
                (n) => n.key == warning['nutrient'],
                orElse: () => NutritionData.nutrients.first,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: warning['severity'] == 'high'
                        ? Colors.red.shade300
                        : Colors.orange.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (warning['severity'] == 'high'
                                ? Colors.red
                                : Colors.orange)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        meta.icon,
                        color: warning['severity'] == 'high'
                            ? Colors.red
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.getLocalizedName(context),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            warning['message'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(warning['value'] as double).toStringAsFixed(1)} ${meta.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: warning['severity'] == 'high'
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          'Limit: ${(warning['limit'] as double).toStringAsFixed(0)} ${meta.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalityShield() {
    final rdas = NutritionUtils.microNutrientRDA;
    final vitamins = NutritionData.nutrients
        .where((n) => rdas.containsKey(n.key))
        .toList();
    
    // Calculate overall coverage percentage
    double totalPercent = 0.0;
    int coveredCount = 0;
    for (var v in vitamins) {
      final val = _totals[v.key] ?? 0.0;
      final rda = rdas[v.key]!;
      final percent = (val / rda).clamp(0.0, 2.0); // Allow up to 200% for display
      totalPercent += percent;
      if (percent >= 1.0) coveredCount++;
    }
    final avgPercent = vitamins.isNotEmpty ? (totalPercent / vitamins.length) : 0.0;
    final overallPercent = (avgPercent * 100).clamp(0.0, 200.0);
    
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 32, // Extra padding bottom to avoid navigation bar
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.vitalityShield,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.dailyNutrientCoverage,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Overall progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.overallCoverage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${overallPercent.toInt()}%',
                          style: TextStyle(
                            color: overallPercent >= 100
                                ? Colors.greenAccent
                                : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$coveredCount/${vitamins.length} nutrients met',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: (overallPercent / 100).clamp(0.0, 1.0),
                            strokeWidth: 6,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallPercent >= 100
                                  ? Colors.greenAccent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '${overallPercent.toInt()}%',
                          style: TextStyle(
                            color: overallPercent >= 100
                                ? Colors.greenAccent
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Individual nutrients
            ...vitamins.map((v) {
              final val = _totals[v.key] ?? 0.0;
              final rda = rdas[v.key]!;
              final percent = (val / rda).clamp(0.0, 2.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.getLocalizedName(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${val.toStringAsFixed(1)} ${v.unit} / ${rda.toStringAsFixed(0)} ${v.unit}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: percent >= 1.0
                                ? Colors.greenAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: percent >= 1.0
                                  ? Colors.greenAccent
                                  : Colors.white30,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(percent * 100).toInt()}%',
                            style: TextStyle(
                              color: percent >= 1.0
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        color: percent >= 1.0
                            ? Colors.greenAccent
                            : AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateStr = isToday
        ? 'Today'
        : DateFormat('MMM dd, yyyy').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final newDate = _selectedDate.subtract(const Duration(days: 1));
                  setState(() => _selectedDate = newDate);
                  _loadLogsForDate(newDate);
                },
                tooltip: AppLocalizations.of(context)!.previousDay,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday
                    ? null
                    : () {
                        final newDate = _selectedDate.add(const Duration(days: 1));
                        if (newDate.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                          setState(() => _selectedDate = newDate);
                          _loadLogsForDate(newDate);
                        }
                      },
                tooltip: AppLocalizations.of(context)!.nextDay,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadLogsForDate(picked);
    }
  }

  Widget _buildMacroSummary() {
    final calories = _totals['calories'] ?? 0.0;
    final protein = _totals['protein'] ?? 0.0;
    final carbs = _totals['carbs'] ?? 0.0;
    final fat = _totals['fat'] ?? 0.0;
    
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
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
                const Icon(
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.dailyMacrosSummary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMacroItem(
                    'Calories',
                    calories.toStringAsFixed(0),
                    'kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroItem(
                    'Protein',
                    protein.toStringAsFixed(1),
                    'g',
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMacroItem(
                    'Carbs',
                    carbs.toStringAsFixed(1),
                    'g',
                    Icons.bolt,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroItem(
                    'Fat',
                    fat.toStringAsFixed(1),
                    'g',
                    Icons.opacity,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<NutrientMeta> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 24),
          child: Text(
            NutritionData.getLocalizedCategory(context, title).toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: items.map((item) {
              final val = _totals[item.key] ?? 0.0;
              final isLast = items.last == item;
              return Column(
                children: [
                  InkWell(
                    onTap: () => _showNutrientChart(item),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        item.getLocalizedName(context),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item.getLocalizedDescription(context),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${val.toStringAsFixed(1)} ${item.unit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 64),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showNutrientChart(NutrientMeta nutrient) async {
    setState(() => _isLoading = true);
    
    // Get data for last 7 days
    final List<Map<String, double>> weekData = [];
    final List<String> labels = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final logs = await _supabaseService.getDailyMealLogs(date);
      
      double total = 0.0;
      for (var log in logs) {
        // Priority 1: Check nutrition_data JSONB
        final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
        if (nutritionData != null && nutritionData.isNotEmpty) {
          total += (nutritionData[nutrient.key] as num?)?.toDouble() ?? 0.0;
          continue;
        }
        
        // Priority 2: Check recipe_id
        final recipeId = log['recipe_id'] as String?;
        if (recipeId != null) {
          final recipe = log['recipes'] as Map<String, dynamic>?;
          if (recipe != null) {
            final quantity = (log['quantity'] as num).toDouble();
            final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
            final factor = quantity / servings;
            total += ((recipe[nutrient.key] as num?)?.toDouble() ?? 0.0) * factor;
            continue;
          }
        }
        
        // Priority 3: Check general_food_flow
        final foodData = log['general_food_flow'] as Map<String, dynamic>?;
        if (foodData != null) {
          final quantity = (log['quantity'] as num).toDouble();
          final multiplier = quantity / 100.0;
          total += ((foodData[nutrient.key] as num?)?.toDouble() ?? 0.0) * multiplier;
        }
      }
      
      weekData.add({
        'date': date.millisecondsSinceEpoch.toDouble(),
        'value': total,
      });
      
      final dayName = DateFormat('EEE').format(date);
      labels.add(dayName);
    }
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              nutrient.icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nutrient.getLocalizedName(context),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last 7 Days',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareChart(nutrient, weekData, labels),
                        tooltip: AppLocalizations.of(context)!.shareChart,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20,
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxValue(weekData) / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: _getMaxValue(weekData) / 5,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < labels.length) {
                              return Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        left: BorderSide(color: Colors.grey.shade300, width: 1),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weekData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value['value']!);
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.primary,
                        barWidth: 4,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.primary,
                              strokeWidth: 3,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                        shadow: Shadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: _getMaxValue(weekData) * 1.2,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              '${touchedSpot.y.toStringAsFixed(1)} ${nutrient.unit}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 32, // Extra padding for navigation bar
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekData.asMap().entries.map((entry) {
                      final dayValue = entry.value['value']!;
                      final dayLabel = labels[entry.key];
                      final maxValue = _getMaxValue(weekData);
                      final isHighest = dayValue == maxValue;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isHighest
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isHighest
                                ? Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayValue.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isHighest
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxValue(List<Map<String, double>> data) {
    if (data.isEmpty) return 100.0;
    double max = 0.0;
    for (var item in data) {
      if (item['value']! > max) max = item['value']!;
    }
    return max == 0 ? 100.0 : max;
  }

  Future<void> _shareChart(
    NutrientMeta nutrient,
    List<Map<String, double>> weekData,
    List<String> labels,
  ) async {
    try {
      // Create a text summary of the chart data
      final buffer = StringBuffer();
      buffer.writeln('📊 ${nutrient.getLocalizedName(context)} - Weekly Trend');
      buffer.writeln('');
      buffer.writeln('Last 7 Days:');
      
      for (int i = 0; i < weekData.length && i < labels.length; i++) {
        final value = weekData[i]['value'] ?? 0.0;
        buffer.writeln('${labels[i]}: ${value.toStringAsFixed(1)} ${nutrient.unit}');
      }
      
      buffer.writeln('');
      final avg = weekData.isEmpty
          ? 0.0
          : weekData.map((e) => e['value']!).reduce((a, b) => a + b) / weekData.length;
      final max = weekData.isEmpty
          ? 0.0
          : weekData.map((e) => e['value']!).reduce((a, b) => a > b ? a : b);
      final min = weekData.isEmpty
          ? 0.0
          : weekData.map((e) => e['value']!).reduce((a, b) => a < b ? a : b);
      
      buffer.writeln('Average: ${avg.toStringAsFixed(1)} ${nutrient.unit}');
      buffer.writeln('Max: ${max.toStringAsFixed(1)} ${nutrient.unit}');
      buffer.writeln('Min: ${min.toStringAsFixed(1)} ${nutrient.unit}');
      buffer.writeln('');
      buffer.writeln('Shared from Flow App');
      
      await Share.share(buffer.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSharing(e.toString()))),
        );
      }
    }
  }
}
