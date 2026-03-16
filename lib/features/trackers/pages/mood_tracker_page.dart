import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animate_do/animate_do.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _moodLogs = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Map<String, dynamic>> _moodDataMap = {};

  final Map<String, Color> _moodColors = {
    'very_happy': Colors.yellow,
    'happy': Colors.green,
    'neutral': Colors.grey,
    'sad': Colors.blue,
    'very_sad': Colors.indigo,
    'anxious': Colors.orange,
    'stressed': Colors.red,
    'calm': Colors.teal,
    'energetic': Colors.amber,
    'tired': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _supabaseService.getMoodLogs();
      setState(() {
        _moodLogs = logs;
        _moodDataMap = {
          for (var log in logs)
            DateTime.parse(log['log_date'] as String): log,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading mood data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogMoodDialog() async {
    final now = DateTime.now();
    String? mood;
    int? moodScore;
    int? energyLevel;
    int? stressLevel;
    List<String> activities = [];
    String? notes;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MoodLogDialog(),
    );

    if (result != null) {
      mood = result['mood'] as String?;
      moodScore = result['mood_score'] as int?;
      energyLevel = result['energy_level'] as int?;
      stressLevel = result['stress_level'] as int?;
      activities = (result['activities'] as List<dynamic>?)?.cast<String>() ?? [];
      notes = result['notes'] as String?;

      await _supabaseService.logMood(
        logDate: _selectedDay ?? now,
        mood: mood,
        moodScore: moodScore,
        energyLevel: energyLevel,
        stressLevel: stressLevel,
        activities: activities,
        notes: notes,
      );

      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.moodLoggedSuccess),
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
                        _buildTodayMood(),
                        const SizedBox(height: 24),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildCalendar(),
                        const SizedBox(height: 24),
                        _buildMoodChart(),
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
        onPressed: _showLogMoodDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.mood, color: Colors.white),
        label: Text(
          l10n.logMood,
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
          AppLocalizations.of(context)!.moodTracker,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('😊', style: TextStyle(fontSize: 80)),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMood() {
    final today = DateTime.now();
    final todayLog = _moodDataMap[DateTime(today.year, today.month, today.day)];

    if (todayLog == null) {
      return Container(
        padding: const EdgeInsets.all(24),
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
            const Text('😊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.howAreYouFeeling,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.logYourMoodToday,
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

    final mood = todayLog['mood'] as String?;
    final score = (todayLog['mood_score'] as num?)?.toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _moodColors[mood ?? 'neutral'] ?? Colors.grey,
            (_moodColors[mood ?? 'neutral'] ?? Colors.grey).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(_getMoodEmoji(mood), style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMoodLabel(mood),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (score != null)
                  Text(
                    'Score: $score/10',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_moodLogs.isEmpty) return const SizedBox.shrink();

    final last7Days = _moodLogs.take(7).toList();
    final avgMood = last7Days
            .where((log) => log['mood_score'] != null)
            .map((log) => (log['mood_score'] as num).toInt())
            .fold(0.0, (sum, s) => sum + s) /
        (last7Days.where((log) => log['mood_score'] != null).length);
    final avgEnergy = last7Days
            .where((log) => log['energy_level'] != null)
            .map((log) => (log['energy_level'] as num).toInt())
            .fold(0.0, (sum, e) => sum + e) /
        (last7Days.where((log) => log['energy_level'] != null).length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Mood',
            avgMood.toStringAsFixed(1),
            Icons.mood,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Energy',
            avgEnergy.toStringAsFixed(1),
            Icons.bolt,
            Colors.orange,
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
          return _moodDataMap[DateTime(day.year, day.month, day.day)] != null
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
            color: Colors.purple,
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

  Widget _buildMoodChart() {
    if (_moodLogs.isEmpty) return const SizedBox.shrink();

    final last14Days = _moodLogs.take(14).toList().reversed.toList();

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
            AppLocalizations.of(context)!.moodTrends,
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
                      final score = (entry.value['mood_score'] as num?)?.toInt() ?? 5;
                      return FlSpot(entry.key.toDouble(), score.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.1),
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
    if (_moodLogs.isEmpty) return const SizedBox.shrink();

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
        ..._moodLogs.take(5).map((log) => _buildMoodLogCard(log)),
      ],
    );
  }

  Widget _buildMoodLogCard(Map<String, dynamic> log) {
    final date = DateTime.parse(log['log_date'] as String);
    final mood = log['mood'] as String?;
    final score = (log['mood_score'] as num?)?.toInt();

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
              color: (_moodColors[mood ?? 'neutral'] ?? Colors.grey)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getMoodEmoji(mood),
              style: const TextStyle(fontSize: 24),
            ),
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
                Text(
                  _getMoodLabel(mood),
                  style: TextStyle(
                    color: _moodColors[mood ?? 'neutral'] ?? Colors.grey,
                    fontSize: 14,
                  ),
                ),
                if (score != null)
                  Text(
                    'Score: $score/10',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'very_happy':
        return '😄';
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😢';
      case 'very_sad':
        return '😭';
      case 'anxious':
        return '😰';
      case 'stressed':
        return '😓';
      case 'calm':
        return '😌';
      case 'energetic':
        return '⚡';
      case 'tired':
        return '😴';
      default:
        return '😊';
    }
  }

  String _getMoodLabel(String? mood) {
    switch (mood) {
      case 'very_happy':
        return 'Very Happy';
      case 'happy':
        return 'Happy';
      case 'neutral':
        return 'Neutral';
      case 'sad':
        return 'Sad';
      case 'very_sad':
        return 'Very Sad';
      case 'anxious':
        return 'Anxious';
      case 'stressed':
        return 'Stressed';
      case 'calm':
        return 'Calm';
      case 'energetic':
        return 'Energetic';
      case 'tired':
        return 'Tired';
      default:
        return 'Not logged';
    }
  }
}

class _MoodLogDialog extends StatefulWidget {
  @override
  State<_MoodLogDialog> createState() => _MoodLogDialogState();
}

class _MoodLogDialogState extends State<_MoodLogDialog> {
  String? _selectedMood;
  int? _moodScore;
  int? _energyLevel;
  int? _stressLevel;
  final List<String> _selectedActivities = [];
  final _notesController = TextEditingController();

  final List<String> _moods = [
    'very_happy',
    'happy',
    'neutral',
    'sad',
    'very_sad',
    'anxious',
    'stressed',
    'calm',
    'energetic',
    'tired',
  ];

  final List<String> _activities = [
    'Exercise',
    'Work',
    'Social',
    'Rest',
    'Meal',
    'Meditation',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.logMood),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.howAreYouFeeling),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final emoji = _getMoodEmoji(mood);
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.moodScore),
            Slider(
              value: (_moodScore ?? 5).toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_moodScore ?? 5}',
              onChanged: (value) {
                setState(() => _moodScore = value.toInt());
              },
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.energyLevel),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.battery_charging_full,
                    color: _energyLevel != null && index < _energyLevel!
                        ? Colors.green
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _energyLevel = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.stressLevel),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.warning,
                    color: _stressLevel != null && index < _stressLevel!
                        ? Colors.red
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _stressLevel = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.activities),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activities.map((activity) {
                final isSelected = _selectedActivities.contains(activity);
                return FilterChip(
                  label: Text(activity),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedActivities.add(activity);
                      } else {
                        _selectedActivities.remove(activity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
              'mood': _selectedMood,
              'mood_score': _moodScore,
              'energy_level': _energyLevel,
              'stress_level': _stressLevel,
              'activities': _selectedActivities,
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

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'very_happy':
        return '😄';
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😢';
      case 'very_sad':
        return '😭';
      case 'anxious':
        return '😰';
      case 'stressed':
        return '😓';
      case 'calm':
        return '😌';
      case 'energetic':
        return '⚡';
      case 'tired':
        return '😴';
      default:
        return '😊';
    }
  }
}

