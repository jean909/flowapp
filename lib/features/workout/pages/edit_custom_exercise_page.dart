import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';

class EditCustomExercisePage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const EditCustomExercisePage({
    super.key,
    required this.exercise,
  });

  @override
  State<EditCustomExercisePage> createState() => _EditCustomExercisePageState();
}

class _EditCustomExercisePageState extends State<EditCustomExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameDeController = TextEditingController();
  final _instructionsEnController = TextEditingController();
  final _instructionsDeController = TextEditingController();
  final _caloriesPerRepController = TextEditingController();
  
  final SupabaseService _supabaseService = SupabaseService();
  
  String _selectedMuscleGroup = 'Full Body';
  String _selectedEquipment = 'None';
  String _selectedDifficulty = 'Beginner';
  bool _isSaving = false;

  final List<String> _muscleGroups = [
    'Chest',
    'Legs',
    'Back',
    'Abs',
    'Arms',
    'Shoulders',
    'Cardio',
    'Full Body',
  ];

  final List<String> _equipmentOptions = [
    'None',
    'Dumbbells',
    'Resistance Band',
    'Barbell',
    'Kettlebell',
    'Machine',
    'Other',
  ];

  final List<String> _difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameDeController.dispose();
    _instructionsEnController.dispose();
    _instructionsDeController.dispose();
    _caloriesPerRepController.dispose();
    super.dispose();
  }

  void _loadExerciseData() {
    _nameEnController.text = widget.exercise['name_en'] ?? '';
    _nameDeController.text = widget.exercise['name_de'] ?? '';
    _instructionsEnController.text = widget.exercise['instructions_en'] ?? '';
    _instructionsDeController.text = widget.exercise['instructions_de'] ?? '';
    _caloriesPerRepController.text = (widget.exercise['calories_per_rep'] ?? 0.5).toString();
    
    _selectedMuscleGroup = widget.exercise['muscle_group'] ?? 'Full Body';
    _selectedEquipment = widget.exercise['equipment'] ?? 'None';
    _selectedDifficulty = widget.exercise['difficulty'] ?? 'Beginner';
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final exerciseId = widget.exercise['id'] as String;
      
      await _supabaseService.updateCustomExercise(
        exerciseId: exerciseId,
        nameEn: _nameEnController.text.trim(),
        nameDe: _nameDeController.text.trim(),
        muscleGroup: _selectedMuscleGroup,
        equipment: _selectedEquipment,
        difficulty: _selectedDifficulty,
        instructionsEn: _instructionsEnController.text.trim(),
        instructionsDe: _instructionsDeController.text.trim(),
        caloriesPerRep: double.tryParse(_caloriesPerRepController.text) ?? 0.5,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exerciseUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingExercise(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editCustomExercise),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveExercise,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
            // Name (English)
            TextFormField(
              controller: _nameEnController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name (English)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Name (German)
            TextFormField(
              controller: _nameDeController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name (German)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Muscle Group
            DropdownButtonFormField<String>(
              value: _selectedMuscleGroup,
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                border: OutlineInputBorder(),
              ),
              items: _muscleGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMuscleGroup = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Equipment
            DropdownButtonFormField<String>(
              value: _selectedEquipment,
              decoration: const InputDecoration(
                labelText: 'Equipment',
                border: OutlineInputBorder(),
              ),
              items: _equipmentOptions.map((equipment) {
                return DropdownMenuItem(
                  value: equipment,
                  child: Text(equipment),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEquipment = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Difficulty
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items: _difficultyLevels.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDifficulty = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Calories per rep
            TextFormField(
              controller: _caloriesPerRepController,
              decoration: const InputDecoration(
                labelText: 'Calories per Rep (or per minute for cardio)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter calories per rep';
                }
                final calories = double.tryParse(value);
                if (calories == null || calories < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Instructions (English)
            TextFormField(
              controller: _instructionsEnController,
              decoration: const InputDecoration(
                labelText: 'Instructions (English)',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),
            // Instructions (German)
            TextFormField(
              controller: _instructionsDeController,
              decoration: const InputDecoration(
                labelText: 'Instructions (German)',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveExercise,
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
                  : Text(AppLocalizations.of(context)!.saveChanges),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

