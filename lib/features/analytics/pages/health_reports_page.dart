import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/l10n/app_localizations.dart';

class HealthReportsPage extends StatefulWidget {
  const HealthReportsPage({super.key});

  @override
  State<HealthReportsPage> createState() => _HealthReportsPageState();
}

class _HealthReportsPageState extends State<HealthReportsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Map<String, double> _nutrients = {};

  final List<String> _radarMetrics = [
    'calcium',
    'iron',
    'magnesium',
    'zinc',
    'vitamin_c',
    'vitamin_d',
    'vitamin_b12',
    'fiber',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getDailyMicronutrients(DateTime.now());
      if (mounted) {
        setState(() {
          _nutrients = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading health report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.advancedHealthInsights, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(AppLocalizations.of(context)!.micronutrientRadar),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.micronutrientRadarDesc, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildRadarChart(),
                  const SizedBox(height: 40),
                  _buildSectionTitle(AppLocalizations.of(context)!.nastiesWatchdog),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.nastiesWatchdogDesc, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildNastiesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildRadarChart() {
    if (_nutrients.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(child: Text(AppLocalizations.of(context)!.noDataLoggedToday)),
      );
    }

    final rda = NutritionUtils.microNutrientRDA;
    
    // Calculate normalized values (capped at 1.0 for chart, but actual value for display)
    final values = _radarMetrics.map((key) {
      final current = _nutrients[key] ?? 0.0;
      final target = rda[key] ?? 1.0;
      final pct = current / target;
      return pct > 1.0 ? 1.0 : pct;
    }).toList();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
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
          titleTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
          getTitle: (index, angle) {
            final key = _radarMetrics[index];
            switch (key) {
              case 'vitamin_c': return RadarChartTitle(text: 'Vit C');
              case 'vitamin_d': return RadarChartTitle(text: 'Vit D');
              case 'vitamin_b12': return RadarChartTitle(text: 'B12');
              case 'calcium': return RadarChartTitle(text: 'Calcium');
              case 'iron': return RadarChartTitle(text: 'Iron');
              case 'magnesium': return RadarChartTitle(text: 'Magnesium');
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
    );
  }

  Widget _buildNastiesList() {
    final thresholds = NutritionUtils.nutrientWarningThresholds;
    
    return Column(
      children: thresholds.entries.map((entry) {
        final key = entry.key;
        final data = entry.value;
        final limit = (data['limit'] as num).toDouble();
        
        final current = _nutrients[key] ?? 0.0;
        final isHigh = current > limit;
        final pct = (current / limit).clamp(0.0, 1.5); // Cap at 150% for display

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHigh ? Colors.red.withOpacity(0.3) : Colors.transparent),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatName(key), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${current.toInt()} / ${limit.toInt()}${key == 'sodium' ? 'mg' : 'g'}',
                    style: TextStyle(
                      color: isHigh ? Colors.red : Colors.green, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct > 1.0 ? 1.0 : pct,
                  backgroundColor: Colors.grey[100],
                  color: isHigh ? Colors.red : Colors.green,
                  minHeight: 12,
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
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['message'] as String,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
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
    );
  }

  String _formatName(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }
}
