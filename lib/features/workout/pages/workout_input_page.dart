import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class WorkoutInputPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const WorkoutInputPage({
    super.key,
    required this.exercise,
  });

  @override
  State<WorkoutInputPage> createState() => _WorkoutInputPageState();
}

class _WorkoutInputPageState extends State<WorkoutInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController(text: '1');
  final _repsController = TextEditingController(text: '0');
  final _weightController = TextEditingController(text: '0');
  final _durationController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _routineNameController = TextEditingController();
  
  final SupabaseService _supabaseService = SupabaseService();
  bool _isCardio = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  
  // Planning options
  bool _isPlanned = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saveAsRoutine = false;

  @override
  void initState() {
    super.initState();
    // Check if exercise is cardio based on muscle_group
    final muscleGroup = widget.exercise['muscle_group'] as String? ?? '';
    _isCardio = muscleGroup.toLowerCase() == 'cardio';
    _loadUserProfile();
    
    // Add listeners to update calories in real-time
    _setsController.addListener(_updateCalories);
    _repsController.addListener(_updateCalories);
    _weightController.addListener(_updateCalories);
    _durationController.addListener(_updateCalories);
  }
  
  void _updateCalories() {
    setState(() {}); // Trigger rebuild to update calories display
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _setsController.removeListener(_updateCalories);
    _repsController.removeListener(_updateCalories);
    _weightController.removeListener(_updateCalories);
    _durationController.removeListener(_updateCalories);
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _routineNameController.dispose();
    super.dispose();
  }

  double _calculateCalories() {
    if (_isLoadingProfile || _userProfile == null) {
      return 0.0;
    }
    
    // Get user data
    final userWeight = (_userProfile!['current_weight'] as num?)?.toDouble() ?? 70.0; // kg
    final userHeight = (_userProfile!['height'] as num?)?.toDouble() ?? 170.0; // cm
    final userGender = (_userProfile!['gender'] as String?) ?? 'MALE';
    
    final sets = int.tryParse(_setsController.text) ?? 1;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weightKg = double.tryParse(_weightController.text) ?? 0.0; // Weight used in exercise
    final durationMinutes = int.tryParse(_durationController.text) ?? 0;
    
    final exerciseName = (widget.exercise['name_en'] ?? '').toLowerCase();
    final muscleGroup = (widget.exercise['muscle_group'] as String? ?? '').toLowerCase();
    
    // Calculate total weight lifted (for strength exercises)
    final totalWeightLifted = sets * reps * (weightKg > 0 ? weightKg : userWeight * 0.6); // If no weight, estimate 60% bodyweight
    
    if (_isCardio || durationMinutes > 0) {
      // Cardio exercises - use MET (Metabolic Equivalent of Task) formula
      // Calories = MET × weight(kg) × time(hours)
      
      double metValue = 3.5; // Default moderate intensity
      
      if (exerciseName.contains('run') || exerciseName.contains('jog')) {
        // Running: 8-12 MET depending on speed (we'll use 10 MET for moderate)
        metValue = 10.0;
      } else if (exerciseName.contains('walk')) {
        // Walking: 3-5 MET depending on speed
        metValue = 3.5;
      } else if (exerciseName.contains('bike') || exerciseName.contains('cycling')) {
        // Cycling: 6-10 MET
        metValue = 8.0;
      } else if (exerciseName.contains('swim')) {
        // Swimming: 6-10 MET
        metValue = 8.0;
      } else if (exerciseName.contains('row')) {
        // Rowing: 6-12 MET
        metValue = 7.0;
      } else if (exerciseName.contains('yoga')) {
        // Yoga: 2-3 MET
        metValue = 2.5;
      } else if (exerciseName.contains('dance')) {
        // Dancing: 4-7 MET
        metValue = 5.0;
      } else {
        // Other cardio: estimate based on intensity
        metValue = 6.0;
      }
      
      // Adjust MET for gender (males typically have slightly higher MET)
      if (userGender == 'FEMALE') {
        metValue *= 0.9; // Slightly lower for females
      }
      
      // Calculate calories: MET × weight(kg) × time(hours)
      final calories = metValue * userWeight * (durationMinutes / 60.0);
      return calories;
      
    } else if (reps > 0 && sets > 0) {
      // Strength training exercises
      // Formula: Calories ≈ 0.5 × total_weight_lifted(kg) × reps + base metabolic cost
      
      // Base metabolic cost per set (resting + movement)
      final baseCaloriesPerSet = 5.0; // Base calories for movement and rest
      
      // Work done calories (lifting weight)
      // For bodyweight exercises, use estimated bodyweight percentage
      final effectiveWeight = weightKg > 0 ? weightKg : (userWeight * 0.6);
      final workCalories = 0.5 * effectiveWeight * reps * sets;
      
      // Additional calories based on exercise intensity
      double intensityMultiplier = 1.0;
      if (muscleGroup.contains('legs') || muscleGroup.contains('full body')) {
        intensityMultiplier = 1.3; // Legs and full body exercises burn more
      } else if (muscleGroup.contains('cardio')) {
        intensityMultiplier = 1.5;
      }
      
      // Total calories = work done + base metabolic + intensity adjustment
      final totalCalories = (workCalories + (baseCaloriesPerSet * sets)) * intensityMultiplier;
      
      // Add gender adjustment
      if (userGender == 'FEMALE') {
        return totalCalories * 0.9;
      }
      
      return totalCalories;
      
    } else if (sets > 0) {
      // Only sets provided (e.g., planks, holds)
      // Estimate based on duration and bodyweight
      // Assume ~30 seconds per set for isometric exercises
      final estimatedDurationMinutes = sets * 0.5;
      final metValue = 3.0; // Moderate intensity for isometric exercises
      return metValue * userWeight * (estimatedDurationMinutes / 60.0);
    }
    
    return 0.0;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isPlanned && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectDatePlannedWorkout)),
      );
      return;
    }
    
    if (_saveAsRoutine && _routineNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterRoutineName)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sets = int.tryParse(_setsController.text) ?? 1;
      final reps = int.tryParse(_repsController.text) ?? 0;
      final weightKg = double.tryParse(_weightController.text) ?? 0.0;
      final durationMinutes = int.tryParse(_durationController.text) ?? 0;
      final durationSeconds = durationMinutes * 60;
      final caloriesBurned = _calculateCalories();

      if (_isPlanned) {
        // Plan workout for future
        final exercises = [
          {
            'exercise_id': widget.exercise['id'],
            'exercise_name': widget.exercise['name_en'],
            'sets': sets,
            'reps': reps,
            'weight_kg': weightKg,
          }
        ];

        await _supabaseService.planWorkout(
          scheduledDate: _selectedDate!,
          scheduledTime: _selectedTime,
          exercises: exercises,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.workoutPlannedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Save as completed workout
        await _supabaseService.logExercise(
          exercise: widget.exercise,
          sets: sets,
          reps: reps,
          weightKg: weightKg,
          durationSeconds: durationSeconds,
          caloriesBurned: caloriesBurned, // Pass calculated calories
        );

        // Save as routine if requested
        if (_saveAsRoutine) {
          final exercises = [
            {
              'exercise_id': widget.exercise['id'],
              'exercise_name': widget.exercise['name_en'],
              'sets': sets,
              'reps': reps,
              'weight_kg': weightKg,
            }
          ];

          await _supabaseService.saveWorkoutRoutine(
            name: _routineNameController.text.trim(),
            description: _notesController.text.trim(),
            exercises: exercises,
            totalCalories: caloriesBurned,
            muscleGroups: [widget.exercise['muscle_group'] as String],
            difficulty: widget.exercise['difficulty'] as String,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.workoutLoggedKcal(caloriesBurned.toStringAsFixed(1))),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.exercise['name_en'] ?? widget.exercise['name_de'] ?? 'Exercise';
    final imageUrl = widget.exercise['image_url'] as String? ?? widget.exercise['video_url'] as String?;
    final isCustom = widget.exercise['is_custom'] == true;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logWorkout),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exercise image/icon
            if (imageUrl != null && imageUrl.isNotEmpty && !isCustom)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Center(
                        child: Icon(Icons.fitness_center, color: AppColors.primary, size: 64),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center, color: AppColors.primary, size: 64),
                ),
              ),
            
            // Exercise name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCustom)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
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
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sets
            TextFormField(
              controller: _setsController,
              decoration: const InputDecoration(
                labelText: 'Sets',
                border: OutlineInputBorder(),
                helperText: 'Number of sets',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final sets = int.tryParse(value ?? '');
                if (sets == null || sets < 1) {
                  return 'Please enter at least 1 set';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Reps (if not cardio)
            if (!_isCardio)
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: 'Reps per set',
                  border: OutlineInputBorder(),
                  helperText: 'Number of repetitions per set',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final reps = int.tryParse(value ?? '0');
                  if (reps == null || reps < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            if (!_isCardio) const SizedBox(height: 16),
            // Duration (if cardio)
            if (_isCardio)
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                  helperText: 'Duration of the exercise in minutes',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final duration = int.tryParse(value ?? '0');
                  if (duration == null || duration < 1) {
                    return 'Please enter duration in minutes';
                  }
                  return null;
                },
              ),
            if (_isCardio) const SizedBox(height: 16),
            // Weight
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                helperText: 'Weight used (0 for bodyweight/cardio)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final weight = double.tryParse(value ?? '0');
                if (weight == null || weight < 0) {
                  return 'Please enter a valid weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Estimated calories
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Calories:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isLoadingProfile 
                            ? 'Calculating...' 
                            : '${_calculateCalories().toStringAsFixed(1)} kcal',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (!_isLoadingProfile && _userProfile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Based on: ${(_userProfile!['current_weight'] as num?)?.toStringAsFixed(1) ?? '70'}kg, ${(_userProfile!['height'] as num?)?.toStringAsFixed(0) ?? '170'}cm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                helperText: 'Add any notes about this workout',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Plan workout option
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.planForLater),
              subtitle: Text(AppLocalizations.of(context)!.scheduleWorkoutFuture),
              value: _isPlanned,
              onChanged: (value) {
                setState(() {
                  _isPlanned = value ?? false;
                  if (!_isPlanned) {
                    _selectedDate = null;
                    _selectedTime = null;
                  }
                });
              },
            ),
            if (_isPlanned) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Save as routine option
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.saveAsRoutine),
              subtitle: Text(AppLocalizations.of(context)!.saveWorkoutReusable),
              value: _saveAsRoutine,
              onChanged: (value) {
                setState(() {
                  _saveAsRoutine = value ?? false;
                });
              },
            ),
            if (_saveAsRoutine) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _routineNameController,
                decoration: const InputDecoration(
                  labelText: 'Routine Name',
                  border: OutlineInputBorder(),
                  helperText: 'Enter a name for this routine',
                ),
                validator: (value) {
                  if (_saveAsRoutine && (value == null || value.trim().isEmpty)) {
                    return 'Please enter a routine name';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isPlanned ? 'Plan Workout' : 'Save Workout'),
            ),
            const SizedBox(height: 100), // Extra padding for bottom navigation
          ],
        ),
      ),
    );
  }
}
