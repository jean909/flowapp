import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/features/workout/pages/planned_workouts_page.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/notification_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  static String _dateLocale(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'de') return 'de_DE';
    if (code == 'ro') return 'ro_RO';
    return 'en_US';
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final planned = await _supabaseService.getPlannedWorkouts(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7)),
      );

      final notifications = <Map<String, dynamic>>[];
      final todayDate = DateTime(now.year, now.month, now.day);

      for (var workout in planned) {
        final scheduledDate = DateTime.parse(workout['scheduled_date'] as String);
        final scheduledTime = workout['scheduled_time'] as String?;
        final workoutDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);

        if (workoutDate.isAtSameMomentAs(todayDate) || workoutDate.isAfter(todayDate)) {
          notifications.add({
            'type': 'workout_reminder',
            'date': scheduledDate,
            'time': scheduledTime,
            'isToday': workoutDate.isAtSameMomentAs(todayDate),
            'workout': workout,
          });
        }
      }

      notifications.add({
        'type': 'system',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      });

      notifications.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        final plannedForSchedule = notifications
            .where((n) => n['type'] == 'workout_reminder')
            .map((n) => n['workout'] as Map<String, dynamic>)
            .toList();
        if (plannedForSchedule.isNotEmpty) _scheduleLocalNotifications(plannedForSchedule);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _scheduleLocalNotifications(List<Map<String, dynamic>> planned) async {
    if (!mounted) return;
    try {
      await NotificationService().requestPermission();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final localeTag = _dateLocale(context);
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
    } catch (_) {}
  }

  String _formatNotificationDate(BuildContext context, DateTime date, String? time, bool isToday) {
    final locale = _dateLocale(context);
    if (isToday && time != null && time.isNotEmpty) {
      return '${AppLocalizations.of(context)!.today} · $time';
    }
    return DateFormat('EEEE, MMM d', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = _dateLocale(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noNotifications,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isWorkout = n['type'] == 'workout_reminder';
                      final isToday = n['isToday'] == true;
                      final date = n['date'] as DateTime;
                      final time = n['time'] as String?;

                      String title;
                      String message;
                      if (isWorkout) {
                        title = l10n.workoutScheduled;
                        final dateStr = DateFormat('EEEE, MMMM d', locale).format(date);
                        message = (time != null && time.isNotEmpty)
                            ? l10n.workoutScheduledForDateAtTime(dateStr, time)
                            : l10n.workoutScheduledForDate(dateStr);
                      } else {
                        title = l10n.welcomeToFlow;
                        message = l10n.startTrackingGoals;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isToday && isWorkout
                              ? BorderSide(color: AppColors.primary, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          onTap: isWorkout
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PlannedWorkoutsPage(),
                                    ),
                                  )
                              : null,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isWorkout
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.textSecondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWorkout ? Icons.fitness_center : Icons.info,
                              color: isWorkout ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatNotificationDate(context, date, time, isToday),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: isToday && isWorkout
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.today,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

