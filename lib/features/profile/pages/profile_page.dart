import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/core/widgets/flow_widgets.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/core/utils/nutrition_utils.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _waterTargetController = TextEditingController();
  final TextEditingController _calorieTargetController = TextEditingController();
  final TextEditingController _proteinTargetController = TextEditingController();
  final TextEditingController _carbsTargetController = TextEditingController();
  final TextEditingController _fatTargetController = TextEditingController();
  final TextEditingController _fiberTargetController = TextEditingController();
  final TextEditingController _sugarTargetController = TextEditingController();
  String _selectedGoal = 'MAINTAIN';
  String _selectedActivity = 'SEDENTARY';
  bool _remindersEnabled = false;
  String? _avatarUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getProfile();
    if (profile != null) {
      // Get latest weight from weight_logs (most recent) or fallback to profile current_weight
      final latestWeight = await _supabaseService.getLatestWeight();
      final weightToDisplay = latestWeight ?? (profile['current_weight'] as num?)?.toDouble() ?? 0.0;
      
      setState(() {
        _profile = profile;
        _nameController.text = profile['full_name'] ?? '';
        _ageController.text = (profile['age'] ?? '').toString();
        _weightController.text = weightToDisplay.toString();
        _targetWeightController.text = (profile['target_weight'] ?? '')
            .toString();
        _heightController.text = (profile['height'] ?? '').toString();
        _selectedGoal = profile['goal'] ?? 'MAINTAIN';
        _selectedActivity = profile['activity_level'] ?? 'SEDENTARY';
        _waterTargetController.text = (profile['daily_water_target'] ?? 2000)
            .toString();
        _remindersEnabled = profile['water_reminders_enabled'] ?? false;
        _avatarUrl = profile['avatar_url'] as String?;
        
        // Load nutrition targets - calculate if missing
        final gender = profile['gender'] ?? 'MALE';
        final currentWeight = (profile['current_weight'] as num?)?.toDouble() ?? 70.0;
        final currentHeight = (profile['height'] as num?)?.toDouble() ?? 170.0;
        final currentAge = (profile['age'] as num?)?.toInt() ?? 25;
        final currentActivity = profile['activity_level'] ?? 'SEDENTARY';
        final currentGoal = profile['goal'] ?? 'MAINTAIN';
        
        // Calculate targets if missing
        final calculatedTargets = NutritionUtils.calculateTargets(
          gender: gender.toString(),
          weight: currentWeight,
          height: currentHeight,
          age: currentAge,
          activityLevel: currentActivity.toString(),
          goal: currentGoal.toString(),
        );
        
        _calorieTargetController.text = (profile['daily_calorie_target'] ?? calculatedTargets['calories'] ?? 2000).toString();
        _proteinTargetController.text = (profile['protein_target_percentage'] ?? calculatedTargets['protein'] ?? 30).toString();
        _carbsTargetController.text = (profile['carbs_target_percentage'] ?? calculatedTargets['carbs'] ?? 40).toString();
        _fatTargetController.text = (profile['fat_target_percentage'] ?? calculatedTargets['fat'] ?? 30).toString();
        _fiberTargetController.text = (profile['fiber_target'] ?? calculatedTargets['fiber'] ?? 25).toString();
        _sugarTargetController.text = (profile['sugar_target'] ?? calculatedTargets['sugar'] ?? 50).toString();
        
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final double weight = double.tryParse(_weightController.text) ?? 70;
      final double height = double.tryParse(_heightController.text) ?? 170;
      final int age = int.tryParse(_ageController.text) ?? 25;
      // Recalculate targets based on new data
      final targets = NutritionUtils.calculateTargets(
        gender: _profile?['gender'] ?? 'MALE',
        weight: weight,
        height: height,
        age: age,
        activityLevel: _selectedActivity,
        goal: _selectedGoal,
      );
      final updatedData = {
        'full_name': _nameController.text,
        'age': age,
        'current_weight': weight,
        'target_weight':
            double.tryParse(_targetWeightController.text) ?? weight,
        'height': height,
        'goal': _selectedGoal,
        'activity_level': _selectedActivity,
        'daily_calorie_target': int.tryParse(_calorieTargetController.text) ?? targets['calories']!,
        'protein_target_percentage': int.tryParse(_proteinTargetController.text) ?? targets['protein']!,
        'carbs_target_percentage': int.tryParse(_carbsTargetController.text) ?? targets['carbs']!,
        'fat_target_percentage': int.tryParse(_fatTargetController.text) ?? targets['fat']!,
        'daily_water_target': int.tryParse(_waterTargetController.text) ?? 2000,
        'water_reminders_enabled': _remindersEnabled,
        'fiber_target': double.tryParse(_fiberTargetController.text) ?? (targets['fiber']?.toDouble() ?? 25.0),
        'sugar_target': double.tryParse(_sugarTargetController.text) ?? (targets['sugar']?.toDouble() ?? 50.0),
      };
      await _supabaseService.updateProfile(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myProfile,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _uploadAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withAlpha(51),
                      backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null || _avatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadAvatar,
                      child: Container(
                        padding: AppSpacing.paddingXs,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildBMICard(),
            const SizedBox(height: AppSpacing.xxxl),
            _buildField(
              AppLocalizations.of(context)!.fullName,
              _nameController,
              Icons.person_outline,
            ),
            _buildField(
              AppLocalizations.of(context)!.ageTitle,
              _ageController,
              Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              AppLocalizations.of(context)!.heightCm,
              _heightController,
              Icons.height,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              AppLocalizations.of(context)!.weightKg,
              _weightController,
              Icons.fitness_center,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              AppLocalizations.of(context)!.targetWeightKg,
              _targetWeightController,
              Icons.flag_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.yourGoal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGoalSelector(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showTrophyRoom,
                    child: Container(
                      padding: AppSpacing.paddingLg,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.orange.shade500]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text(AppLocalizations.of(context)!.trophyRoom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppLocalizations.of(context)!.activityLevel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildActivitySelector(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Nutrition Targets',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              'Daily Calorie Target (kcal)',
              _calorieTargetController,
              Icons.local_fire_department,
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Protein (%)',
                    _proteinTargetController,
                    Icons.fitness_center,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildField(
                    'Carbs (%)',
                    _carbsTargetController,
                    Icons.bolt,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _buildField(
              'Fat (%)',
              _fatTargetController,
              Icons.opacity,
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Fiber Target (g)',
                    _fiberTargetController,
                    Icons.eco,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildField(
                    'Sugar Target (g)',
                    _sugarTargetController,
                    Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              AppLocalizations.of(context)!.waterSettings,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              AppLocalizations.of(context)!.dailyWaterTarget,
              _waterTargetController,
              Icons.local_drink,
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.waterReminders,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.waterRemindersDesc,
                style: const TextStyle(fontSize: 12),
              ),
              value: _remindersEnabled,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _remindersEnabled = val),
            ),
            SizedBox(height: AppSpacing.xxxl + 8),
            FlowButton(
              text: AppLocalizations.of(context)!.saveChanges,
              isLoading: _isSaving,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildDeleteAccountButton(),
            SizedBox(height: AppSpacing.xxxl + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Wrap(
      spacing: 12,
      children: ['LOSE', 'MAINTAIN', 'GAIN'].map((goal) {
        final isSelected = _selectedGoal == goal;
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = goal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.primary.withAlpha(51)),
            ),
            child: Text(
              goal == 'LOSE'
                  ? AppLocalizations.of(context)!.loseWeight
                  : (goal == 'MAINTAIN'
                        ? AppLocalizations.of(context)!.maintainHealth
                        : AppLocalizations.of(context)!.gainMuscle),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySelector() {
    final levels = [
      'SEDENTARY',
      'LIGHTLY ACTIVE',
      'MODERATELY ACTIVE',
      'VERY ACTIVE',
    ];
    return Column(
      children: levels.map((level) {
        final isSelected = _selectedActivity == level;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedActivity = level),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(25)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    level == 'SEDENTARY'
                        ? AppLocalizations.of(context)!.sedentary
                        : (level == 'LIGHTLY ACTIVE'
                              ? AppLocalizations.of(context)!.lightlyActive
                              : (level == 'MODERATELY ACTIVE'
                                    ? AppLocalizations.of(
                                        context,
                                      )!.moderatelyActive
                                    : AppLocalizations.of(
                                        context,
                                      )!.veryActive)),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBMICard() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    if (weight == 0 || height == 0) return const SizedBox.shrink();
    final bmi = NutritionUtils.calculateBMI(weight, height);
    final status = NutritionUtils.getBMIStatus(bmi);
    // Ideal weight range for BMI 18.5 - 24.9
    final hMeters = height / 100;
    final lowWeight = 18.5 * hMeters * hMeters;
    final highWeight = 24.9 * hMeters * hMeters;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.currentBmi,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status == 'Normal'
                    ? AppLocalizations.of(context)!.normal
                    : status,
                style: TextStyle(
                  color: status == 'Normal' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bmi.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.idealWeightRange,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lowWeight.toStringAsFixed(1)} kg - ${highWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAvatar() async {
    try {
      final avatarUrl = await _supabaseService.uploadAvatar();
      if (avatarUrl != null && mounted) {
        setState(() {
          _avatarUrl = avatarUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.avatarUpdatedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUploadingAvatar(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccount),
        content: Text(
          AppLocalizations.of(context)!.deleteAccountConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Note: User account deletion should be handled server-side
        // For now, we'll show a message to contact support
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.contactSupportToDelete),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Alternative: If you have a server endpoint for account deletion, call it here
        // await _supabaseService.deleteAccount();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorContactSupport(e.toString())),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.dangerZone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.deleteAccountDescription,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                AppLocalizations.of(context)!.deleteMyAccount,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrophyRoom() {
    // Sync achievements from completed challenges before showing
    _supabaseService.syncAchievementsFromCompletedChallenges();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.hallOfFame + ' 🏆', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _supabaseService.getAchievements(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                     final achievements = snapshot.data!;
                     if (achievements.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.noTrophiesYet, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Text(AppLocalizations.of(context)!.completeChallengesToEarn, style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        );
                     }
                     
                     return RefreshIndicator(
                       onRefresh: () async {
                         // Sync achievements and refresh
                         await _supabaseService.syncAchievementsFromCompletedChallenges();
                         if (mounted) {
                           setState(() {});
                         }
                       },
                       child: GridView.builder(
                         controller: scrollController,
                         padding: const EdgeInsets.all(24),
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                           crossAxisCount: 2,
                           crossAxisSpacing: 16,
                           mainAxisSpacing: 16,
                         ),
                         itemCount: achievements.length,
                         itemBuilder: (context, index) {
                           return Container(
                             decoration: BoxDecoration(
                               color: AppColors.background,
                               borderRadius: BorderRadius.circular(24),
                               border: Border.all(color: Colors.orange.withOpacity(0.3)),
                             ),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const Icon(Icons.workspace_premium, size: 48, color: Colors.orange),
                                 const SizedBox(height: 12),
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 8),
                                   child: Text(
                                     achievements[index],
                                     textAlign: TextAlign.center,
                                     style: const TextStyle(fontWeight: FontWeight.bold),
                                   ),
                                 ),
                               ],
                             ),
                           );
                         },
                       ),
                     );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
