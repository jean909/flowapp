import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlannedWorkoutsPage extends StatefulWidget {
  const PlannedWorkoutsPage({super.key});

  @override
  State<PlannedWorkoutsPage> createState() => _PlannedWorkoutsPageState();
}

class _PlannedWorkoutsPageState extends State<PlannedWorkoutsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _plannedWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlannedWorkouts();
  }

  Future<void> _loadPlannedWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final workouts = await _supabaseService.getPlannedWorkouts(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 30)),
      );
      setState(() {
        _plannedWorkouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    try {
      await _supabaseService.deletePlannedWorkout(workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.workoutDeleted)),
        );
        _loadPlannedWorkouts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  void _showDeleteDialog(String workoutId, String workoutName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteWorkout),
        content: Text(AppLocalizations.of(context)!.deleteWorkoutConfirmWithName(workoutName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkout(workoutId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.plannedWorkouts),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plannedWorkouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPlannedWorkouts,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlannedWorkouts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plannedWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = _plannedWorkouts[index];
                      final scheduledDate = DateTime.parse(workout['scheduled_date'] as String);
                      final scheduledTime = workout['scheduled_time'] as String?;
                      final exercises = workout['exercises'] as List<dynamic>? ?? [];
                      final notes = workout['notes'] as String?;

                      final isPast = scheduledDate.isBefore(DateTime.now());
                      final isToday = scheduledDate.year == DateTime.now().year &&
                          scheduledDate.month == DateTime.now().month &&
                          scheduledDate.day == DateTime.now().day;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isToday
                              ? BorderSide(color: AppColors.primary, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 18,
                                              color: isToday
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormat('EEEE, MMMM d', Localizations.localeOf(context).languageCode == 'de' ? 'de_DE' : 'en_US').format(scheduledDate),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isToday
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (isToday) ...[
                                              const SizedBox(width: 8),
                                              Container(
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
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (scheduledTime != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                                              const SizedBox(width: 8),
                                              Text(
                                                scheduledTime,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            Text(l10n.delete),
                                          ],
                                        ),
                                        onTap: () => _showDeleteDialog(
                                          workout['id'] as String,
                                          '${exercises.length} ${l10n.exercises}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (exercises.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                ...exercises.take(3).map((exercise) {
                                  final exerciseName = exercise['exercise_name'] as String? ?? 'Unknown';
                                  final sets = exercise['sets'] as int? ?? 0;
                                  final reps = exercise['reps'] as int? ?? 0;
                                  final weight = exercise['weight_kg'] as num? ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            exerciseName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Text(
                                          '$sets x $reps',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        if (weight > 0) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '${weight.toStringAsFixed(1)}kg',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                                if (exercises.length > 3)
                                  Text(
                                    '+ ${exercises.length - 3} ${l10n.more}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                  ),
                              ],
                              if (notes != null && notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.note, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          notes,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

