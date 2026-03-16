import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WaterTrackingPage extends StatefulWidget {
  final int currentWater;
  final int target;
  
  const WaterTrackingPage({
    super.key,
    required this.currentWater,
    required this.target,
  });

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late AnimationController _waveController;
  
  int _manualWater = 0;
  double _foodWater = 0.0;
  int _totalWater = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _waterHistory = [];
  Map<String, dynamic>? _profile;
  double? _currentWeight;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadWaterData();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      
      // Get manual water logs
      final waterLogs = await _supabaseService.getDailyWaterLogs(now);
      _manualWater = waterLogs.fold(0, (sum, log) => sum + (log['amount_ml'] as int));
      
      // Get water from food (from daily_logs nutrition_data)
      final mealLogs = await _supabaseService.getDailyMealLogs(now);
      _foodWater = 0.0;
      
      for (var log in mealLogs) {
        // Priority 1: Check nutrition_data JSONB
        final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
        if (nutritionData != null && nutritionData.isNotEmpty) {
          final water = (nutritionData['water'] as num?)?.toDouble();
          if (water != null) {
            _foodWater += water;
          }
          continue;
        }
        
        // Priority 2: Check recipe_id
        final recipeId = log['recipe_id'] as String?;
        if (recipeId != null) {
          final recipe = log['recipes'] as Map<String, dynamic>?;
          if (recipe != null) {
            final quantity = (log['quantity'] as num?)?.toDouble() ?? 0.0;
            final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
            final factor = quantity / servings;
            final water = (recipe['water'] as num?)?.toDouble() ?? 0.0;
            _foodWater += water * factor;
            continue;
          }
        }
        
        // Priority 3: Check general_food_flow
        final foodData = log['general_food_flow'] as Map<String, dynamic>?;
        if (foodData != null) {
          final quantity = (log['quantity'] as num?)?.toDouble() ?? 0.0;
          final multiplier = quantity / 100.0;
          final water = (foodData['water'] as num?)?.toDouble() ?? 0.0;
          _foodWater += water * multiplier;
        }
      }
      
      _totalWater = _manualWater + _foodWater.round();
      
      // Get water history for last 7 days
      _waterHistory = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayLogs = await _supabaseService.getDailyWaterLogs(date);
        final dayMealLogs = await _supabaseService.getDailyMealLogs(date);
        
        int dayManual = dayLogs.fold(0, (sum, log) => sum + (log['amount_ml'] as int));
        double dayFood = 0.0;
        
        for (var log in dayMealLogs) {
          final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
          if (nutritionData != null && nutritionData.isNotEmpty) {
            final water = (nutritionData['water'] as num?)?.toDouble();
            if (water != null) dayFood += water;
          } else {
            final recipe = log['recipes'] as Map<String, dynamic>?;
            if (recipe != null) {
              final quantity = (log['quantity'] as num?)?.toDouble() ?? 0.0;
              final servings = (recipe['servings'] as num?)?.toDouble() ?? 1.0;
              final factor = quantity / servings;
              final water = (recipe['water'] as num?)?.toDouble() ?? 0.0;
              dayFood += water * factor;
            } else {
              final foodData = log['general_food_flow'] as Map<String, dynamic>?;
              if (foodData != null) {
                final quantity = (log['quantity'] as num?)?.toDouble() ?? 0.0;
                final multiplier = quantity / 100.0;
                final water = (foodData['water'] as num?)?.toDouble() ?? 0.0;
                dayFood += water * multiplier;
              }
            }
          }
        }
        
        _waterHistory.add({
          'date': date,
          'manual': dayManual,
          'food': dayFood.round(),
          'total': dayManual + dayFood.round(),
        });
      }
      
      // Get profile for target
      _profile = await _supabaseService.getProfile();
      
      // Get latest weight
      _currentWeight = await _supabaseService.getLatestWeight() ?? 
          (_profile?['current_weight'] as num?)?.toDouble() ?? 70.0;
      
    } catch (e) {
      print('Error loading water data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int amount) async {
    await _supabaseService.logWater(amount);
    _loadWaterData();
  }

  @override
  Widget build(BuildContext context) {
    final target = (_profile?['daily_water_target'] as num?)?.toInt() ?? widget.target;
    final progress = _totalWater / target;
    final progressPercent = (progress * 100).clamp(0.0, 100.0);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.hydrationTracking),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWaterProgressCard(target, progressPercent),
                  const SizedBox(height: 24),
                  _buildPersonalizedWaterNeeds(),
                  const SizedBox(height: 24),
                  _buildWaterBreakdown(),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(),
                  const SizedBox(height: 24),
                  _buildWaterBenefits(),
                  const SizedBox(height: 24),
                  _buildWaterImpact(),
                  const SizedBox(height: 24),
                  _buildWaterTips(),
                  const SizedBox(height: 24),
                  _buildWaterFacts(),
                  const SizedBox(height: 24),
                  _buildQuickAddButtons(),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
    );
  }

  Widget _buildWaterProgressCard(int target, double progressPercent) {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.todaysHydration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_totalWater / $target ml',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.ofDailyGoal(progressPercent.toStringAsFixed(0)),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progressPercent / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedWaterNeeds() {
    if (_profile == null || _currentWeight == null) return const SizedBox.shrink();
    
    final currentWeight = _currentWeight!;
    final gender = _profile!['gender'] as String? ?? 'MALE';
    final activityLevel = _profile!['activity_level'] as String? ?? 'SEDENTARY';
    final calculatedTarget = NutritionUtils.calculateWaterTarget(
      weight: currentWeight,
      gender: gender,
      activityLevel: activityLevel,
    );
    
    // Calculate base water (weight-based)
    final baseWater = (currentWeight * 35).round();
    
    final l10n = AppLocalizations.of(context)!;
    
    // Calculate gender adjustment
    int genderAdjustment = 0;
    String genderText = '';
    if (gender.toUpperCase() == 'MALE') {
      genderAdjustment = 500;
      genderText = '${l10n.male} (+500ml)';
    } else if (gender.toUpperCase() == 'FEMALE') {
      genderAdjustment = 200;
      genderText = '${l10n.female} (+200ml)';
    } else {
      genderAdjustment = 350;
      genderText = '${l10n.other} (+350ml)';
    }
    
    // Calculate activity adjustment
    int activityAdjustment = 0;
    String activityText = '';
    switch (activityLevel.toUpperCase()) {
      case 'SEDENTARY':
        activityAdjustment = 0;
        activityText = '${l10n.sedentary} (+0ml)';
        break;
      case 'LIGHTLY ACTIVE':
        activityAdjustment = 300;
        activityText = '${l10n.lightlyActive} (+300ml)';
        break;
      case 'MODERATELY ACTIVE':
        activityAdjustment = 500;
        activityText = '${l10n.moderatelyActive} (+500ml)';
        break;
      case 'VERY ACTIVE':
        activityAdjustment = 800;
        activityText = '${l10n.veryActive} (+800ml)';
        break;
      default:
        activityAdjustment = 0;
        activityText = '${l10n.sedentary} (+0ml)';
    }
    
    return FadeInUp(
      delay: const Duration(milliseconds: 50),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.yourPersonalizedWaterNeeds,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildWaterCalculationCard(
              l10n.baseWeight,
              '${currentWeight.toStringAsFixed(1)} kg × 35ml',
              baseWater,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildWaterCalculationCard(
              l10n.genderAdjustment,
              genderText,
              genderAdjustment,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildWaterCalculationCard(
              l10n.activityLevel,
              activityText,
              activityAdjustment,
              Colors.orange,
            ),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.yourDailyTarget,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$calculatedTarget ml',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: calculatedTarget * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final labels = ['Base', 'Gender', 'Activity', 'Total'];
                          if (index >= 0 && index < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}ml',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: baseWater.toDouble(),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: genderAdjustment.toDouble(),
                          color: Colors.purple,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: activityAdjustment.toDouble(),
                          color: Colors.orange,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: calculatedTarget.toDouble(),
                          color: Colors.blue.shade700,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCalculationCard(String label, String description, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$amount ml',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBreakdown() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.waterBreakdown,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildBreakdownItem(
              l10n.manualInput,
              _manualWater,
              Icons.local_drink,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              l10n.fromFood,
              _foodWater.round(),
              Icons.restaurant,
              Colors.green,
            ),
            const Divider(height: 32),
            _buildBreakdownItem(
              l10n.total,
              _totalWater,
              Icons.water_drop,
              Colors.blue.shade700,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int amount, IconData icon, Color color, {bool isTotal = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          '$amount ml',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final l10n = AppLocalizations.of(context)!;
    if (_waterHistory.isEmpty) return const SizedBox.shrink();
    
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weeklyTrend,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _waterHistory.map((e) => e['total'] as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blue,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _waterHistory[group.x.toInt()];
                        return BarTooltipItem(
                          '${day['total']} ml\n${DateFormat('EEE').format(day['date'])}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _waterHistory.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('EEE').format(_waterHistory[index]['date']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}ml',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          );
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _waterHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final total = day['total'] as int;
                    final isToday = index == _waterHistory.length - 1;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: total.toDouble(),
                          color: isToday ? Colors.blue : Colors.blue.shade300,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: widget.target.toDouble(),
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterBenefits() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.whyWaterMatters,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBenefitItem(
              Icons.favorite,
              l10n.heartHealth,
              l10n.heartHealthDesc,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.psychology,
              l10n.brainFunction,
              l10n.brainFunctionDesc,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.energy_savings_leaf,
              l10n.energyLevels,
              l10n.energyLevelsDesc,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.spa,
              l10n.skinHealth,
              l10n.skinHealthDesc,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.fitness_center,
              l10n.muscleFunction,
              l10n.muscleFunctionDesc,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.eco,
              l10n.digestion,
              l10n.digestionDesc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterImpact() {
    final l10n = AppLocalizations.of(context)!;
    final hydrationLevel = _calculateHydrationLevel();
    
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourHydrationImpact,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hydrationLevel['color'].withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hydrationLevel['color'],
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hydrationLevel['icon'],
                    color: hydrationLevel['color'],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hydrationLevel['status'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hydrationLevel['color'],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hydrationLevel['message'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...hydrationLevel['effects'] as List<Widget>,
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateHydrationLevel() {
    final l10n = AppLocalizations.of(context)!;
    final progress = _totalWater / widget.target;
    
    if (progress >= 1.0) {
      return {
        'status': l10n.excellentHydration,
        'message': l10n.excellentHydrationMsg,
        'color': Colors.green,
        'icon': Icons.check_circle,
        'effects': [
          _buildImpactItem(l10n.optimalBrainFunction, Colors.green),
          _buildImpactItem(l10n.peakPhysicalPerformance, Colors.green),
          _buildImpactItem(l10n.healthySkinDigestion, Colors.green),
        ],
      };
    } else if (progress >= 0.75) {
      return {
        'status': l10n.goodHydration,
        'message': l10n.goodHydrationMsg,
        'color': Colors.blue,
        'icon': Icons.thumb_up,
        'effects': [
          _buildImpactItem(l10n.goodEnergyLevels, Colors.blue),
          _buildImpactItem(l10n.normalCognitiveFunction, Colors.blue),
          _buildImpactItem(l10n.drinkMoreOptimal, Colors.orange),
        ],
      };
    } else if (progress >= 0.5) {
      return {
        'status': l10n.moderateHydration,
        'message': l10n.moderateHydrationMsg,
        'color': Colors.orange,
        'icon': Icons.warning,
        'effects': [
          _buildImpactItem(l10n.mildDehydrationPossible, Colors.orange),
          _buildImpactItem(l10n.reducedEnergyLevels, Colors.orange),
          _buildImpactItem(l10n.drinkMoreWater, Colors.blue),
        ],
      };
    } else {
      return {
        'status': l10n.lowHydration,
        'message': l10n.lowHydrationMsg,
        'color': Colors.red,
        'icon': Icons.warning_amber_rounded,
        'effects': [
          _buildImpactItem(l10n.dehydrationRisk, Colors.red),
          _buildImpactItem(l10n.fatigueHeadachesPossible, Colors.red),
          _buildImpactItem(l10n.startDrinkingWater, Colors.blue),
        ],
      };
    }
  }

  Widget _buildImpactItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTips() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
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
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.hydrationTips,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTipItem(
              '1',
              l10n.startYourDayRight,
              l10n.startYourDayRightDesc,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '2',
              l10n.setReminders,
              l10n.setRemindersDesc,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '3',
              l10n.drinkBeforeMeals,
              l10n.drinkBeforeMealsDesc,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '4',
              l10n.carryWaterBottle,
              l10n.carryWaterBottleDesc,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '5',
              l10n.eatWaterRichFoods,
              l10n.eatWaterRichFoodsDesc,
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              '6',
              l10n.monitorYourUrine,
              l10n.monitorYourUrineDesc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterFacts() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.didYouKnow,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFactItem(
              Icons.percent,
              l10n.bodyIsWater,
              l10n.bodyIsWaterDesc,
            ),
            const SizedBox(height: 16),
            _buildFactItem(
              Icons.timer,
              l10n.surviveWeeksWithoutFood,
              l10n.surviveWeeksWithoutFoodDesc,
            ),
            const SizedBox(height: 16),
            _buildFactItem(
              Icons.water_drop,
              l10n.brainIsWater,
              l10n.brainIsWaterDesc,
            ),
            const SizedBox(height: 16),
            _buildFactItem(
              Icons.thermostat,
              l10n.waterRegulatesTemperature,
              l10n.waterRegulatesTemperatureDesc,
            ),
            const SizedBox(height: 16),
            _buildFactItem(
              Icons.bloodtype,
              l10n.waterCarriesNutrients,
              l10n.waterCarriesNutrientsDesc,
            ),
            const SizedBox(height: 16),
            _buildFactItem(
              Icons.cleaning_services,
              l10n.waterFlushesToxins,
              l10n.waterFlushesToxinsDesc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButtons() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 550),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickAdd,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAddButton(250, l10n.glass, Icons.local_drink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAddButton(500, l10n.bottle, Icons.local_drink_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAddButton(750, l10n.large, Icons.water_drop),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(int amount, String label, IconData icon) {
    return InkWell(
      onTap: () => _addWater(amount),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$amount ml',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wave painter for water animation
class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double progress;
  final Color color;

  _WavePainter(this.animation, this.progress, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final waveHeight = size.height * (1 - progress);
    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, waveHeight);

    for (double x = 0; x < size.width; x++) {
      final y = waveHeight + math.sin((x / size.width * 2 * math.pi) + (animation.value * 2 * math.pi)) * 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.progress != progress;
  }
}

