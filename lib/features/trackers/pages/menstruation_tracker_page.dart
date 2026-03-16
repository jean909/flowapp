import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import 'package:flow/l10n/app_localizations.dart';

class MenstruationTrackerPage extends StatefulWidget {
  const MenstruationTrackerPage({super.key});

  @override
  State<MenstruationTrackerPage> createState() => _MenstruationTrackerPageState();
}

class _MenstruationTrackerPageState extends State<MenstruationTrackerPage> with TickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  int _cycleDay = 0;
  int _daysUntilNext = 0;
  String _currentPhase = 'Follicular';
  List<Map<String, dynamic>> _symptomHistory = [];
  List<Map<String, dynamic>> _todayMealLogs = [];
  Map<String, double> _micronutrientActuals = {};
  Map<String, List<dynamic>> _micronutrientRequirements = {};
  double _cycleRegularity = 1.0;
  int _avgCycleLength = 28;
  late AnimationController _phaseAnimationController;

  @override
  void initState() {
    super.initState();
    _phaseAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _phaseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final setup = await _supabaseService.getMenstruationSetup();
      if (setup != null) {
        final cycleInfo = _supabaseService.calculateCycleInfo(setup);
        final logs = await _supabaseService.getMenstruationLogs(limit: 12);
        final symptomHistory = await _supabaseService.getSymptomHistory(limit: 10);
        final mealLogs = await _supabaseService.getDailyMealLogs(DateTime.now());
        final requirements = _calculateMicronutrientRequirements(cycleInfo['currentPhase']?.toString() ?? 'Unknown');
        final actuals = _calculateActualMicronutrients(mealLogs, requirements);
        final stats = _calculateCycleStats(logs, (setup['average_cycle_length'] as num?)?.toInt() ?? 28);

        setState(() {
          _cycleDay = (cycleInfo['cycleDay'] as num?)?.toInt() ?? 0;
          _daysUntilNext = (cycleInfo['daysUntilNext'] as num?)?.toInt() ?? 0;
          _currentPhase = cycleInfo['currentPhase']?.toString() ?? 'Unknown';
          _logs = logs;
          _symptomHistory = symptomHistory;
          _todayMealLogs = mealLogs;
          _micronutrientRequirements = requirements;
          _micronutrientActuals = actuals;
          _avgCycleLength = (stats['avg'] as num?)?.toInt() ?? 28;
          _cycleRegularity = (stats['regularity'] as num?)?.toDouble() ?? 1.0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          // Navigator.pop(context); // Do not pop, just show empty state
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
                  _buildWellnessScore(),
                  const SizedBox(height: 20),
                  _buildCycleTrends(),
                  const SizedBox(height: 20),
                  _buildHormoneGraph(),
                  const SizedBox(height: 20),
                  _buildCycleOverviewCard(),
                  const SizedBox(height: 20),
                  _buildPhaseCard(),
                  const SizedBox(height: 20),
                  _buildCalendarCard(), // Ensure no args here if method takes none?
                  const SizedBox(height: 20),
                  _buildSymptomTracker(),
                  const SizedBox(height: 20),
                  _buildSymptomHistory(),
                  const SizedBox(height: 20),
                  _buildMicronutritionInsight(),
                  const SizedBox(height: 20),
                  _buildPhaseRecommendations(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogPeriodDialog,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.logPeriod, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFE91E63),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(l10n.cycleTracker, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat(l10n.day(_cycleDay), '$_cycleDay', Icons.calendar_today),
                  Container(width: 1, height: 60, color: Colors.white30),
                  _buildHeaderStat(l10n.nextIn, '$_daysUntilNext days', Icons.event),
                  Container(width: 1, height: 60, color: Colors.white30),
                  _buildHeaderStat(l10n.phase, _currentPhase == 'Follicular' ? l10n.follicular : (_currentPhase == 'Menstrual' ? l10n.menstrual : (_currentPhase == 'Ovulation' ? l10n.ovulation : l10n.luteal)), Icons.auto_awesome),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showSettingsDialog)],
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildCycleOverviewCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF48FB1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.currentCycle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(AppLocalizations.of(context)!.daysAvg, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _CyclePainter(_cycleDay, 28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_cycleDay', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    Text(l10n.dayOfCycle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard() {
    final l10n = AppLocalizations.of(context)!;
    final phases = [
      {'name': 'Menstrual', 'icon': '🩸', 'color': const Color(0xFFE57373)},
      {'name': 'Follicular', 'icon': '🌱', 'color': const Color(0xFF81C784)},
      {'name': 'Ovulation', 'icon': '✨', 'color': const Color(0xFFFFD54F)},
      {'name': 'Luteal', 'icon': '🌙', 'color': const Color(0xFF9575CD)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cyclePhases, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: phases.map((phase) {
              final isActive = phase['name'] == _currentPhase;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive ? (phase['color'] as Color).withOpacity(0.2) : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: isActive ? Border.all(color: phase['color'] as Color, width: 3) : null,
                    ),
                    child: Text(phase['icon'] as String, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phase['name'] == 'Menstrual' ? l10n.menstrual : (phase['name'] == 'Follicular' ? l10n.follicular : (phase['name'] == 'Ovulation' ? l10n.ovulation : l10n.luteal)),
                    style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? phase['color'] as Color : AppColors.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabaseService.getMenstruationSetup(),
      builder: (context, snapshot) {
        final setup = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.calendar, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) => setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) => _buildCalendarDay(day, setup),
                  todayBuilder: (context, day, focusedDay) => _buildCalendarDay(day, setup, isToday: true),
                  selectedBuilder: (context, day, focusedDay) => _buildCalendarDay(day, setup, isSelected: true),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: const Color(0xFFE91E63).withOpacity(0.3), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
              const SizedBox(height: 16),
              // Legend
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.cyclePhases, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildLegendItem(const Color(0xFFE57373), AppLocalizations.of(context)!.menstrual, '🩸'), _buildLegendItem(const Color(0xFF81C784), AppLocalizations.of(context)!.fertile, '🌱'), _buildLegendItem(const Color(0xFFFFD54F), AppLocalizations.of(context)!.ovulation, '✨'), _buildLegendItem(const Color(0xFF9575CD), AppLocalizations.of(context)!.luteal, '🌙')])])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, String emoji) {
    return Column(children: [Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 12)))), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10))]);
  }

  Widget _buildCalendarDay(DateTime day, Map<String, dynamic>? setup, {bool isToday = false, bool isSelected = false}) {
    if (setup == null) return Center(child: Text('${day.day}', style: const TextStyle(fontSize: 14)));
    final lastPeriodStr = setup['last_period_start'] as String?;
    if (lastPeriodStr == null) return Center(child: Text('${day.day}', style: const TextStyle(fontSize: 14)));

    final lastPeriod = DateTime.parse(lastPeriodStr);
    final cycleLength = setup['average_cycle_length'] as int? ?? 28;
    final periodLength = setup['average_period_length'] as int? ?? 5;
    final daysSinceLastPeriod = day.difference(lastPeriod).inDays;
    final cycleDay = (daysSinceLastPeriod % cycleLength) + 1;

    Color? backgroundColor;
    Color textColor = Colors.black;

    if (cycleDay <= periodLength) {
      backgroundColor = const Color(0xFFE57373).withOpacity(0.3);
    } else if (cycleDay >= 11 && cycleDay <= 16) {
      if (cycleDay == 14) {
        backgroundColor = const Color(0xFFFFD54F);
      } else {
        backgroundColor = const Color(0xFF81C784).withOpacity(0.3);
      }
    } else if (cycleDay > 16) {
      backgroundColor = const Color(0xFF9575CD).withOpacity(0.2);
    }
    
    if (isSelected) {
      backgroundColor = const Color(0xFFE91E63);
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = backgroundColor?.withOpacity(0.8) ?? const Color(0xFFE91E63).withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: isToday && !isSelected ? Border.all(color: const Color(0xFFE91E63), width: 2) : null),
      child: Center(child: Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal, color: textColor))),
    );
  }

  Widget _buildSymptomTracker() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabaseService.getSymptomsForDate(DateTime.now()),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final selectedSymptoms = List<String>.from(snapshot.data?['symptoms'] as List? ?? []);
        final smartSymptoms = ['Cramps', 'Headache', 'Mood Swings', 'Fatigue', 'Bloating', 'Acne'];
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(l10n.todaysSymptoms, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE91E63)), onPressed: () => _showAddCustomSymptomDialog(selectedSymptoms)),
            ]),
            const SizedBox(height: 8),
            Text(l10n.smartSuggestions, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: smartSymptoms.map((symptom) {
              final isSelected = selectedSymptoms.contains(symptom);
              return FilterChip(
                label: Row(mainAxisSize: MainAxisSize.min, children: [Text(_getSymptomEmoji(symptom), style: const TextStyle(fontSize: 16)), const SizedBox(width: 4), Text(symptom == 'Cramps' ? l10n.cramps : (symptom == 'Headache' ? l10n.headache : (symptom == 'Mood Swings' ? l10n.moodSwings : (symptom == 'Fatigue' ? l10n.fatigue : (symptom == 'Bloating' ? l10n.bloating : (symptom == 'Acne' ? l10n.acne : symptom))))))]),
                selected: isSelected,
                onSelected: (selected) async {
                  final newSymptoms = List<String>.from(selectedSymptoms);
                  if (selected) {
                    newSymptoms.add(symptom);
                  } else {
                    newSymptoms.remove(symptom);
                  }
                  await _supabaseService.saveSymptoms(date: DateTime.now(), symptoms: newSymptoms);
                  setState(() {});
                },
                selectedColor: const Color(0xFFE91E63).withOpacity(0.2),
                checkmarkColor: const Color(0xFFE91E63),
              );
            }).toList()),
            if (selectedSymptoms.any((s) => !smartSymptoms.contains(s))) ...[
              const SizedBox(height: 16),
              Text(l10n.customSymptoms, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: selectedSymptoms.where((s) => !smartSymptoms.contains(s)).map((symptom) => Chip(
                label: Text(symptom), deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () async {
                  final newSymptoms = List<String>.from(selectedSymptoms); newSymptoms.remove(symptom);
                  await _supabaseService.saveSymptoms(date: DateTime.now(), symptoms: newSymptoms);
                  setState(() {});
                },
                backgroundColor: Colors.purple[100],
              )).toList()),
            ],
          ]),
        );
      },
    );
  }

  String _getSymptomEmoji(String symptom) {
    switch (symptom) {
      case 'Cramps': return '😣';
      case 'Headache': return '🤕';
      case 'Mood Swings': return '😤';
      case 'Fatigue': return '😴';
      case 'Bloating': return '🎈';
      case 'Acne': return '🔴';
      default: return '💊';
    }
  }

  void _showAddCustomSymptomDialog(List<String> currentSymptoms) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.addCustomSymptom),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: AppLocalizations.of(context)!.enterSymptomName, border: const OutlineInputBorder()), textCapitalization: TextCapitalization.words),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(onPressed: () async {
          if (controller.text.trim().isNotEmpty) {
            final newS = List<String>.from(currentSymptoms)..add(controller.text.trim());
            await _supabaseService.saveSymptoms(date: DateTime.now(), symptoms: newS);
            Navigator.pop(context); setState(() {});
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)), child: Text(AppLocalizations.of(context)!.add)),
      ],
    ));
  }

  void _showLogPeriodDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.logPeriod),
      content: Text(AppLocalizations.of(context)!.markPeriodStart),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(onPressed: () async {
          try {
            await _supabaseService.logPeriod(periodStart: DateTime.now(), flowIntensity: 'medium');
            final setup = await _supabaseService.getMenstruationSetup();
            if (setup != null) await _supabaseService.saveMenstruationSetup(lastPeriodStart: DateTime.now(), averageCycleLength: setup['average_cycle_length'] ?? 28, averagePeriodLength: setup['average_period_length'] ?? 5);
            Navigator.pop(context); ScrumptiousOf(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.periodLogged)));
            _loadData();
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())), backgroundColor: Colors.red));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)), child: Text(AppLocalizations.of(context)!.log)),
      ],
    ));
  }
  
  ScaffoldMessengerState ScrumptiousOf(BuildContext context) => ScaffoldMessenger.of(context);

  Widget _buildPhaseRecommendations() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabaseService.getMenstruationSetup(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final cycleInfo = _supabaseService.calculateCycleInfo(snapshot.data!);
        final phase = cycleInfo['currentPhase'] as String;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context)!.cycleRoadmap, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCycleTimeline(cycleInfo['cycleDay'] as int, cycleInfo),
          const SizedBox(height: 20),
          _buildWaterInsight(phase),
          const SizedBox(height: 20),
          _buildExerciseInsight(phase),
          const SizedBox(height: 24),
          _buildPhaseInfoCard(phase, cycleInfo),
          const SizedBox(height: 20),
          _buildNutritionRecommendations(phase),
        ]);
      },
    );
  }

  Widget _buildWaterInsight(String phase) {
    String message = 'Drink plenty of water today.';
    double progress = 0.5;
    if (phase == 'Menstrual') { message = 'Hydration helps with cramps and bloating. Aim for 2.5L-3L.'; progress = 0.8; }
    else if (phase == 'Follicular') { message = 'Stay consistent with 2L. Your energy is rising!'; progress = 0.65; }
    else if (phase == 'Ovulation') { message = 'High energy needs high hydration! Keep a bottle nearby.'; progress = 0.75; }
    else if (phase == 'Luteal') { message = 'Reducing salt and increasing water can help with PMS.'; progress = 0.9; }

    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.water_drop, color: Colors.blue), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.hydrationTip, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), Text(message, style: const TextStyle(fontSize: 14)), const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.blue.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), minHeight: 8))]));
  }

  Widget _buildExerciseInsight(String phase) {
    String activity = 'Light Movement'; IconData icon = Icons.directions_walk; String detail = 'Stay active as per your comfort level.';
    if (phase == 'Menstrual') { activity = 'Gentle Yoga / Walking'; icon = Icons.self_improvement; detail = 'Focus on stretching and relaxation to ease discomfort.'; }
    else if (phase == 'Follicular') { activity = 'HIIT / Strength Training'; icon = Icons.fitness_center; detail = 'New energy! Great for muscle building and intense cardio.'; }
    else if (phase == 'Ovulation') { activity = 'Outdoor Running / Group Sports'; icon = Icons.directions_run; detail = 'You are at your peak performance. Push your limits!'; }
    else if (phase == 'Luteal') { activity = 'Light Cardio / Pilates'; icon = Icons.pool; detail = 'Listen to your body. Focus on consistency over intensity.'; }
    
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.orange, size: 32)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.dailyExercise, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(activity, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))]))]));
  }

  Widget _buildCycleTimeline(int currentDay, Map<String, dynamic> cycleInfo) {
    const double timelineHeight = 8.0;
    final double availableWidth = math.min(MediaQuery.of(context).size.width - 80, 500);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AppLocalizations.of(context)!.dayLabel(currentDay), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(AppLocalizations.of(context)!.daysUntilNext((cycleInfo['daysUntilNext'] as num?)?.toInt() ?? 0), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))]),
        const SizedBox(height: 24),
        SizedBox(height: 20, child: Stack(clipBehavior: Clip.none, children: [
          Container(height: timelineHeight, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
          Positioned(left: 0, top: 0, child: Container(height: timelineHeight, width: (5 / 28) * availableWidth, decoration: const BoxDecoration(color: Color(0xFFE57373), borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4))))),
          Positioned(left: (10 / 28) * availableWidth, top: 0, child: Container(height: timelineHeight, width: (6 / 28) * availableWidth, color: const Color(0xFF81C784).withOpacity(0.5))),
          Positioned(left: (13 / 28) * availableWidth, top: -2, child: Container(height: 12, width: 4, color: const Color(0xFFFFD54F))),
          Positioned(left: math.max(0, ((currentDay - 1) / 28) * availableWidth - 8), top: -4, child: Container(height: 16, width: 16, decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]), child: Center(child: Container(height: 6, width: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))))),
        ])),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AppLocalizations.of(context)!.timelineStart, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), Text(AppLocalizations.of(context)!.timelineFertile, style: const TextStyle(fontSize: 10, color: Color(0xFF81C784), fontWeight: FontWeight.bold)), Text(AppLocalizations.of(context)!.timelineOvulation, style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)), Text(AppLocalizations.of(context)!.timelineEnd, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
      ]),
    );
  }

  Widget _buildPhaseInfoCard(String phase, Map<String, dynamic> cycleInfo) {
    Map<String, dynamic> phaseData = {'emoji': '❓', 'colors': [Colors.grey, Colors.grey], 'description': 'Unknown', 'tips': []};
    if (phase == 'Menstrual') {
      phaseData = {'emoji': '🩸', 'colors': [const Color(0xFFE57373), const Color(0xFFEF5350)], 'description': 'Rest and restore your body', 'tips': ['Stay hydrated', 'Gentle exercise', 'Iron-rich foods']};
    } else if (phase == 'Follicular') phaseData = {'emoji': '🌱', 'colors': [const Color(0xFF81C784), const Color(0xFF66BB6A)], 'description': 'Energy is rising', 'tips': ['Great for new projects', 'Higher energy workouts', 'Protein & complex carbs']};
    else if (phase == 'Ovulation') phaseData = {'emoji': '✨', 'colors': [const Color(0xFFFFD54F), const Color(0xFFFFCA28)], 'description': 'Peak energy', 'tips': ['Most fertile window', 'Peak performance', 'Social activities']};
    else if (phase == 'Luteal') phaseData = {'emoji': '🌙', 'colors': [const Color(0xFF9575CD), const Color(0xFF7E57C2)], 'description': 'Prepare for next cycle', 'tips': ['Self-care', 'Magnesium-rich foods']};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: phaseData['colors'] as List<Color>, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(phaseData['emoji'], style: const TextStyle(fontSize: 32)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.phasePhase(phase), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(phaseData['description'], style: const TextStyle(color: Colors.white70, fontSize: 13))]))]),
        const SizedBox(height: 16),
        ...(phaseData['tips'] as List).map((tip) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle, color: Colors.white70, size: 16), const SizedBox(width: 8), Expanded(child: Text(tip, style: const TextStyle(color: Colors.white, fontSize: 13)))]))).toList(),
      ]),
    );
  }

  Widget _buildNutritionRecommendations(String phase) {
    List<Map<String, String>> recommendations = [];
    if (phase == 'Menstrual') {
      recommendations = [{'emoji': '🥩', 'name': 'Red Meat'}, {'emoji': '🥬', 'name': 'Spinach'}, {'emoji': '🫘', 'name': 'Lentils'}];
    } else if (phase == 'Follicular') recommendations = [{'emoji': '🥚', 'name': 'Eggs'}, {'emoji': '🥑', 'name': 'Avocado'}, {'emoji': '🐟', 'name': 'Salmon'}];
    else if (phase == 'Ovulation') recommendations = [{'emoji': '🥗', 'name': 'Leafy Greens'}, {'emoji': '🍓', 'name': 'Berries'}, {'emoji': '🌰', 'name': 'Almonds'}];
    else if (phase == 'Luteal') recommendations = [{'emoji': '🍌', 'name': 'Bananas'}, {'emoji': '🥔', 'name': 'Sweet Potato'}, {'emoji': '🌾', 'name': 'Whole Grains'}];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.restaurant_menu, color: Color(0xFFE91E63)), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.nutritionRecommendations, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.foodsToFocusOnPhase(phase), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: recommendations.map((food) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE91E63).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(food['emoji']!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(food['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]))).toList()),
      ]),
    );
  }

  Widget _buildMicronutritionInsight() {
    if (_micronutrientRequirements.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.biotech, color: Color(0xFFE91E63)), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.micronutrientInsight, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.yourBodyNeedsPhase(_currentPhase), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        ..._micronutrientRequirements.entries.map((entry) {
          final name = entry.key; final target = entry.value[0] as double; final unit = entry.value[1] as String;
          final actual = _micronutrientActuals[name] ?? 0.0; final progress = (actual / target).clamp(0.0, 1.0);
          return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w500)), Text('${actual.toStringAsFixed(1)}$unit / $target$unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFE91E63).withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)), minHeight: 6))]));
        }),
      ]),
    );
  }

  Widget _buildCycleTrends() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.trending_up, color: Color(0xFFE91E63)), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.cycleTrends, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 20), Row(children: [Expanded(child: _buildTrendItem(AppLocalizations.of(context)!.avgLength, '$_avgCycleLength days', Icons.calendar_month)), Container(width: 1, height: 40, color: Colors.white10), Expanded(child: _buildTrendItem(AppLocalizations.of(context)!.regularity, '${(_cycleRegularity * 100).toInt()}%', Icons.check_circle_outline, color: _cycleRegularity > 0.8 ? Colors.green : Colors.orange))]), const SizedBox(height: 20), Text(AppLocalizations.of(context)!.basedOnLast12Months, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]));
  }

  Widget _buildTrendItem(String label, String value, IconData icon, {Color? color}) {
    return Column(children: [Icon(icon, size: 16, color: color ?? AppColors.textSecondary), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]);
  }

  Widget _buildWellnessScore() {
    int score = 75; String label = 'Energy rising'; Color scoreColor = const Color(0xFF81C784);
    if (_currentPhase == 'Menstrual') { score = 45; label = 'Rest mode'; scoreColor = const Color(0xFFE57373); }
    else if (_currentPhase == 'Ovulation') { score = 95; label = 'Peak performance'; scoreColor = const Color(0xFFFFD54F); }
    else if (_currentPhase == 'Luteal') { score = 60; label = 'Slow down'; scoreColor = const Color(0xFF9575CD); }
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Row(children: [Stack(alignment: Alignment.center, children: [SizedBox(height: 70, width: 70, child: CircularProgressIndicator(value: score / 100, strokeWidth: 8, backgroundColor: scoreColor.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(scoreColor))), Text('$score%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.dailyWellnessScore, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(AppLocalizations.of(context)!.basedOnPhase, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]))]));
  }

  Widget _buildHormoneGraph() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AppLocalizations.of(context)!.hormoneBalance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [_buildHormoneLegend(AppLocalizations.of(context)!.estrogen, Colors.blue), const SizedBox(width: 12), _buildHormoneLegend(AppLocalizations.of(context)!.progesterone, Colors.orange)])]), const SizedBox(height: 24), SizedBox(height: 120, width: double.infinity, child: CustomPaint(painter: _HormonePainter(cycleDay: _cycleDay))), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AppLocalizations.of(context)!.day1, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), Text(AppLocalizations.of(context)!.day14, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), Text(AppLocalizations.of(context)!.day28, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))])]));
  }

  Widget _buildHormoneLegend(String label, Color color) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]);
  }
  
  Widget _buildSymptomHistory() {
     if (_symptomHistory.isEmpty) return const SizedBox.shrink();
     return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.history, color: Color(0xFFE91E63)), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.symptomHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _symptomHistory.length, separatorBuilder: (context, index) => const Divider(height: 24), itemBuilder: (context, index) { final item = _symptomHistory[index]; final dateStr = item['date'] as String?; if (dateStr == null) return const SizedBox.shrink(); final date = DateTime.tryParse(dateStr) ?? DateTime.now(); final symptoms = List<String>.from(item['symptoms'] as List? ?? []); return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [Text(date.day.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))), Text(_getMonthAbbr(date.month), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: 4, runSpacing: 4, children: symptoms.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(s, style: const TextStyle(fontSize: 11)))).toList()), if (item['notes'] != null && (item['notes'] as String).isNotEmpty) ...[const SizedBox(height: 4), Text(item['notes'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary))]]))]); })]));
  }

  String _getMonthAbbr(int month) { const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']; return months[month - 1]; }

  void _showSettingsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.trackerSettings),
      content: Text(AppLocalizations.of(context)!.configurationNotAvailable),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel))],
    ));
    // Simplified due to async complexity and rebuild issues in previous attempts.
  }
  
  Map<String, List<dynamic>> _calculateMicronutrientRequirements(String phase) {
    if(phase == 'Menstrual') return {'Iron': [18.0, 'mg', 'iron'], 'Magnesium': [320.0, 'mg', 'magnesium'], 'Vitamin B12': [2.4, 'μg', 'vitamin_b12']};
    if(phase == 'Follicular') return {'Vitamin B6': [1.3, 'mg', 'vitamin_b6'], 'Vitamin C': [75.0, 'mg', 'vitamin_c'], 'Zinc': [8.0, 'mg', 'zinc']};
    if(phase == 'Ovulation') return {'Zinc': [8.0, 'mg', 'zinc'], 'Vitamin D': [15.0, 'μg', 'vitamin_d'], 'Calcium': [1000.0, 'mg', 'calcium']};
    return {'Magnesium': [320.0, 'mg', 'magnesium'], 'Omega-3': [1.1, 'g', 'omega3'], 'Calcium': [1000.0, 'mg', 'calcium']};
  }

  Map<String, double> _calculateActualMicronutrients(List<Map<String, dynamic>> mealLogs, Map<String, List<dynamic>> reqs) {
    Map<String, double> actuals = {};
    for (var log in mealLogs) {
      final food = log['general_food_flow'] as Map<String, dynamic>?; if (food == null) continue;
      final quantity = (log['quantity'] as num?)?.toDouble() ?? 0.0;
      reqs.forEach((name, data) {
        final column = data[2] as String; final val = (food[column] as num?)?.toDouble() ?? 0.0;
        actuals[name] = (actuals[name] ?? 0.0) + ((val / 100) * quantity);
      });
    }
    return actuals;
  }

  Map<String, dynamic> _calculateCycleStats(List<Map<String, dynamic>> logs, int defaultLen) {
    if (logs.length < 2) return {'avg': defaultLen, 'regularity': 1.0};
    List<int> intervals = [];
    for (int i = 0; i < logs.length - 1; i++) {
        final d1 = DateTime.tryParse(logs[i]['start_date']); final d2 = DateTime.tryParse(logs[i+1]['start_date']);
        if (d1!=null && d2!=null) intervals.add(d1.difference(d2).inDays.abs());
    }
    if (intervals.isEmpty) return {'avg': defaultLen, 'regularity': 1.0};
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    double variance = 0; for (var v in intervals) {
      variance += math.pow(v - avg, 2);
    }
    final stdDev = math.sqrt(variance / intervals.length);
    final regularity = avg == 0 ? 1.0 : (1.0 - (stdDev / avg)).clamp(0.0, 1.0);
    return {'avg': avg.round(), 'regularity': regularity};
  }
}

class _HormonePainter extends CustomPainter {
  final int cycleDay;
  _HormonePainter({required this.cycleDay});
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.blue.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 3;
    final p2 = Paint()..color = Colors.orange.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 3;
    final path1 = Path()..moveTo(0, size.height*0.8)..quadraticBezierTo(size.width*0.3, size.height*0.7, size.width*0.45, size.height*0.1)..quadraticBezierTo(size.width*0.55, size.height*0.6, size.width*0.75, size.height*0.4)..quadraticBezierTo(size.width*0.9, size.height*0.75, size.width, size.height*0.9);
    final path2 = Path()..moveTo(0, size.height*0.9)..lineTo(size.width*0.5, size.height*0.9)..quadraticBezierTo(size.width*0.75, size.height*0.1, size.width, size.height*0.9);
    canvas.drawPath(path1, p1); canvas.drawPath(path2, p2);
    final cx = (cycleDay/28)*size.width; 
    canvas.drawCircle(Offset(cx, size.height*0.5), 4, Paint()..color = const Color(0xFFE91E63));
  }
  @override bool shouldRepaint(covariant _HormonePainter old) => old.cycleDay != cycleDay;
}

class _CyclePainter extends CustomPainter {
  final int current; final int total;
  _CyclePainter(this.current, this.total);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2); final r = math.min(size.width, size.height)/2;
    canvas.drawCircle(c, r-6, Paint()..color=Colors.white.withOpacity(0.2)..style=PaintingStyle.stroke..strokeWidth=12);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r-6), -math.pi/2, (current/total)*2*math.pi, false, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=12..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(_CyclePainter old) => old.current != current || old.total != total;
}
