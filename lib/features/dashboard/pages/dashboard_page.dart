import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/features/meal_tracking/pages/food_search_page.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/core/utils/nutrition_utils.dart';

import 'package:flow/core/utils/nutrition_data.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/dashboard/pages/fasting_history_page.dart';
import 'package:flow/features/dashboard/pages/nutrition_details_page.dart';
import 'package:flow/features/dashboard/pages/water_tracking_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'package:flow/features/trackers/pages/menstruation_tracker_page.dart';
import 'package:flow/features/trackers/pages/sleep_tracker_page.dart';
import 'package:flow/features/trackers/pages/mood_tracker_page.dart';
import 'package:flow/features/analytics/pages/advanced_analytics_page.dart';
import 'package:flow/features/notifications/pages/notifications_page.dart';
import 'package:flow/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:flow/features/marketplace/pages/marketplace_page.dart';
import 'package:flow/core/widgets/buy_coins_sheet.dart';
import 'package:flow/features/programs/pages/programs_page.dart';
import 'package:flow/features/analytics/pages/health_reports_page.dart';
import 'package:flow/features/diets_programs/pages/diets_and_programs_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/features/workout/pages/workout_confirmation_page.dart';
import 'package:flow/features/workout/pages/exercise_search_page.dart';
import 'package:flow/features/workout/pages/edit_custom_exercise_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum HeaderState { normal, health, macro }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final ReplicateService _replicateService = ReplicateService();
  late ConfettiController _confettiController;
  late AnimationController _waveController;
  
  List<Map<String, dynamic>> _allLogsRaw = [];
  List<String> _trackedNutrientKeys = ['omega3', 'fiber']; // Default
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _plannedWorkouts = [];
  Map<String, dynamic>? _upcomingWorkout;
  String _planType = 'free';
  int _coins = 100;
  
  Map<String, List<Map<String, dynamic>>> _mealLogs = {
    'BREAKFAST': [],
    'LUNCH': [],
    'DINNER': [],
    'SNACK': [],
  };
  int _waterAmount = 0;
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  int _streakCount = 0;
  bool _isLoading = true;

  // Real data from profile
  Map<String, double> _dailyNutrientTotals = {}; // For warnings
  int _calorieTarget = 2000;
  int _proteinTargetProgress = 0;
  int _carbsTargetProgress = 0;
  int _fatTargetProgress = 0;
  
  Map<String, dynamic>? _activeFast;
  double _healthScore = 0.0;

  int _proteinTargetGrams = 150;
  int _carbsTargetGrams = 220;
  int _fatTargetGrams = 70;
  double _totalBurnedCalories = 0;
  int _baseCalorieTarget = 2000;
  List<Map<String, dynamic>> _activeAddons = [];
  List<Map<String, dynamic>> _todaysExercises = [];
  
  // Header morphing state
  HeaderState _headerState = HeaderState.normal;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _userChallenges = [];
  Map<String, dynamic>? _activeDiet;
  Map<String, dynamic>? _activeProgram;

  // Today's tip (AI) – loaded in background after _loadData
  String? _todayTip;
  bool _todayTipLoading = false;
  
  // Realtime subscriptions
  RealtimeChannel? _dailyLogsChannel;
  RealtimeChannel? _exerciseLogsChannel;
  RealtimeChannel? _waterLogsChannel;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadData();
    _setupRealtimeSubscriptions();
  }

  void _onScroll() {
    if (_scrollController.offset > 50) {
      if (_headerState != HeaderState.normal) {
        setState(() {
          _headerState = HeaderState.normal;
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _dailyLogsChannel?.unsubscribe();
    _exerciseLogsChannel?.unsubscribe();
    _waterLogsChannel?.unsubscribe();
    super.dispose();
  }

  /// Setup realtime subscriptions for live dashboard updates
  void _setupRealtimeSubscriptions() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final client = Supabase.instance.client;

    // Subscribe to daily_logs changes
    _dailyLogsChannel = client
        .channel('dashboard_daily_logs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'daily_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('New meal logged via Realtime: ${payload.newRecord}');
            // Reload meals data
            _reloadMealsData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'daily_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Meal deleted via Realtime');
            _reloadMealsData();
          },
        )
        .subscribe();

    // Subscribe to exercise_logs changes
    _exerciseLogsChannel = client
        .channel('dashboard_exercise_logs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'exercise_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('New exercise logged via Realtime: ${payload.newRecord}');
            // Reload exercises data
            _reloadExercisesData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'exercise_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Exercise deleted via Realtime');
            _reloadExercisesData();
          },
        )
        .subscribe();

    // Subscribe to water_logs changes
    _waterLogsChannel = client
        .channel('dashboard_water_logs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'water_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('New water logged via Realtime: ${payload.newRecord}');
            // Reload water data
            _reloadWaterData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'water_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Water deleted via Realtime');
            _reloadWaterData();
          },
        )
        .subscribe();
  }

  /// Reload meals data when realtime update is received
  Future<void> _reloadMealsData() async {
    if (!mounted) return;
    
    try {
      final now = DateTime.now();
      final meals = await _supabaseService.getDailyMealLogs(now);
      
      Map<String, List<Map<String, dynamic>>> tempMeals = {
        'BREAKFAST': [],
        'LUNCH': [],
        'DINNER': [],
        'SNACK': [],
      };
      
      double calories = 0, protein = 0, carbs = 0, fat = 0;
      
      for (var meal in meals) {
        final type = meal['meal_type'] as String;
        if (tempMeals.containsKey(type)) {
          tempMeals[type]!.add(meal);
        }
        
        calories += (meal['calories'] as num?)?.toDouble() ?? 0.0;
        protein += (meal['protein'] as num?)?.toDouble() ?? 0.0;
        carbs += (meal['carbs'] as num?)?.toDouble() ?? 0.0;
        fat += (meal['fat'] as num?)?.toDouble() ?? 0.0;
      }
      
      if (mounted) {
        setState(() {
          _mealLogs = tempMeals;
          _totalCalories = calories;
          _totalProtein = protein;
          _totalCarbs = carbs;
          _totalFat = fat;
          _allLogsRaw = meals;
        });
      }
    } catch (e) {
      debugPrint('Error reloading meals data: $e');
    }
  }

  /// Reload exercises data when realtime update is received
  Future<void> _reloadExercisesData() async {
    if (!mounted) return;
    
    try {
      final now = DateTime.now();
      final exercises = await _supabaseService.getDailyExerciseLogs(now);
      
      double totalBurned = 0;
      for (var exercise in exercises) {
        totalBurned += (exercise['calories_burned'] as num?)?.toDouble() ?? 0.0;
      }
      
      if (mounted) {
        setState(() {
          _todaysExercises = exercises;
          _totalBurnedCalories = totalBurned;
        });
      }
    } catch (e) {
      debugPrint('Error reloading exercises data: $e');
    }
  }

  /// Reload water data when realtime update is received
  Future<void> _reloadWaterData() async {
    if (!mounted) return;
    
    try {
      final now = DateTime.now();
      final water = await _supabaseService.getDailyWaterLogs(now);
      
      int totalWater = 0;
      for (var log in water) {
        totalWater += (log['amount_ml'] as num?)?.toInt() ?? 0;
      }
      
      if (mounted) {
        setState(() {
          _waterAmount = totalWater;
        });
      }
    } catch (e) {
      debugPrint('Error reloading water data: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    
    try {
      await _supabaseService.ensureProfileExists();
      final meals = await _supabaseService.getDailyMealLogs(now);
      final water = await _supabaseService.getDailyWaterLogs(now);
      final exercises = await _supabaseService.getDailyExerciseLogs(now);
      
      // Load planned workouts
      final planned = await _supabaseService.getPlannedWorkouts(
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
      );
      
      // Find upcoming workout for today or next few days
      Map<String, dynamic>? upcoming;
      final today = DateTime(now.year, now.month, now.day);
      for (var workout in planned) {
        final scheduledDate = DateTime.parse(workout['scheduled_date'] as String);
        if (scheduledDate.isAtSameMomentAs(today) || scheduledDate.isAfter(today)) {
          upcoming = workout;
          break;
        }
      }
      
      Map<String, List<Map<String, dynamic>>> tempMeals = {
        'BREAKFAST': [],
        'LUNCH': [],
        'DINNER': [],
        'SNACK': [],
      };
      
      double calories = 0, protein = 0, carbs = 0, fat = 0;
      
      for (var meal in meals) {
        final type = meal['meal_type'] as String;
        tempMeals[type]?.add(meal);
        calories += (meal['calories'] ?? 0.0);
        protein += (meal['protein'] ?? 0.0);
        carbs += (meal['carbs'] ?? 0.0);
        fat += (meal['fat'] ?? 0.0);
      }
      
      int waterMl = 0;
      for (var log in water) {
        waterMl += (log['amount_ml'] as int);
      }

      final profile = await _supabaseService.getProfile();
      _profile = profile;
      _coins = (profile?['coins'] as num?)?.toInt() ?? 100;
      _planType = (profile?['plan_type'] as String?) ?? 'free';
      
      if (profile?['tracked_nutrients'] != null) {
        _trackedNutrientKeys = List<String>.from(profile!['tracked_nutrients']);
      }

      int calTarget = profile?['daily_calorie_target'] ?? 2000;
      int pPct = profile?['protein_target_percentage'] ?? 30;
      int cPct = profile?['carbs_target_percentage'] ?? 40;
      int fPct = profile?['fat_target_percentage'] ?? 30;

      int pGrams = ((calTarget * (pPct / 100)) / 4).round();
      int cGrams = ((calTarget * (cPct / 100)) / 4).round();
      int fGrams = ((calTarget * (fPct / 100)) / 9).round();

      _profile = profile;
      final activeFast = await _supabaseService.getCurrentFast();
      final activeAddons = await _supabaseService.getUserAddons();
      final streak = await _supabaseService.getStreakCount();
      final activeDiet = await _supabaseService.getActiveDiet();
      final activeProgram = await _supabaseService.getActiveProgram();
      
      setState(() {
        _allLogsRaw = meals; // Save for details page
        _mealLogs = tempMeals;
        _waterAmount = waterMl;
        _totalCalories = calories;
        _totalProtein = protein;
        _totalCarbs = carbs;
        _totalFat = fat;
        
        _calorieTarget = calTarget;
        _baseCalorieTarget = calTarget;
        _proteinTargetGrams = pGrams;
        _carbsTargetGrams = cGrams;
        _fatTargetGrams = fGrams;

        _activeFast = activeFast;
        _activeAddons = activeAddons;
        _streakCount = streak;
        _todaysExercises = exercises;
        _activeDiet = activeDiet;
        _activeProgram = activeProgram;
        
        _totalBurnedCalories = 0;
        for (var ex in exercises) {
          _totalBurnedCalories += (ex['calories_burned'] as num?)?.toDouble() ?? 0.0;
        }

        _calorieTarget = (_baseCalorieTarget + _totalBurnedCalories).round();

        _isLoading = false;
        
        // Load User Challenges
        _loadUserChallenges();
        
        // Calculate totals for warnings
        _dailyNutrientTotals = {};
        for (var log in meals) {
           final food = log['general_food_flow'] as Map<String, dynamic>?;
           if (food != null) {
              final qty = (log['quantity'] as num).toDouble() / 100.0;
              NutritionUtils.nutrientWarningThresholds.forEach((key, val) {
                 final nutrientVal = (food[key] as num?)?.toDouble() ?? 0.0;
                 _dailyNutrientTotals[key] = (_dailyNutrientTotals[key] ?? 0) + (nutrientVal * qty);
              });
           }
        }
        _healthScore = _calculateHealthScore(meals, waterMl);
        _plannedWorkouts = planned;
        _upcomingWorkout = upcoming;
      });
      if (_todayTip == null && !_todayTipLoading) _fetchTodayTip();
      if (mounted) {
        _scheduleNotifications(planned, streak, meals.isNotEmpty || exercises.isNotEmpty, waterMl, profile);
        _checkCelebrations();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))));
      }
    }
  }

  Future<void> _scheduleNotifications(
    List<Map<String, dynamic>> planned,
    int streakCount,
    bool hasLoggedToday,
    int waterMl,
    Map<String, dynamic>? profile,
  ) async {
    try {
      await NotificationService().requestPermission();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).languageCode;
      final localeTag = locale == 'de' ? 'de_DE' : (locale == 'ro' ? 'ro_RO' : 'en_US');
      final waterTargetMl = (profile?['daily_water_target'] as num?)?.toInt() ?? 2000;

      await NotificationService().scheduleWorkoutReminders(
        planned,
        title: l10n.workoutScheduled,
        bodyBuilder: (dateStr, timeStr) {
          final d = DateTime.tryParse('$dateStr') ?? DateTime.now();
          final dateFormatted = DateFormat('EEEE, MMMM d', localeTag).format(d);
          if (timeStr != null && timeStr.isNotEmpty) {
            final t = timeStr.length > 5 ? timeStr.substring(0, 5) : timeStr;
            return l10n.workoutScheduledForDateAtTime(dateFormatted, t);
          }
          return l10n.workoutScheduledForDate(dateFormatted);
        },
      );

      await NotificationService().scheduleGamificationReminders(
        streakCount: streakCount,
        hasLoggedToday: hasLoggedToday,
        waterMl: waterMl,
        waterTargetMl: waterTargetMl,
        streakReminderTitle: l10n.streakReminderTitle,
        streakReminderBody: l10n.streakReminderBody(streakCount.toString()),
        waterReminderTitle: l10n.water,
        waterReminderBody: l10n.pandaWater,
      );
    } catch (e) {
      debugPrint('Dashboard: schedule notifications $e');
    }
  }

  /// Calorie goal confetti + streak milestone messages (once per day / per milestone).
  Future<void> _checkCelebrations() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Calorie goal hit: confetti + snackbar once per day
    final calTarget = _calorieTarget.toDouble();
    if (calTarget > 0) {
      final inRange = _totalCalories >= calTarget * 0.95 && _totalCalories <= calTarget * 1.05;
      final lastCalorieDate = prefs.getString('flow_last_calorie_celebration') ?? '';
      if (inRange && lastCalorieDate != todayStr) {
        await prefs.setString('flow_last_calorie_celebration', todayStr);
        if (!mounted) return;
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.calorieGoalHit), backgroundColor: AppColors.primary),
        );
      }
    }

    // Streak milestone: message once per milestone (7, 14, 30, 100)
    const milestones = [7, 14, 30, 100];
    final lastMilestone = prefs.getInt('flow_last_streak_milestone') ?? 0;
    for (final m in milestones) {
      if (_streakCount >= m && lastMilestone < m) {
        await prefs.setInt('flow_last_streak_milestone', m);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.streakMilestone(m)), backgroundColor: Colors.orange),
        );
        break;
      }
    }

    // First workout of the day: confetti + snackbar once per day
    final lastWorkoutCelebration = prefs.getString('flow_last_workout_celebration') ?? '';
    if (_todaysExercises.isNotEmpty && lastWorkoutCelebration != todayStr) {
      await prefs.setString('flow_last_workout_celebration', todayStr);
      if (!mounted) return;
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workoutLoggedCelebration), backgroundColor: Colors.purple),
      );
    }
  }

  Future<void> _loadUserChallenges() async {
    try {
      final ucs = await _supabaseService.getUserChallenges();
      setState(() {
        _userChallenges = ucs.where((uc) => uc['status'] == 'active').toList();
      });
      // Trigger progress check
      await _supabaseService.checkChallengeProgress();
      
      // Reload if progress check completed anything
      final updated = await _supabaseService.getUserChallenges();
      if (mounted) {
        setState(() {
          _userChallenges = updated.where((uc) => uc['status'] == 'active').toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading user challenges: $e');
    }
  }

  Future<void> _fetchTodayTip() async {
    if (!mounted) return;
    setState(() => _todayTipLoading = true);

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final langHint = locale == 'de' ? 'German' : (locale == 'ro' ? 'Romanian' : 'English');

      String? sleepInfo;
      try {
        final lastNight = DateTime.now().subtract(const Duration(days: 1));
        final sleepLog = await _supabaseService.getSleepLogForDate(lastNight);
        if (sleepLog != null) {
          final duration = sleepLog['duration_hours'] as num?;
          if (duration != null) {
            sleepInfo = '${duration.toStringAsFixed(1)}h sleep last night';
          }
        }
      } catch (_) {}

      final goal = _profile?['goal']?.toString() ?? 'general wellness';
      final remaining = (_calorieTarget - _totalCalories).round();
      final dataLines = [
        'Goal: $goal',
        'Daily calorie target: $_calorieTarget kcal',
        'Consumed today: ${_totalCalories.round()} kcal',
        'Remaining: $remaining kcal',
        'Protein today: ${_totalProtein.round()}g',
        'Water today: ${_waterAmount}ml',
        if (sleepInfo != null) sleepInfo,
      ];

      const systemInstruction = '''You are Flow's friendly coach. Reply with exactly ONE short sentence: a tip or encouragement for today based on the data. No greeting, no bullet points, no quotes. Be warm and actionable. Keep it under 15 words.''';

      final prompt = '''Today's data:
${dataLines.join('\n')}

Reply in $langHint. One short sentence only.''';

      final response = await _replicateService.generateAdvice(
        prompt: prompt,
        systemInstruction: systemInstruction,
        temperature: 0.6,
        maxOutputTokens: 80,
      );

      String tip = response.trim();
      if (tip.startsWith('"') && tip.endsWith('"')) {
        tip = tip.substring(1, tip.length - 1);
      }
      tip = tip.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1').replaceAll('*', '').trim();

      if (!mounted) return;
      setState(() {
        _todayTip = tip.isEmpty ? null : tip;
        _todayTipLoading = false;
      });
    } catch (e) {
      debugPrint('Today tip fetch error: $e');
      if (mounted) {
        setState(() {
          _todayTip = null;
          _todayTipLoading = false;
        });
      }
    }
  }

  void _navigateToAddFood(BuildContext context, String mealType) async {
    // 1. Check for Active Fast
    if (_activeFast != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.fastingActiveDialog),
          content: Text(AppLocalizations.of(context)!.fastingEndLog),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.endFastLog),
            ),
          ],
        ),
      );

      if (confirm != true) return; // User cancelled

      await _supabaseService.endFast();
      await _loadData(); // Update UI
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodSearchPage(mealType: mealType)),
    );
    _loadData(); // Reload after return
  }

  void _addWater() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: AppSpacing.paddingPage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.addWater, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterOption(250, AppLocalizations.of(context)!.glass, Icons.local_drink),
                _buildWaterOption(500, AppLocalizations.of(context)!.bottle, Icons.local_drink_outlined),
                _buildWaterOption(750, AppLocalizations.of(context)!.large, Icons.water_drop),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(AppLocalizations.of(context)!.enterAmount, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.ml,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (val) {
                  final amount = int.tryParse(val);
                  if (amount != null) _logWaterAmount(amount);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logWaterAmount(int amount) async {
    Navigator.pop(context);
    await _supabaseService.logWater(amount);
    _loadData();
  }

  void _quickAddWater(int amount) async {
    await _supabaseService.logWater(amount);
    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.waterLogged('$amount ml'))),
      );
    }
  }

  Widget _buildQuickWaterChip(int amount) {
    return Material(
      color: Colors.blue.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _quickAddWater(amount),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('+$amount', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildWaterOption(int amount, String label, IconData icon) {
    return InkWell(
      onTap: () => _logWaterAmount(amount),
      child: Column(
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$amount ml', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildNutrientWarnings() {
    List<Widget> warningWidgets = [];
    NutritionUtils.nutrientWarningThresholds.forEach((key, thresholdData) {
      final total = _dailyNutrientTotals[key] ?? 0.0;
      final limit = (thresholdData['limit'] as num).toDouble();
      
      if (total > limit) {
        final meta = NutritionData.metaMap[key];
        if (meta != null) {
          warningWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          '${AppLocalizations.of(context)!.high} ${meta.name}',
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          thresholdData['message'],
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    if (warningWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.warnings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 12),
        ...warningWidgets,
        const SizedBox(height: 24),
      ],
    );
  }

  double _calculateShadowWeight(double currentWeight, double calorieTarget, double totalCalories) {
    if (currentWeight <= 0 || calorieTarget <= 0) return currentWeight;
    // 1 kg of fat is approximately 7700 calories
    double calorieDifference = totalCalories - calorieTarget;
    double weightChange = calorieDifference / 7700; // Change in kg
    return currentWeight + weightChange;
  }

  double _calculateHealthScore(List<Map<String, dynamic>> meals, int water) {
    double score = 10.0;
    
    // If no data at all yet, keep it at 10.0 (fresh start)
    if (meals.isEmpty && water == 0) return 10.0;

    // 1. Calories check (+/- 15% is ideal)
    double calDiff = (_totalCalories - _calorieTarget).abs();
    if (calDiff > _calorieTarget * 0.15) score -= 1.0;
    if (calDiff > _calorieTarget * 0.30) score -= 2.0;
    
    // 2. Protein Check (crucial for health)
    if (_totalProtein < _proteinTargetGrams * 0.7) score -= 1.5;
    
    // 3. Water Check
    final waterTarget = (_profile?['daily_water_target'] as num?)?.toDouble() ?? 2000.0;
    if (water < waterTarget * 0.5) score -= 1.5;
    
    // 4. Bad Nutrients (Sugar/Sodium)
    _dailyNutrientTotals.forEach((key, val) {
       final threshold = NutritionUtils.nutrientWarningThresholds[key];
       if (threshold != null) {
         final limit = (threshold['limit'] as num).toDouble();
         if (val > limit) {
           score -= 1.0;
           if (val > limit * 1.5) score -= 1.0; 
         }
       }
    });

    return score.clamp(0.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Skeleton
                Container(height: 240, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32))),
                const SizedBox(height: 24),
                // Fasting Card Skeleton
                Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
                const SizedBox(height: 24),
                // Meal Cards Skeleton
                Expanded(
                   child: ListView.builder(
                     itemCount: 3,
                     itemBuilder: (c, i) => Container(
                       margin: const EdgeInsets.only(bottom: 16),
                       height: 80,
                       width: double.infinity,
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                     ),
                   ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 380,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Premium Mesh Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MeshGradientPainter(),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) {
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildHeaderContent(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: innerBoxIsScrolled 
                    ? const Text('FLOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)) 
                    : null,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.storefront, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MarketplacePage()),
                    ).then((_) => _loadData()),
                    tooltip: AppLocalizations.of(context)!.marketplaceTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SportsProgramsPage()),
                      );
                    },
                    tooltip: AppLocalizations.of(context)!.challengesTooltip,
                  ),
                  // Notifications button - show workout reminder badge if needed
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () => _showNotificationsPage(),
                        tooltip: AppLocalizations.of(context)!.notificationsTooltip,
                      ),
                      if (_upcomingWorkout != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildPandaCoach(),
                  const SizedBox(height: 16),
                  _buildActiveChallenges(),
                  const SizedBox(height: 16),
                  _buildDietsAndProgramsCard(),
                  const SizedBox(height: 16),
                  _buildFastingCard(),
                  const SizedBox(height: 24),
                  ..._buildAddonCards(),
                  _buildNutrientWarnings(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.todaysMeals, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => NutritionDetailsPage(initialLogs: _allLogsRaw))
                        ),
                        child: Text(AppLocalizations.of(context)!.viewAll + ' >'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMealSection(context, AppLocalizations.of(context)!.breakfast, 'BREAKFAST', Icons.wb_sunny_rounded, AppColors.secondary),
                  _buildMealSection(context, AppLocalizations.of(context)!.lunch, 'LUNCH', Icons.restaurant, AppColors.primary),
                  _buildMealSection(context, AppLocalizations.of(context)!.dinner, 'DINNER', Icons.dinner_dining, AppColors.accent),
                  _buildMealSection(context, AppLocalizations.of(context)!.snacks, 'SNACK', Icons.icecream, Colors.orange),
                  
                  const SizedBox(height: 32),
                  _buildActivitiesSection(),
                  
                  const SizedBox(height: 24),
                  _buildCustomTrackers(),
                  const SizedBox(height: 24),
                  _buildWeightEntryCard(),
                  const SizedBox(height: 24),
                  _buildWaterTracking(),
                  const SizedBox(height: 32),
                  _buildPalmares(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ),
        ],
      ),
    );
  }




Widget _buildActiveChallenges() {
if (_userChallenges.isEmpty) return const SizedBox.shrink();

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppLocalizations.of(context)!.activeChallenges + ' 🏆', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(AppLocalizations.of(context)!.activeCount(_userChallenges.length), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ],
    ),
    const SizedBox(height: 12),
    SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _userChallenges.length,
        itemBuilder: (context, index) {
          final uc = _userChallenges[index];
          final challenge = uc['challenges'];
          if (challenge == null) return const SizedBox.shrink();

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  challenge['Name_English'] ?? 'Challenge',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ((uc['current_progress'] as num?)?.toDouble() ?? 0) /
                      ((challenge['goal_value'] as num?)?.toDouble() ?? 1),
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep it flowin\'! 🔥',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
);
}

Widget _buildPalmares() {
  final achievements = List<String>.from(_profile?['achievements'] ?? []);
  if (achievements.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(AppLocalizations.of(context)!.hallOfFame + ' 🏆', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: achievements.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withAlpha(102), blurRadius: 15, spreadRadius: 1),
            ],
            border: Border.all(color: AppColors.primary.withAlpha(127), width: 2),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        )).toList(),
      ),
      const SizedBox(height: 32),
    ],
  );
}



  void _showEditTargetsDialog() {
    final calorieController = TextEditingController(text: _calorieTarget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editDailyGoal),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.setManualCalorieTarget),
            const SizedBox(height: 16),
            TextField(
              controller: calorieController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.caloriesKcal,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              int? newTarget = int.tryParse(calorieController.text);
              if (newTarget != null) {
                await _supabaseService.updateProfile({'daily_calorie_target': newTarget});
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }


  Widget _buildWeightEntryCard() {
    final currentWeight = _profile?['current_weight'] ?? 0.0;
    
    // Prediction logic
    double predicted = _calculateShadowWeight(currentWeight, _calorieTarget.toDouble(), _totalCalories);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(51), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.logMorningWeight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(currentWeight > 0 ? AppLocalizations.of(context)!.lastLogged(currentWeight.toString()) : AppLocalizations.of(context)!.keepTrackProgress, 
                     style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (currentWeight > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(AppLocalizations.of(context)!.tomorrowsEst(predicted.toStringAsFixed(1)), 
                               style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          if (_profile?['height'] != null)
                            Builder(builder: (context) {
                              final bmi = NutritionUtils.calculateBMI(currentWeight, (_profile!['height'] as num).toDouble());
                              final status = NutritionUtils.getBMIStatus(bmi);
                              return Text('${AppLocalizations.of(context)!.bmi}: ${bmi.toStringAsFixed(1)} ($status)', 
                                   style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold));
                            }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: _showWeightLogDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(currentWeight > 0 ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.logWeight),
          ),
        ],
      ),
    );
  }

  void _showWeightLogDialog() {
    final controller = TextEditingController(text: (_profile?['current_weight'] ?? '').toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logMorningWeight),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: 'kg', hintText: AppLocalizations.of(context)!.enterWeight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                await _supabaseService.logWeight(val);
                _loadData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracking() {
    final target = (_profile?['daily_water_target'] as num?)?.toInt() ?? 2000;
    if (_waterAmount >= target) _confettiController.play();

    double progress = _waterAmount / target;
    if (progress > 1.0) progress = 1.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaterTrackingPage(
              currentWater: _waterAmount,
              target: target,
            ),
          ),
        ).then((_) => _loadData()); // Reload data when returning
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              CustomPaint(
                painter: _WavePainter(_waveController, progress, Colors.blue.withOpacity(0.3)),
                child: Container(),
              ),
              Padding(
                 padding: const EdgeInsets.all(20),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Row(
                         children: [
                           const Icon(Icons.water_drop, color: Colors.blue, size: 30),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Text(AppLocalizations.of(context)!.hydrationWave, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                 Text('$_waterAmount / $target ml', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                     Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         _buildQuickWaterChip(250),
                         const SizedBox(width: 6),
                         _buildQuickWaterChip(500),
                         const SizedBox(width: 6),
                         GestureDetector(
                           onTap: () => _addWater(),
                           behavior: HitTestBehavior.opaque,
                           child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(Icons.add, color: Colors.blue),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDietsAndProgramsCard() {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final hasActive = _activeDiet != null || _activeProgram != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DietsAndProgramsPage()),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasActive
                ? [AppColors.primary, AppColors.secondary]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasActive
                ? AppColors.primary.withAlpha(102)
                : Colors.grey.withAlpha(26),
            width: hasActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasActive
                  ? AppColors.primary.withAlpha(51)
                  : Colors.black.withAlpha(13),
              blurRadius: hasActive ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hasActive
                    ? Colors.white.withAlpha(51)
                    : AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: hasActive ? Colors.white : AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dietsAndPrograms,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasActive ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasActive) ...[
                    if (_activeDiet != null) ...[
                      Text(
                        isDe
                            ? ((_activeDiet!['diets'] as Map<String, dynamic>?)?['name_de'] as String? ?? '')
                            : ((_activeDiet!['diets'] as Map<String, dynamic>?)?['name_en'] as String? ?? ''),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (_activeProgram != null) ...[
                      Text(
                        isDe
                            ? ((_activeProgram!['fitness_programs'] as Map<String, dynamic>?)?['name_de'] as String? ?? '')
                            : ((_activeProgram!['fitness_programs'] as Map<String, dynamic>?)?['name_en'] as String? ?? ''),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else
                    Text(
                      AppLocalizations.of(context)!.activateDietOrProgram,
                      style: TextStyle(
                        color: hasActive ? Colors.white70 : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: hasActive ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingCard() {
    bool isFasting = _activeFast != null;
    final l10n = AppLocalizations.of(context)!;
    String statusText = isFasting ? l10n.fastingActive : l10n.eatingWindow;
    String timeText = l10n.startFast;
    double progress = 0;
    String stageText = l10n.bodyIsDigesting;
    Color stageColor = Colors.orange;
    
    if (isFasting) {
      final start = DateTime.parse(_activeFast!['start_time']);
      final diff = DateTime.now().difference(start);
      final minutes = diff.inMinutes;

      // Stage Logic
      if (minutes < 240) { // < 4h
        stageText = l10n.bloodSugarRising;
        stageColor = Colors.redAccent;
        progress = minutes / 240;
      } else if (minutes < 720) { // < 12h
        stageText = l10n.bloodSugarFalling;
        stageColor = Colors.orange;
        progress = (minutes - 240) / (720 - 240);
      } else if (minutes < 960) { // < 16h
        stageText = l10n.fatBurningKetosis;
        stageColor = Colors.purpleAccent;
        progress = (minutes - 720) / (960 - 720);
      } else { // 16h+
        stageText = l10n.autophagyRepair;
        stageColor = Colors.deepPurple;
        progress = 1.0;
      }

      timeText = '${diff.inHours}h ${diff.inMinutes % 60}m elapsed';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFasting ? stageColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer, color: isFasting ? stageColor : Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(isFasting ? stageText : AppLocalizations.of(context)!.readyToFast, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (!isFasting)
                 IconButton(
                   icon: const Icon(Icons.history, color: AppColors.primary),
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FastingHistoryPage())),
                 ),
            ],
          ),
          if (isFasting) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: stageColor, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  if (isFasting) {
                    await _supabaseService.endFast();
                  } else {
                    await _supabaseService.startFast();
                  }
                  await _loadData();
                } catch (e) {
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(AppLocalizations.of(context)!.fastingError(e.toString())), backgroundColor: Colors.red),
                     );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFasting ? AppColors.background : Colors.black,
                foregroundColor: isFasting ? Colors.black : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isFasting ? AppLocalizations.of(context)!.endFast : AppLocalizations.of(context)!.startFasting),
            ),
          ),
          if (isFasting)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: TextButton(
                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FastingHistoryPage())),
                  child: Text(AppLocalizations.of(context)!.viewHistory, style: const TextStyle(fontSize: 12)),
               ),
             )
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String title, String mealKey, IconData icon, Color iconColor) {
    final entries = _mealLogs[mealKey] ?? [];
    double mealCalories = 0;
    double mealProtein = 0;
    double mealCarbs = 0;
    
    for (var e in entries) {
      mealCalories += (e['calories'] ?? 0.0);
      mealProtein += (e['protein'] ?? 0.0);
      mealCarbs += (e['carbs'] ?? 0.0);
    }

    // Smart Tags Logic
    final l10n = AppLocalizations.of(context)!;
    List<Widget> tags = [];
    if (mealCalories > 0) {
      if (mealProtein > 30) tags.add(_buildTag(l10n.highProtein, Colors.green));
      else if (mealCarbs < 20) tags.add(_buildTag(l10n.lowCarb, Colors.blue));
      else if (mealCalories < 400 && title != l10n.snack) tags.add(_buildTag(l10n.light, Colors.orange));
      else tags.add(_buildTag(l10n.balanced, Colors.purple));
    }

    return InkWell(
      onTap: () {
        if (entries.isEmpty) _navigateToAddFood(context, mealKey);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: AppColors.card,
           borderRadius: BorderRadius.circular(24),
           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          Text('${mealCalories.toInt()} kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(width: 8),
                          ...tags,
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _navigateToAddFood(context, mealKey),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
               const SizedBox(height: 16),
               const Divider(),
               ...entries.map((entry) => Padding(
                 padding: const EdgeInsets.symmetric(vertical: 6),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(
                         entry['general_food_flow']?['name']?.toString() ?? 
                         entry['custom_food_name']?.toString() ?? 
                         'Food',
                         style: const TextStyle(fontWeight: FontWeight.w500),
                       ),
                     ),
                     Text('${(entry['calories'] as num).toInt()} kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                   ],
                 ),
               )).toList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTrackers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.myTrackers, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: _showAddTrackerDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_trackedNutrientKeys.isEmpty)
          Text(AppLocalizations.of(context)!.noCustomTrackers, style: const TextStyle(color: AppColors.textSecondary)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _trackedNutrientKeys.map((key) {
              final meta = NutritionData.metaMap[key];
              if (meta == null) return const SizedBox();
              
              // Calculate total for this nutrient
              double total = 0;
              for (var log in _allLogsRaw) {
                final food = log['general_food_flow'] as Map<String, dynamic>?;
                if (food != null) {
                  final quantity = (log['quantity'] as num).toDouble();
                  final val = (food[key] as num?)?.toDouble() ?? 0.0;
                  total += (val * quantity / 100.0);
                }
              }

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(meta.icon, color: AppColors.primary, size: 24),
                    const SizedBox(height: 8),
                    Text(meta.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${total.toStringAsFixed(1)} ${meta.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddTrackerDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectTrackers),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: NutritionData.nutrients.map((n) {
                final isTracked = _trackedNutrientKeys.contains(n.key);
                return CheckboxListTile(
                  title: Text(n.name),
                  value: isTracked,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setDialogState(() {
                      if (val == true) {
                        _trackedNutrientKeys.add(n.key);
                      } else {
                        _trackedNutrientKeys.remove(n.key);
                      }
                    });
                    setState(() {}); // Update dashboard too
                    await _supabaseService.updateProfile({'tracked_nutrients': _trackedNutrientKeys});
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close)),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final AnimationController controller;
  final double progress;
  final Color color;

  _WavePainter(this.controller, this.progress, this.color) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 10.0;
    final waveLength = size.width / 2;
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Draw bottom edge
    path.lineTo(0, size.height * (1 - progress));
    
    // Draw wave
    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final y = size.height * (1 - progress) + 
                math.sin((i / waveLength + controller.value * 2) * math.pi * 2) * waveHeight;
      path.lineTo(x, y);
    }
    
    // Complete the path
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}

// Extension to build addon cards dynamically
extension _AddonCards on _DashboardPageState {
  List<Widget> _buildAddonCards() {
    if (_activeAddons.isEmpty) return [];
    
    return _activeAddons.map((addon) {
      final addonData = addon['available_addons'] as Map<String, dynamic>?;
      if (addonData == null) return const SizedBox.shrink();

      final addonId = addonData['id']?.toString();
      if (addonId == null || addonId.isEmpty) return const SizedBox.shrink();
      
      // Build card based on addon type
      if (addonId == 'menstruation_tracker') {
        return Column(
          children: [
            _buildMenstruationCard(),
            const SizedBox(height: 24),
          ],
        );
      }
      
      if (addonId == 'sleep_tracker') {
        return Column(
          children: [
            _buildSleepTrackerCard(),
            const SizedBox(height: 24),
          ],
        );
      }
      
      if (addonId == 'mood_tracker') {
        return Column(
          children: [
            _buildMoodTrackerCard(),
            const SizedBox(height: 24),
          ],
        );
      }
      
      if (addonId == 'advanced_analytics') {
        return Column(
          children: [
            _buildAdvancedAnalyticsCard(),
            const SizedBox(height: 24),
          ],
        );
      }
      
      // Default card for other addons
      return Column(
        children: [
          _buildGenericAddonCard(addonData),
          const SizedBox(height: 24),
        ],
      );
    }).toList();
  }
  
  Widget _buildMenstruationCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MenstruationTrackerPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('🩸', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.cycleTracker, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.nextInDays('16'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSleepTrackerCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SleepTrackerPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('😴', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.sleepTracker,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.trackYourSleep,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMoodTrackerCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MoodTrackerPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('😊', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.moodTracker,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.trackYourMood,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdvancedAnalyticsCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdvancedAnalyticsPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('📊', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.advancedAnalytics,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.aiPoweredInsights,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGenericAddonCard(Map<String, dynamic> addon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(addon['icon'] ?? '📦', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(addon['description'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _PremiumUI on _DashboardPageState {
  Widget _buildHeaderGreeting() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    String greeting = l10n.goodMorning;
    IconData icon = Icons.wb_sunny_outlined;
    if (hour >= 12 && hour < 17) {
      greeting = l10n.goodAfternoon;
      icon = Icons.wb_cloudy_outlined;
    } else if (hour >= 17 || hour < 5) {
      greeting = l10n.goodEvening;
      icon = Icons.nights_stay_outlined;
    }
    
    final name = _profile?['full_name']?.split(' ')[0] ?? l10n.flowUser;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                 final newUrl = await _supabaseService.uploadAvatar();
                 if (newUrl != null && mounted) {
                   _loadData();
                 }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipOval(
                  child: _profile != null && _profile!['avatar_url'] != null
                      ? Image.network(
                          _profile!['avatar_url'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: Text(
                                (_profile?['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        )
                      : Container(
                          alignment: Alignment.center,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            (_profile?['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketplacePage(),
                      ),
                    );
                    _loadData();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Plan Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: _planType == 'creator'
                              ? Colors.purpleAccent.withValues(alpha: 0.3)
                              : (_planType == 'premium'
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : Colors.white10),
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                          border: Border.all(
                            color: _planType == 'creator'
                                ? Colors.purpleAccent.withValues(alpha: 0.5)
                                : (_planType == 'premium'
                                    ? Colors.amber.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.2)),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _planType == 'creator'
                              ? AppLocalizations.of(context)!.flowCreator
                              : (_planType == 'premium'
                                  ? AppLocalizations.of(context)!.flowPremier
                                  : AppLocalizations.of(context)!.flowBasic),
                          style: TextStyle(
                            color: _planType == 'creator'
                                ? Colors.purpleAccent
                                : (_planType == 'premium'
                                    ? Colors.amber
                                    : Colors.white70),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Coins display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPandaCoach() {
    final l10n = AppLocalizations.of(context)!;
    String tip = l10n.pandaDoingGreat;
    bool isFitness = false;
    bool hasWorkoutReminder = false;
    VoidCallback? onTap;

    // Check for upcoming workout reminder (priority)
    if (_upcomingWorkout != null) {
      final scheduledDate = DateTime.parse(_upcomingWorkout!['scheduled_date'] as String);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (scheduledDate.isAtSameMomentAs(todayDate)) {
        final scheduledTime = _upcomingWorkout!['scheduled_time'] as String?;
        if (scheduledTime != null) {
          final timeParts = scheduledTime.split(':');
          final workoutHour = int.parse(timeParts[0]);
          final workoutMinute = int.parse(timeParts[1]);
          final workoutTime = DateTime(today.year, today.month, today.day, workoutHour, workoutMinute);
          
          // Show reminder if workout time is within next 2 hours or past due
          if (workoutTime.isBefore(today.add(const Duration(hours: 2))) && workoutTime.isAfter(today.subtract(const Duration(hours: 1)))) {
            hasWorkoutReminder = true;
            tip = l10n.tapToLogWorkout;
            isFitness = true;
            onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseSearchPage(),
                ),
              ).then((_) {
                _reloadExercisesData();
              });
            };
          }
        } else {
          // No time specified, show reminder for today
          hasWorkoutReminder = true;
          tip = l10n.tapToLogWorkout;
          isFitness = true;
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExerciseSearchPage(),
              ),
            ).then((_) {
              _reloadExercisesData();
            });
          };
        }
      }
    }

    // AI tip from background (when ready) or other rule-based tips
    if (!hasWorkoutReminder) {
      if (_todayTip != null && _todayTip!.trim().isNotEmpty) {
        tip = _todayTip!;
      } else if (_totalCalories > _calorieTarget) {
        tip = l10n.pandaCarefulCal;
        isFitness = true;
      } else if (_totalProtein < _proteinTargetGrams * 0.5) {
        tip = l10n.pandaProtein;
        isFitness = true;
      } else if (_waterAmount < 1000) {
        tip = l10n.pandaWater;
      } else if (_streakCount > 0) {
        tip = l10n.pandaStreak(_streakCount.toString());
      }
    }

    return FadeInRight(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: hasWorkoutReminder ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Image.asset(
                  isFitness ? 'assets/images/panda_fitness.png' : 'assets/images/panda.png',
                  height: 60,
                  width: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.pandaCoach, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                          if (hasWorkoutReminder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fitness_center, size: 12, color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasWorkoutReminder ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: hasWorkoutReminder ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    switch (_headerState) {
      case HeaderState.health:
        return _buildHealthExpandedHeader();
      case HeaderState.macro:
        return _buildMacroExpandedHeader();
      case HeaderState.normal:
      default:
        return _buildNormalHeader();
    }
  }

  Widget _buildNormalHeader() {
    return Column(
      key: const ValueKey('header_normal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderGreeting(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showHealthScoreDetails,
                  borderRadius: BorderRadius.circular(32),
                  child: _buildHealthScoreGlassCard(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showNutrientBreakdown,
                  borderRadius: BorderRadius.circular(100),
                  child: _buildNutrientRings(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildQuickStatsBar(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickStatsBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem(
            icon: Icons.local_fire_department,
            value: '${_totalCalories.toInt()}',
            label: l10n.calories,
            color: Colors.orangeAccent,
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
          _buildQuickStatItem(
            icon: Icons.fitness_center,
            value: '${_totalProtein.toInt()}g',
            label: AppLocalizations.of(context)!.nutrient_protein,
            color: Colors.pinkAccent,
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
          _buildQuickStatItem(
            icon: Icons.water_drop,
            value: '${(_waterAmount / 1000).toStringAsFixed(1)}L',
            label: AppLocalizations.of(context)!.water,
            color: Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthExpandedHeader() {
    // Collect all deductions including warnings
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> deductions = [
      _buildScoreDeductionItem(l10n.calorieBalance, _totalCalories, _calorieTarget.toDouble(), 0.15, 2.0),
      _buildScoreDeductionItem(l10n.proteinTarget, _totalProtein, _proteinTargetGrams.toDouble(), 0.70, 1.5, isGoal: true),
      _buildScoreDeductionItem(l10n.hydration, _waterAmount.toDouble(), (_profile?['daily_water_target'] as num?)?.toDouble() ?? 2000.0, 0.50, 1.5, isGoal: true),
    ];

    // Add nutrient warnings
    NutritionUtils.nutrientWarningThresholds.forEach((key, value) {
      final total = _dailyNutrientTotals[key] ?? 0.0;
      final limit = (value['limit'] as num).toDouble();
      if (total > limit) {
        deductions.add(_buildScoreDeductionItem(NutritionData.metaMap[key]?.name ?? key, total, limit, 1.0, 1.0, isInverse: true));
      }
    });

    return Container(
      key: const ValueKey('header_health_expanded'),
      padding: const EdgeInsets.all(20), // Slightly reduced padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.healthAnalysis, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                onPressed: () => setState(() => _headerState = HeaderState.normal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_healthScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Text('/ 10', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(_healthScore).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _healthScore > 8 ? AppLocalizations.of(context)!.excellentStatus : _healthScore > 5 ? AppLocalizations.of(context)!.goodStatus : AppLocalizations.of(context)!.needsWorkStatus,
                  style: TextStyle(color: _getScoreColor(_healthScore), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          // Use a limited height or list view to prevent overflow
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: deductions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroExpandedHeader() {
    final calorieBalanced = (_totalCalories - _calorieTarget).abs() < (_calorieTarget * 0.15);
    
    return Container(
      key: const ValueKey('header_macro_expanded'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.nutritionSummary, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                    onPressed: () {
                      setState(() => _headerState = HeaderState.normal);
                      _showEditTargetsDialog();
                    },
                    tooltip: AppLocalizations.of(context)!.editDailyGoal,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                    onPressed: () => setState(() => _headerState = HeaderState.normal),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: _buildNutrientRings(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildMacroExpandedItem('P', _totalProtein, _proteinTargetGrams, Colors.pinkAccent),
                    const SizedBox(height: 10),
                    _buildMacroExpandedItem('C', _totalCarbs, _carbsTargetGrams, Colors.cyanAccent),
                    const SizedBox(height: 10),
                    _buildMacroExpandedItem('F', _totalFat, _fatTargetGrams, Colors.amberAccent),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.calorieBalance, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(
                    calorieBalanced ? AppLocalizations.of(context)!.perfectlyBalanced : _totalCalories > _calorieTarget ? AppLocalizations.of(context)!.calorieSurplus : AppLocalizations.of(context)!.calorieDeficit,
                    style: TextStyle(color: calorieBalanced ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppLocalizations.of(context)!.keepTrackProgress, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${((_totalCalories / _calorieTarget) * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text('${AppLocalizations.of(context)!.activitiesWorkouts} 🏋️', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
             IconButton(
               onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseSearchPage(),
                  ),
                ).then((_) {
                  // Reload exercises when returning from search
                  _reloadExercisesData();
                });
              },
               icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
             ),
          ],
        ),
        const SizedBox(height: 16),
        if (_todaysExercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Center(
              child: Text(AppLocalizations.of(context)!.noActivitiesLogged, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._todaysExercises.map((log) {
            final exercise = log['exercises'] as Map<String, dynamic>?;
            final isCustom = log['is_custom'] == true;
            
            // Debug logging
            if (exercise == null) {
              debugPrint('[Dashboard] WARNING: Exercise data is null for log: ${log['id']}');
              debugPrint('[Dashboard] Log keys: ${log.keys}');
              debugPrint('[Dashboard] exercise_id: ${log['exercise_id']}, custom_exercise_id: ${log['custom_exercise_id']}');
            }
            
            final exerciseName = exercise?['name_en'] ?? exercise?['name_de'] ?? 'Exercise';
            final imageUrl = exercise?['image_url'] as String? ?? exercise?['video_url'] as String?;
            
            return GestureDetector(
              onTap: isCustom ? () async {
                // Navigate to edit page for custom exercises
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCustomExercisePage(
                      exercise: exercise!,
                    ),
                  ),
                );
                // Reload exercises if updated
                if (result == true) {
                  _reloadExercisesData();
                }
              } : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                children: [
                   Container(
                     width: 56,
                     height: 56,
                     decoration: BoxDecoration(
                       color: Colors.orange.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: (imageUrl != null && imageUrl.isNotEmpty && !isCustom)
                         ? ClipRRect(
                             borderRadius: BorderRadius.circular(16),
                             child: CachedNetworkImage(
                               imageUrl: imageUrl,
                               fit: BoxFit.cover,
                               placeholder: (context, url) => Container(
                                 color: Colors.orange.withOpacity(0.1),
                                 child: const Center(
                                   child: CircularProgressIndicator(strokeWidth: 2),
                                 ),
                               ),
                               errorWidget: (context, url, error) => Container(
                                 color: Colors.orange.withOpacity(0.1),
                                 child: const Center(
                                   child: Icon(Icons.fitness_center, color: Colors.orange, size: 24),
                                 ),
                               ),
                             ),
                           )
                         : Center(
                             child: Icon(
                               Icons.fitness_center,
                               color: Colors.orange,
                               size: 24,
                             ),
                           ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Expanded(
                               child: Text(
                                 exerciseName,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                             if (isCustom)
                               Container(
                                 margin: const EdgeInsets.only(left: 8),
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: AppColors.primary.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: Text(
                                   'Custom',
                                   style: TextStyle(
                                     color: AppColors.primary,
                                     fontSize: 10,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(
                           '${log['sets']} sets • ${log['reps']} reps • ${log['weight_kg']}kg', 
                           style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 8),
                   Text('${(log['calories_burned'] as num?)?.toInt() ?? 0} kcal', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                 ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showExerciseSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('${AppLocalizations.of(context)!.log} Activity 🏋️', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchExerciseHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  // Implement live search if needed, or simple local filter if data loaded
                },
                onSubmitted: (val) async {
                  final results = await _supabaseService.searchExercises(val);
                  if (!mounted) return;
                  // Show results dialog or update local state list
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.selectExercise),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final ex = results[index];
                            return ListTile(
                              title: Text(ex['name_en']), // Could toggle EN/DE based on locale
                              subtitle: Text(ex['muscle_group']),
                              onTap: () {
                                Navigator.pop(context); // Close dialog
                                _showLogDetailsDialog(ex); // Open details
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.quickAdd, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabaseService.searchExercises(' '), // Empty query trick or specific method
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                     return ListView.builder(
                       controller: controller,
                       itemCount: snapshot.data!.length,
                       itemBuilder: (context, index) {
                         final ex = snapshot.data![index];
                         final isCustom = ex['is_custom'] == true;
                         final imageUrl = ex['image_url'] as String? ?? ex['video_url'] as String?;
                         
                         return ListTile(
                           leading: Container(
                             width: 56,
                             height: 56,
                             decoration: BoxDecoration(
                               color: AppColors.primary.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: (imageUrl != null && imageUrl.isNotEmpty && !isCustom)
                                 ? ClipRRect(
                                     borderRadius: BorderRadius.circular(8),
                                     child: CachedNetworkImage(
                                       imageUrl: imageUrl,
                                       fit: BoxFit.cover,
                                       placeholder: (context, url) => Container(
                                         color: AppColors.primary.withOpacity(0.1),
                                         child: const Center(
                                           child: CircularProgressIndicator(strokeWidth: 2),
                                         ),
                                       ),
                                       errorWidget: (context, url, error) => Container(
                                         color: AppColors.primary.withOpacity(0.1),
                                         child: const Center(
                                           child: Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                                         ),
                                       ),
                                     ),
                                   )
                                 : const Center(
                                     child: Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                                   ),
                           ),
                           title: Row(
                             children: [
                               Expanded(
                                 child: Text(ex['name_en']),
                               ),
                               if (isCustom)
                                 Container(
                                   margin: const EdgeInsets.only(left: 8),
                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                   decoration: BoxDecoration(
                                     color: AppColors.primary.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                   child: Text(
                                     'Custom',
                                     style: TextStyle(
                                       color: AppColors.primary,
                                       fontSize: 10,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                 ),
                             ],
                           ),
                           subtitle: Text('${ex['muscle_group']} • ${ex['difficulty']}'),
                           trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                           onTap: () => _showLogDetailsDialog(ex),
                         );
                       },
                     );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetailsDialog(Map<String, dynamic> exercise) {
     final setsController = TextEditingController(text: '3');
     final repsController = TextEditingController(text: '10');
     final weightController = TextEditingController(text: '0');
     final imageUrl = exercise['image_url'] as String? ?? exercise['video_url'] as String?;

     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('${AppLocalizations.of(context)!.log} ${exercise['name_en']}'),
         content: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               if (imageUrl != null && imageUrl.isNotEmpty)
                 Container(
                   height: 150,
                   width: double.infinity,
                   margin: const EdgeInsets.only(bottom: 16),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(12),
                     color: AppColors.primary.withOpacity(0.1),
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     child: CachedNetworkImage(
                       imageUrl: imageUrl,
                       fit: BoxFit.cover,
                       placeholder: (context, url) => Container(
                         color: AppColors.primary.withOpacity(0.1),
                         child: const Center(
                           child: CircularProgressIndicator(strokeWidth: 2),
                         ),
                       ),
                       errorWidget: (context, url, error) => Container(
                         color: AppColors.primary.withOpacity(0.1),
                         child: const Center(
                           child: Icon(Icons.fitness_center, size: 48, color: AppColors.primary),
                         ),
                       ),
                     ),
                   ),
                 ),
               TextField(controller: setsController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.sets), keyboardType: TextInputType.number),
               const SizedBox(height: 12),
               TextField(controller: repsController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.reps), keyboardType: TextInputType.number),
               const SizedBox(height: 12),
               TextField(controller: weightController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.exerciseWeight), keyboardType: TextInputType.number),
             ],
           ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (setsController.text.isEmpty) return;
              
              final sets = int.parse(setsController.text);
              final reps = int.parse(repsController.text);
              final weightKg = double.parse(weightController.text);
              
              // Calculate calories
              final calPerRep = (exercise['calories_per_rep'] as num?)?.toDouble() ?? 0.5;
              final caloriesBurned = (sets * reps * calPerRep);
              
              // Log exercise
              await _supabaseService.logExercise(
                exercise: exercise,
                sets: sets,
                reps: reps,
                weightKg: weightKg,
              );
              
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
                _loadData();
                
                // Navigate to confirmation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutConfirmationPage(
                      exercise: exercise,
                      sets: sets,
                      reps: reps,
                      weightKg: weightKg,
                      caloriesBurned: caloriesBurned,
                    ),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.logWorkout),
          ),
         ],
       ),
     );
  }

  Widget _buildMacroExpandedItem(String label, double val, int target, Color color) {
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${val.toInt()}g', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${target}g', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (val / target).clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  color: color,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreGlassCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.healthScore, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                 child: Row(
                   children: [
                     const Text('🔥', style: TextStyle(fontSize: 10)),
                     const SizedBox(width: 4),
                     Text('${_totalBurnedCalories.toInt()} kcal', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                   ],
                 ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_healthScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 4),
                child: Text('/ 10', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              const Spacer(),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppLocalizations.of(context)!.dailyProgress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                    Text(
                      _healthScore > 8 ? AppLocalizations.of(context)!.excellent : _healthScore > 5 ? AppLocalizations.of(context)!.goodProgress : AppLocalizations.of(context)!.needsFocus,
                      style: TextStyle(color: _healthScore > 8 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 8) return Colors.greenAccent;
    if (score > 5) return Colors.blueAccent;
    return Colors.orangeAccent;
  }

  Widget _buildNutrientRings() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _NutrientRingsPainter(
              caloriesProgress: _totalCalories / _calorieTarget,
              proteinProgress: _totalProtein / _proteinTargetGrams,
              carbsProgress: _totalCarbs / _carbsTargetGrams,
              fatProgress: _totalFat / _fatTargetGrams,
            ),
          ),
          if (_headerState == HeaderState.normal)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text((_calorieTarget - _totalCalories).toInt().toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                Text(AppLocalizations.of(context)!.kcalLeft, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }

  void _showHealthScoreDetails() {
    setState(() {
      _headerState = _headerState == HeaderState.health ? HeaderState.normal : HeaderState.health;
    });
  }

  void _showNutrientBreakdown() {
    setState(() {
      _headerState = _headerState == HeaderState.macro ? HeaderState.normal : HeaderState.macro;
    });
  }

  void _showNotificationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }


  Widget _buildScoreDeductionItem(String label, double current, double target, double threshold, double deduction, {bool isGoal = false, bool isInverse = false}) {
    bool hasDeduction = false;
    String status = 'Perfect';
    Color statusColor = Colors.greenAccent;

    if (isGoal) {
      if (current < target * threshold) {
        hasDeduction = true;
        status = '-$deduction';
        statusColor = Colors.orangeAccent;
      }
    } else if (isInverse) {
      if (current > target) {
        hasDeduction = true;
        status = '-$deduction';
        statusColor = Colors.redAccent;
      }
    } else {
      double diff = (current - target).abs();
      if (diff > target * threshold) {
        hasDeduction = true;
        status = '-$deduction';
        statusColor = Colors.orangeAccent;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showBuyCoinsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BuyCoinsSheet(
        currentCoins: _coins,
        onBought: (amount) async {
          await _supabaseService.recordCoinTransaction(
            amount: amount, 
            type: 'PURCHASE', 
            description: 'Top-up: $amount coins'
          );
          
          await _supabaseService.updateProfile({'coins': _coins + amount});
          
          if (mounted) {
            _loadData(); 
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.successCoinsAdded(amount))),
            );
          }
        },
      ),
    );
  }

  Widget _buildActiveChallenges() {
    if (_userChallenges.isEmpty) return const SizedBox.shrink();

    final isDe = Localizations.localeOf(context).languageCode == 'de';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.activeChallenges,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _userChallenges.length,
            itemBuilder: (context, index) {
              final uc = _userChallenges[index];
              final challenge = uc['challenges'];
              if (challenge == null) return const SizedBox.shrink();
              
              final title = isDe ? challenge['title_de'] : challenge['title_en'];
              final progress = (uc['progress'] as num).toDouble();
              final target = (challenge['goal_value'] as num).toDouble();
              final percent = (progress / target).clamp(0.0, 1.0);
              final icon = challenge['icon'] ?? '🏆';

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(percent >= 1.0 ? AppLocalizations.of(context)!.done : '${(percent * 100).toInt()}%', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                        Text('${progress.toInt()} / ${target.toInt()}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class _NutrientRingsPainter extends CustomPainter {
  final double caloriesProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;

  _NutrientRingsPainter({
    required this.caloriesProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    _drawRing(canvas, center, radius, caloriesProgress, Colors.white, 8);
    _drawRing(canvas, center, radius - 14, proteinProgress, Colors.pinkAccent, 6);
    _drawRing(canvas, center, radius - 26, carbsProgress, Colors.cyanAccent, 6);
    _drawRing(canvas, center, radius - 38, fatProgress, Colors.amberAccent, 6);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress, Color color, double strokeWidth) {
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MeshGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: const Alignment(-0.8, -0.6),
      radius: 1.2,
      colors: [
        AppColors.primary.withOpacity(0.8),
        AppColors.secondary.withOpacity(0.9),
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Add some "mesh" glows
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 100, glowPaint..color = Colors.pinkAccent.withOpacity(0.3));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 120, glowPaint..color = Colors.blueAccent.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
