import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:flow/l10n/app_localizations.dart';

class FastingHistoryPage extends StatefulWidget {
  const FastingHistoryPage({super.key});
  @override
  State<FastingHistoryPage> createState() => _FastingHistoryPageState();
}

class _FastingHistoryPageState extends State<FastingHistoryPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  double _avgDuration = 0;
  int _longestFast = 0;
  int _totalFasts = 0;
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _supabaseService.getFastingHistory();
    double totalMin = 0;
    int maxMin = 0;
    for (var log in history) {
      final duration = log['duration_minutes'] as int;
      totalMin += duration;
      if (duration > maxMin) maxMin = duration;
    }
    if (history.isNotEmpty) {
      _avgDuration = (totalMin / history.length) / 60;
    }
    if (mounted) {
      setState(() {
        _history = history;
        _totalFasts = history.length;
        _longestFast = (maxMin / 60).round();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.fastingHistory,
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
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final log = _history[index];
                      final start = DateTime.parse(log['start_time']).toLocal();
                      final durationMin = log['duration_minutes'] as int;
                      final hours = durationMin ~/ 60;
                      final mins = durationMin % 60;
                      return FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: Duration(milliseconds: index * 50),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt,
                                color: Colors.purple,
                              ),
                            ),
                            title: Text(
                              '${hours}h ${mins}m ${AppLocalizations.of(context)!.fast}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(start),
                            ),
                            trailing: const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            AppLocalizations.of(context)!.totalFasts,
            '$_totalFasts',
          ),
          _buildStatItem(
            AppLocalizations.of(context)!.avgDuration,
            '${_avgDuration.toStringAsFixed(1)}h',
          ),
          _buildStatItem(
            AppLocalizations.of(context)!.longestFast,
            '${_longestFast}h',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
