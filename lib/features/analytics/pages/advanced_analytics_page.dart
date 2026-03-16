import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';

class AdvancedAnalyticsPage extends StatefulWidget {
  const AdvancedAnalyticsPage({super.key});

  @override
  State<AdvancedAnalyticsPage> createState() => _AdvancedAnalyticsPageState();
}

class _AdvancedAnalyticsPageState extends State<AdvancedAnalyticsPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isGenerating = false;
  String _selectedReportType = 'weekly';
  Map<String, dynamic>? _currentReport;
  List<Map<String, dynamic>> _previousReports = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousReports();
  }

  Future<void> _loadPreviousReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _supabaseService.getAnalyticsReports(
        reportType: _selectedReportType,
        limit: 10,
      );
      setState(() {
        _previousReports = reports;
        if (reports.isNotEmpty) {
          _currentReport = reports.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      final report = await _supabaseService.generateAnalyticsReport(
        reportDate: DateTime.now(),
        reportType: _selectedReportType,
      );

      if (report != null) {
        setState(() {
          _currentReport = report;
          _isGenerating = false;
        });
        _loadPreviousReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.analyticsReportSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating report: $e');
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneratingReport(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.advancedAnalytics,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportTypeSelector(),
                  const SizedBox(height: 24),
                  if (_currentReport == null)
                    _buildEmptyState()
                  else
                    _buildReportContent(),
                  const SizedBox(height: 24),
                  _buildPreviousReports(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateReport,
        backgroundColor: AppColors.primary,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.analytics, color: Colors.white),
        label: Text(
          _isGenerating ? l10n.generating : l10n.generateReport,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReportTypeButton('daily', 'Daily'),
          _buildReportTypeButton('weekly', 'Weekly'),
          _buildReportTypeButton('monthly', 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildReportTypeButton(String type, String label) {
    final isSelected = _selectedReportType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReportType = type;
          _currentReport = null;
        });
        _loadPreviousReports();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.noAnalyticsData,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.generateAnalyticsReport,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_currentReport == null) return const SizedBox.shrink();

    final insights = _currentReport!['insights'] as Map<String, dynamic>? ?? {};
    final recommendations = _currentReport!['recommendations'] as List<dynamic>? ?? [];
    final trends = _currentReport!['trends'] as Map<String, dynamic>? ?? {};
    final summary = _currentReport!['summary'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty) ...[
          _buildSummaryCard(summary),
          const SizedBox(height: 20),
        ],
        _buildInsightsSection(insights),
        const SizedBox(height: 20),
        _buildTrendsSection(trends),
        const SizedBox(height: 20),
        _buildRecommendationsSection(recommendations),
      ],
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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
              const Icon(Icons.summarize, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.summary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.insights,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...insights.entries.map((entry) {
          return FadeInUp(
            delay: Duration(milliseconds: entry.key.hashCode % 200),
            child: _buildInsightCard(entry.key, entry.value.toString()),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInsightCard(String category, String content) {
    final icons = {
      'nutrition': Icons.restaurant,
      'exercise': Icons.fitness_center,
      'hydration': Icons.water_drop,
      'sleep': Icons.bedtime,
      'mood': Icons.mood,
      'overall': Icons.insights,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icons[category.toLowerCase()] ?? Icons.info,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(Map<String, dynamic> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.trends,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: trends.entries.map((entry) {
              final trend = entry.value.toString();
              final isUp = trend.contains('up');
              final isDown = trend.contains('down');
              final isStable = trend.contains('stable');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up
                              : (isDown ? Icons.trending_down : Icons.trending_flat),
                          color: isUp
                              ? Colors.green
                              : (isDown ? Colors.red : Colors.grey),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trend.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUp
                                ? Colors.green
                                : (isDown ? Colors.red : Colors.grey),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<dynamic> recommendations) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recommendations,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recommendations.asMap().entries.map((entry) {
          final rec = entry.value as Map<String, dynamic>;
          return FadeInUp(
            delay: Duration(milliseconds: entry.key * 100),
            child: _buildRecommendationCard(rec),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String? ?? 'medium';
    final category = recommendation['category'] as String? ?? 'general';
    final title = recommendation['title'] as String? ?? 'Recommendation';
    final description = recommendation['description'] as String? ?? '';
    final actionable = recommendation['actionable'] as String? ?? '';

    Color priorityColor;
    if (priority == 'high') {
      priorityColor = Colors.red;
    } else if (priority == 'medium') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (actionable.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionable,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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

  Widget _buildPreviousReports() {
    if (_previousReports.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.previousReports,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._previousReports.skip(1).map((report) {
          final date = report['report_date'] as String? ?? '';
          return ListTile(
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: Text(AppLocalizations.of(context)!.reportTypeReport(report['report_type']?.toString() ?? '')),
            subtitle: Text(date),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() => _currentReport = report);
            },
          );
        }).toList(),
      ],
    );
  }
}


