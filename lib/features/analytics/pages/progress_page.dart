import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;

  List<Map<String, dynamic>> _weightHistory = [];
  Map<String, List<double>> _weeklyStats = {
    'calories': [],
    'protein': [],
    'carbs': [],
    'fat': []
  };
  Map<String, dynamic>? _profile;
  double? _initialWeight;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _supabaseService.getProfile();
    final weightHistory = await _supabaseService.getWeightHistory(days: 7);
    final weeklyStats = await _supabaseService.getWeeklyStats();
    final initialWeight = await _supabaseService.getInitialWeight();

    setState(() {
      _profile = profile;
      _weightHistory = weightHistory;
      _weeklyStats = weeklyStats;
      _initialWeight = initialWeight;
      _isLoading = false;
    });
  }

  String _calculateTargetDate() {
    if (_profile == null || _weeklyStats['calories']!.isEmpty) return 'TBD';

    double currentWeight = (_profile!['current_weight'] as num?)?.toDouble() ?? 0;
    double targetWeight = (_profile!['target_weight'] as num?)?.toDouble() ?? currentWeight;

    if (currentWeight == 0 || currentWeight == targetWeight) return 'Reached!';

    double dailyTarget = (_profile!['daily_calorie_target'] as num?)?.toDouble() ?? 2000;
    double avgCals = _weeklyStats['calories']!.reduce((a, b) => a + b) / _weeklyStats['calories']!.length;
    double dailyDeficit = dailyTarget - avgCals;

    bool isLosing = targetWeight < currentWeight;
    if (isLosing && dailyDeficit <= 0) return 'Needs Deficit';
    if (!isLosing && dailyDeficit >= 0) return 'Needs Surplus';

    double weightToLose = (currentWeight - targetWeight).abs();
    double totalCaloriesNeeded = weightToLose * 7700;

    int daysRemaining = (totalCaloriesNeeded / dailyDeficit.abs()).ceil();
    if (daysRemaining > 1000) return AppLocalizations.of(context)!.moreThan3Years;

    final targetDate = DateTime.now().add(Duration(days: daysRemaining));
    return DateFormat('MMM dd, yyyy', Localizations.localeOf(context).languageCode).format(targetDate);
  }

  double _calculatePredictedWeight() {
    if (_profile == null || _weeklyStats['calories']!.isEmpty) return 0;

    double currentWeight = (_profile!['current_weight'] as num?)?.toDouble() ?? 0;
    if (currentWeight == 0) return 0;

    double todayCals = _weeklyStats['calories']!.last;
    double targetCals = (_profile!['daily_calorie_target'] as num?)?.toDouble() ?? 2000;

    double change = (todayCals - targetCals) / 7700;
    return currentWeight + change;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avgP = _weeklyStats['protein']!.isNotEmpty
        ? (_weeklyStats['protein']!.reduce((a, b) => a + b) / 7).toInt()
        : 0;
    final avgC = _weeklyStats['carbs']!.isNotEmpty
        ? (_weeklyStats['carbs']!.reduce((a, b) => a + b) / 7).toInt()
        : 0;
    final avgF = _weeklyStats['fat']!.isNotEmpty
        ? (_weeklyStats['fat']!.reduce((a, b) => a + b) / 7).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.insightsProgress,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBMIStatus(),
            const SizedBox(height: 24),
            _buildPredictionCard(),
            const SizedBox(height: 24),
            _buildMetabolicEfficiency(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppLocalizations.of(context)!.weightEvolution),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.theoryDescription,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 16),
            _buildWeightChart(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppLocalizations.of(context)!.weeklyCalories),
            const SizedBox(height: 16),
            _buildWeeklyCalorieChart(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppLocalizations.of(context)!.avgWeeklyMacros),
            const SizedBox(height: 16),
            _buildMacroBreakdown(avgP, avgC, avgF),
            const SizedBox(height: 32),
            _buildAdvancedInsightsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedInsightsSection() {
    return FutureBuilder<Map<String, double>>(
      future: _supabaseService.getDailyMicronutrients(DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final nutrients = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)!.advancedHealthInsights),
            const SizedBox(height: 16),
            _buildMicronutrientRadar(nutrients),
            const SizedBox(height: 32),
            _buildNastiesWatchdog(nutrients),
          ],
        );
      },
    );
  }

  Widget _buildMicronutrientRadar(Map<String, double> nutrients) {
    final rda = NutritionUtils.microNutrientRDA;
    final radarMetrics = ['calcium', 'iron', 'magnesium', 'zinc', 'vitamin_c', 'vitamin_d', 'vitamin_b12', 'fiber'];
    
    final values = radarMetrics.map((key) {
      final current = nutrients[key] ?? 0.0;
      final target = rda[key] ?? 1.0;
      final pct = current / target;
      return pct > 1.0 ? 1.0 : pct;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Micronutrient Radar',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.micronutrientRadarDesc,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: true),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withOpacity(0.2),
                    borderColor: AppColors.primary,
                    entryRadius: 3,
                    dataEntries: values.map((e) => RadarEntry(value: e)).toList(),
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.black12),
                titlePositionPercentageOffset: 0.1,
                titleTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                getTitle: (index, angle) {
                  final key = radarMetrics[index];
                  switch (key) {
                    case 'vitamin_c': return RadarChartTitle(text: 'Vit C');
                    case 'vitamin_d': return RadarChartTitle(text: 'Vit D');
                    case 'vitamin_b12': return RadarChartTitle(text: 'B12');
                    case 'calcium': return RadarChartTitle(text: 'Calcium');
                    case 'iron': return RadarChartTitle(text: 'Iron');
                    case 'magnesium': return RadarChartTitle(text: 'Mg');
                    case 'zinc': return RadarChartTitle(text: 'Zinc');
                    case 'fiber': return RadarChartTitle(text: 'Fiber');
                    default: return RadarChartTitle(text: '');
                  }
                },
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: const BorderSide(color: Colors.black12, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNastiesWatchdog(Map<String, double> nutrients) {
    final thresholds = NutritionUtils.nutrientWarningThresholds;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nasties Watchdog',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.nastiesWatchdogDesc,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...thresholds.entries.map((entry) {
          final key = entry.key;
          final data = entry.value;
          final limit = (data['limit'] as num).toDouble();
          final current = nutrients[key] ?? 0.0;
          final isHigh = current > limit;
          final pct = (current / limit).clamp(0.0, 1.5);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isHigh ? Colors.red.withOpacity(0.3) : Colors.transparent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatName(key),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${current.toInt()} / ${limit.toInt()}${key == 'sodium' ? 'mg' : 'g'}',
                      style: TextStyle(
                        color: isHigh ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct > 1.0 ? 1.0 : pct,
                    backgroundColor: Colors.grey[200],
                    color: isHigh ? Colors.red : Colors.green,
                    minHeight: 8,
                  ),
                ),
                if (isHigh) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['message'] as String,
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatName(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  Widget _buildBMIStatus() {
    if (_profile == null) return const SizedBox.shrink();
    final weight = (_profile!['current_weight'] as num?)?.toDouble() ?? 0;
    final height = (_profile!['height'] as num?)?.toDouble() ?? 0;
    if (weight == 0 || height == 0) return const SizedBox.shrink();

    final bmi = NutritionUtils.calculateBMI(weight, height);
    final status = NutritionUtils.getBMIStatus(bmi);
    final statusText = status == 'Normal' ? AppLocalizations.of(context)!.normal : status;

    return FadeInLeft(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.bodyMassIndex,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'Normal'
                            ? Colors.green.withAlpha(51)
                            : Colors.orange.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: status == 'Normal' ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final predicted = _calculatePredictedWeight();
    final targetDate = _calculateTargetDate();
    if (predicted == 0) return const SizedBox.shrink();

    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(76),
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
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.smartProjection,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  targetDate == AppLocalizations.of(context)!.tbd
                      ? ''
                      : AppLocalizations.of(context)!.estGoal(targetDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${predicted.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.predictedTomorrow,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    targetDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetabolicEfficiency() {
    if (_weightHistory.isEmpty || _initialWeight == null || _initialWeight == 0) {
      return const SizedBox.shrink();
    }

    final currentWeight = (_weightHistory.last['weight'] as num).toDouble();
    final totalLoss = _initialWeight! - currentWeight;

    if (totalLoss.abs() < 0.5) return const SizedBox.shrink();

    double dailyTarget = (_profile!['daily_calorie_target'] as num?)?.toDouble() ?? 2000;

    if (_weightHistory.length < 2) return const SizedBox.shrink();

    final weekStartWeight = (_weightHistory.first['weight'] as num).toDouble();
    final weekEndWeight = (_weightHistory.last['weight'] as num).toDouble();
    final actualWeekLoss = weekStartWeight - weekEndWeight;

    double theoreticalWeekLoss = 0;
    if (_weeklyStats['calories'] != null) {
      for (var val in _weeklyStats['calories']!) {
        theoreticalWeekLoss += (dailyTarget - val) / 7700;
      }
    }

    String status = AppLocalizations.of(context)!.normal;
    double efficiency = 1.0;
    Color color = Colors.green;
    String msg = AppLocalizations.of(context)!.metabolismNormalMsg;

    if (theoreticalWeekLoss > 0.1) {
      efficiency = actualWeekLoss / theoreticalWeekLoss;
      if (efficiency > 1.2) {
        status = AppLocalizations.of(context)!.metabolismFast;
        color = Colors.orange;
        msg = AppLocalizations.of(context)!.metabolismFastMsg;
      } else if (efficiency < 0.8) {
        status = AppLocalizations.of(context)!.metabolismSlow;
        color = Colors.blue;
        msg = AppLocalizations.of(context)!.metabolismSlowMsg;
      }
    } else if (actualWeekLoss > 0.2) {
      status = AppLocalizations.of(context)!.metabolismOnFire;
      color = Colors.deepOrange;
      msg = AppLocalizations.of(context)!.metabolismOnFireMsg;
    }

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.speed, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.metabolismSpeed}: $status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    );
  }

  Widget _buildWeightChart() {
    if (_weightHistory.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noWeightLogs,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spots = _weightHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble());
    }).toList();

    final List<FlSpot> theorySpots = [];
    if (_weightHistory.isNotEmpty) {
      double startWeight = (_weightHistory.first['weight'] as num).toDouble();
      theorySpots.add(FlSpot(0, startWeight));

      double currentTheoretical = startWeight;
      double dailyTarget = (_profile!['daily_calorie_target'] as num?)?.toDouble() ?? 2000;

      for (int i = 0; i < _weeklyStats['calories']!.length - 1; i++) {
        double dayCals = _weeklyStats['calories']![i];
        double diff = (dayCals - dailyTarget) / 7700;
        currentTheoretical += diff;
        theorySpots.add(FlSpot((i + 1).toDouble(), currentTheoretical));
      }
    }

    return FadeInUp(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _weightHistory.length) {
                      final date = DateTime.parse(_weightHistory[value.toInt()]['logged_at']);
                      return Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: theorySpots,
                isCurved: true,
                color: AppColors.primary.withAlpha(100),
                dashArray: [5, 5],
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withAlpha(51),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyCalorieChart() {
    final cals = _weeklyStats['calories']!;
    if (cals.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 3000,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(cals.length, (i) {
              return _makeGroupData(i, cals[i], AppColors.primary);
            }),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 3000,
            color: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBreakdown(int p, int c, int f) {
    return Row(
      children: [
        _buildStatCard(AppLocalizations.of(context)!.nutrient_protein, '${p}g', AppColors.secondary),
        const SizedBox(width: 12),
        _buildStatCard(AppLocalizations.of(context)!.nutrient_carbs, '${c}g', AppColors.primary),
        const SizedBox(width: 12),
        _buildStatCard(AppLocalizations.of(context)!.nutrient_fat, '${f}g', AppColors.accent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
