import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animate_do/animate_do.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _sleepLogs = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Map<String, dynamic>> _sleepDataMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _supabaseService.getSleepLogs();
      setState(() {
        _sleepLogs = logs;
        _sleepDataMap = {
          for (var log in logs)
            DateTime.parse(log['sleep_date'] as String): log,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sleep data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogSleepDialog() async {
    final now = DateTime.now();
    DateTime? bedtime;
    DateTime? wakeTime;
    int? qualityRating;
    double? durationHours;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SleepLogDialog(
        initialBedtime: bedtime,
        initialWakeTime: wakeTime,
        initialQuality: qualityRating,
      ),
    );

    if (result != null) {
      bedtime = result['bedtime'] as DateTime?;
      wakeTime = result['wake_time'] as DateTime?;
      qualityRating = result['quality'] as int?;
      final notes = result['notes'] as String?;

      if (bedtime != null && wakeTime != null) {
        durationHours = wakeTime.difference(bedtime).inMinutes / 60.0;
      } else if (result['duration'] != null) {
        durationHours = (result['duration'] as num).toDouble();
      }

      await _supabaseService.logSleep(
        sleepDate: _selectedDay ?? now,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationHours: durationHours,
        qualityRating: qualityRating,
        notes: notes,
      );

      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sleepLoggedSuccess),
            backgroundColor: Colors.green,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildCalendar(),
                        const SizedBox(height: 24),
                        _buildSleepChart(),
                        const SizedBox(height: 24),
                        _buildRecentLogs(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogSleepDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.bedtime, color: Colors.white),
        label: Text(
          l10n.logSleep,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppLocalizations.of(context)!.sleepTracker,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Colors.indigo.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('😴', style: TextStyle(fontSize: 80)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_sleepLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text('😴', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noSleepData,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.startLoggingSleep,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final last7Days = _sleepLogs.take(7).toList();
    final avgDuration = last7Days
            .where((log) => log['duration_hours'] != null)
            .map((log) => (log['duration_hours'] as num).toDouble())
            .fold(0.0, (sum, d) => sum + d) /
        (last7Days.where((log) => log['duration_hours'] != null).length);
    final avgQuality = last7Days
            .where((log) => log['quality_rating'] != null)
            .map((log) => (log['quality_rating'] as num).toInt())
            .fold(0.0, (sum, q) => sum + q) /
        (last7Days.where((log) => log['quality_rating'] != null).length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Sleep',
            '${avgDuration.toStringAsFixed(1)}h',
            Icons.bedtime,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Quality',
            avgQuality.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          return _sleepDataMap[DateTime(day.year, day.month, day.day)] != null
              ? [1]
              : [];
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildSleepChart() {
    if (_sleepLogs.isEmpty) return const SizedBox.shrink();

    final last14Days = _sleepLogs.take(14).toList().reversed.toList();

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
            AppLocalizations.of(context)!.sleepTrends,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: last14Days.asMap().entries.map((entry) {
                      final duration = (entry.value['duration_hours'] as num?)?.toDouble() ?? 0.0;
                      return FlSpot(entry.key.toDouble(), duration);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs() {
    if (_sleepLogs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recentLogs,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._sleepLogs.take(5).map((log) => _buildSleepLogCard(log)),
      ],
    );
  }

  Widget _buildSleepLogCard(Map<String, dynamic> log) {
    final date = DateTime.parse(log['sleep_date'] as String);
    final duration = (log['duration_hours'] as num?)?.toDouble() ?? 0.0;
    final quality = (log['quality_rating'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bedtime, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (duration > 0) ...[
                      Text('${duration.toStringAsFixed(1)}h'),
                      const SizedBox(width: 16),
                    ],
                    if (quality != null) ...[
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < quality
                                ? Colors.amber
                                : Colors.grey[300],
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepLogDialog extends StatefulWidget {
  final DateTime? initialBedtime;
  final DateTime? initialWakeTime;
  final int? initialQuality;

  const _SleepLogDialog({
    this.initialBedtime,
    this.initialWakeTime,
    this.initialQuality,
  });

  @override
  State<_SleepLogDialog> createState() => _SleepLogDialogState();
}

class _SleepLogDialogState extends State<_SleepLogDialog> {
  DateTime? _bedtime;
  DateTime? _wakeTime;
  int? _quality;
  double? _duration;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.logSleep),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.bedtime),
              trailing: Text(_bedtime != null
                  ? '${_bedtime!.hour}:${_bedtime!.minute.toString().padLeft(2, '0')}'
                  : AppLocalizations.of(context)!.notSet),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _bedtime != null
                      ? TimeOfDay.fromDateTime(_bedtime!)
                      : TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    final now = DateTime.now();
                    _bedtime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.wakeTime),
              trailing: Text(_wakeTime != null
                  ? '${_wakeTime!.hour}:${_wakeTime!.minute.toString().padLeft(2, '0')}'
                  : AppLocalizations.of(context)!.notSet),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _wakeTime != null
                      ? TimeOfDay.fromDateTime(_wakeTime!)
                      : TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    final now = DateTime.now();
                    _wakeTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      time.hour,
                      time.minute,
                    );
                    if (_bedtime != null) {
                      _duration = _wakeTime!.difference(_bedtime!).inMinutes / 60.0;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.enterDurationManually),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.hoursHint,
                labelText: AppLocalizations.of(context)!.durationLabel,
              ),
              onChanged: (value) {
                _duration = double.tryParse(value);
              },
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.sleepQuality),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: _quality != null && index < _quality!
                        ? Colors.amber
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _quality = index + 1);
                  },
                );
              }),
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.notesOptional,
                labelText: AppLocalizations.of(context)!.notes,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'bedtime': _bedtime,
              'wake_time': _wakeTime,
              'duration': _duration,
              'quality': _quality,
              'notes': _notesController.text.isEmpty
                  ? null
                  : _notesController.text,
            });
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}

