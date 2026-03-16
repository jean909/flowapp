import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/core/widgets/flow_widgets.dart';
import 'package:flow/features/onboarding/models/onboarding_data.dart';
import 'package:flow/features/onboarding/pages/auth_page.dart';
import 'package:flow/features/onboarding/pages/analyzing_info_page.dart';
import 'package:flow/l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final OnboardingData _data = OnboardingData();

  // Health quotes for carousel
  final List<String> _quotes = [
    "Health is not valued till sickness comes.",
    "A journey of a thousand miles begins with a single step.",
    "Your body hears everything your mind says.",
    "Consistency is more important than perfection.",
    "Invest in your health, it pays the best interest."
  ];
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _startQuoteTimer();
  }

  void _startQuoteTimer() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AnalyzingInfoPage(onboardingData: _data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Animation
          AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: _currentPage == 0
                ? Container(
                    key: const ValueKey('bg_intro'),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/onboarding_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withAlpha(150), Colors.black.withAlpha(50)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: ValueKey<int>(_currentPage),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(26),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
          ),

          // Edge-to-edge Banner for Welcome
          if (_currentPage == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/flow_banner.png',
                fit: BoxFit.fitWidth,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.lg),
              child: Column(
                children: [
                  if (_currentPage > 0) _buildProgressIndicator(),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      children: [
                        _buildIntroductionStep(),
                        _buildNicknameStep(),
                        _buildGoalStep(),
                        _buildAreasToImproveStep(),
                        _buildGenderStep(),
                        _buildAgeStep(),
                        _buildBodyMetricsStep(),
                        _buildTargetWeightStep(),
                        _buildActivityStep(),
                        _buildSmokingStep(),
                        _buildDietTypeStep(),
                        _buildAllergensStep(),
                        _buildFoodPreferencesStep(),
                        _buildCookingFrequencyStep(),
                        _buildWaterIntakeStep(),
                        _buildSleepScheduleStep(),
                        _buildWorkoutTimeStep(),
                        _buildHealthConditionsStep(),
                      ],
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        if (_currentPage == 0) ...[
                          FlowButton(
                            text: AppLocalizations.of(context)!.getStarted,
                            onPressed: _nextPage,
                          ),
                          SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            height: AppSpacing.touchTarget + 12,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AuthPage(isSignUp: false)),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.signIn,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              if (_currentPage > 9) // Skip button for optional questions
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _nextPage,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Skip',
                                      style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              if (_currentPage > 9) const SizedBox(width: 12),
                              Expanded(
                                flex: _currentPage > 9 ? 1 : 1,
                                child: FlowButton(
                                  text: _currentPage == 17
                                      ? AppLocalizations.of(context)!.finish
                                      : AppLocalizations.of(context)!.continueText,
                                  onPressed: _isStepValid() ? _nextPage : null,
                                ),
                              ),
                            ],
                          ),
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutQuint,
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.back,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ],
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

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(18, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index + 1 <= _currentPage ? AppColors.primary : Colors.black12,
              borderRadius: BorderRadius.circular(2),
              boxShadow: index + 1 <= _currentPage
                  ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 4)]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIntroductionStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        SizedBox(
          height: 120,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Text(
              _quotes[_quoteIndex],
              key: ValueKey<int>(_quoteIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.nicknameTitle,
      subtitle: AppLocalizations.of(context)!.nicknameSubtitle,
      children: [
        TextField(
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.nicknameHint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(50)),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            _data.nickname = val;
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.missionTitle,
      subtitle: AppLocalizations.of(context)!.missionSubtitle,
      children: [
        SelectionCard(
          title: AppLocalizations.of(context)!.loseWeight,
          subtitle: AppLocalizations.of(context)!.loseWeightDesc,
          icon: Icons.monitor_weight_outlined,
          isSelected: _data.goal == 'LOSE',
          onTap: () => setState(() => _data.goal = 'LOSE'),
        ),
        const SizedBox(height: 16),
        SelectionCard(
          title: AppLocalizations.of(context)!.maintainHealth,
          subtitle: AppLocalizations.of(context)!.maintainHealthDesc,
          icon: Icons.favorite_outline,
          isSelected: _data.goal == 'MAINTAIN',
          onTap: () => setState(() => _data.goal = 'MAINTAIN'),
        ),
        const SizedBox(height: 16),
        SelectionCard(
          title: AppLocalizations.of(context)!.gainMuscle,
          subtitle: AppLocalizations.of(context)!.gainMuscleDesc,
          icon: Icons.fitness_center,
          isSelected: _data.goal == 'GAIN',
          onTap: () => setState(() => _data.goal = 'GAIN'),
        ),
      ],
    );
  }

  Widget _buildAreasToImproveStep() {
    final areasToImprove = [
      'Mental Health',
      'More Energy',
      'Better Sleep',
      'Reduce Stress',
      'Weight Management',
      'Muscle Building',
      'Cardiovascular Health',
      'Flexibility & Mobility',
      'Strength Training',
      'Endurance',
      'Balance & Coordination',
      'Posture Improvement',
      'Stress Management',
      'Mindfulness',
      'Nutrition Knowledge',
      'Meal Planning',
      'Hydration',
      'Recovery & Rest',
      'Injury Prevention',
      'Consistency & Habits',
      'Boost Immunity',
      'Improve Digestion',
    ];

    return _buildStepContainer(
      title: AppLocalizations.of(context)!.areasToImprove,
      subtitle: AppLocalizations.of(context)!.areasToImproveSubtitle,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: areasToImprove.map((area) {
            final isSelected = _data.secondaryGoals.contains(area);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _data.secondaryGoals.remove(area);
                  } else {
                    _data.secondaryGoals.add(area);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary.withAlpha(50),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8)]
                      : [],
                ),
                child: Text(
                  area,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.genderTitle,
      subtitle: AppLocalizations.of(context)!.genderSubtitle,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(AppLocalizations.of(context)!.male, Icons.male),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(AppLocalizations.of(context)!.female, Icons.female),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    bool isSelected = _data.gender == gender.toUpperCase();
    return GestureDetector(
      onTap: () => setState(() => _data.gender = gender.toUpperCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 160,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withAlpha(10),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              gender,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.ageTitle,
      subtitle: AppLocalizations.of(context)!.ageSubtitle,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 48, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '25',
            hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(50)),
            border: InputBorder.none,
            suffixText: 'y/o',
            suffixStyle: const TextStyle(fontSize: 20, color: AppColors.textSecondary),
          ),
          onChanged: (val) {
            _data.age = int.tryParse(val);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildBodyMetricsStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.bodyMetricsTitle,
      subtitle: AppLocalizations.of(context)!.bodyMetricsSubtitle,
      children: [
        _buildMetricField(
          AppLocalizations.of(context)!.height,
          'cm',
          (val) {
            _data.height = double.tryParse(val);
            setState(() {});
          },
        ),
        const SizedBox(height: 24),
        _buildMetricField(
          AppLocalizations.of(context)!.currentWeight,
          'kg',
          (val) {
            _data.currentWeight = double.tryParse(val);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildTargetWeightStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.targetWeightTitle,
      subtitle: AppLocalizations.of(context)!.targetWeightSubtitle,
      children: [
        _buildMetricField(
          AppLocalizations.of(context)!.targetWeightTitle,
          'kg',
          (val) {
            _data.targetWeight = double.tryParse(val);
            setState(() {});
          },
        ),
      ],
    );
  }

  static const List<String> _activityLevelKeys = [
    'SEDENTARY',
    'LIGHTLY ACTIVE',
    'MODERATELY ACTIVE',
    'VERY ACTIVE',
  ];

  Widget _buildActivityStep() {
    final l10n = AppLocalizations.of(context)!;
    final titles = [l10n.sedentary, l10n.lightlyActive, l10n.moderatelyActive, l10n.veryActive];
    final subtitles = [l10n.sedentaryDesc, l10n.lightlyActiveDesc, l10n.moderatelyActiveDesc, l10n.veryActiveDesc];
    final icons = [
      Icons.airline_seat_recline_normal,
      Icons.directions_walk,
      Icons.directions_run,
      Icons.bolt,
    ];
    return _buildStepContainer(
      title: l10n.activityTitle,
      subtitle: l10n.activitySubtitle,
      children: [
        for (int i = 0; i < _activityLevelKeys.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildActivityCard(
            _activityLevelKeys[i],
            titles[i],
            subtitles[i],
            icons[i],
          ),
        ],
      ],
    );
  }

  Widget _buildSmokingStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.smokingTitle,
      subtitle: AppLocalizations.of(context)!.smokingSubtitle,
      children: [
        Row(
          children: [
            Expanded(
              child: SelectionCard(
                title: AppLocalizations.of(context)!.yes,
                icon: Icons.smoking_rooms,
                isSelected: _data.isSmoker == true,
                onTap: () => setState(() => _data.isSmoker = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SelectionCard(
                title: AppLocalizations.of(context)!.no,
                icon: Icons.smoke_free,
                isSelected: _data.isSmoker == false,
                onTap: () => setState(() => _data.isSmoker = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return FadeInRight(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 40),
            ...children,
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricField(String label, String unit, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withAlpha(5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            suffixText: unit,
            suffixStyle: const TextStyle(color: AppColors.primary),
            contentPadding: const EdgeInsets.all(20),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActivityCard(String levelKey, String title, String subtitle, IconData icon) {
    return SelectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isSelected: _data.activityLevel == levelKey,
      onTap: () => setState(() => _data.activityLevel = levelKey),
    );
  }

  /// Returns true if current step has valid data (required fields filled).
  bool _isStepValid() {
    switch (_currentPage) {
      case 1: // Nickname
        return _data.nickname != null && _data.nickname!.trim().isNotEmpty;
      case 2: // Goal
        return _data.goal != null && _data.goal!.isNotEmpty;
      case 4: // Gender
        return _data.gender != null && _data.gender!.isNotEmpty;
      case 5: // Age
        return _data.age != null && _data.age! >= 13 && _data.age! <= 120;
      case 6: // Body metrics (height + current weight)
        final h = _data.height;
        final w = _data.currentWeight;
        return h != null && w != null &&
            h >= 100 && h <= 250 &&
            w >= 30 && w <= 300;
      case 7: // Target weight
        final t = _data.targetWeight;
        return t != null && t >= 30 && t <= 300;
      case 8: // Activity
        return _data.activityLevel != null && _data.activityLevel!.isNotEmpty;
      case 9: // Smoking
        return _data.isSmoker != null;
      default:
        return true;
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (!_isStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentPage == 6
                ? AppLocalizations.of(context)!.onboardingBodyMetricsHint
                : AppLocalizations.of(context)!.onboardingCompleteRequired,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentPage < 17) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuint,
      );
    } else {
      _finishOnboarding();
    }
  }
  
  // New optional steps
  Widget _buildDietTypeStep() {
    final dietTypes = ['None', 'Vegetarian', 'Vegan', 'Keto', 'Mediterranean', 'Paleo', 'Low Carb', 'Gluten Free'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.dietType,
      subtitle: AppLocalizations.of(context)!.dietTypeSubtitle,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: dietTypes.map((diet) {
            final isSelected = _data.dietType == diet;
            return FilterChip(
              label: Text(diet),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _data.dietType = selected ? diet : null);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildAllergensStep() {
    final allergens = ['Peanuts', 'Tree Nuts', 'Dairy', 'Eggs', 'Fish', 'Shellfish', 'Soy', 'Wheat', 'Sesame'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.allergens,
      subtitle: AppLocalizations.of(context)!.allergensSubtitle,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: allergens.map((allergen) {
            final isSelected = _data.allergies.contains(allergen);
            return FilterChip(
              label: Text(allergen),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _data.allergies.add(allergen);
                  } else {
                    _data.allergies.remove(allergen);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildFoodPreferencesStep() {
    final preferences = ['Breakfast Lover', 'Snack Enthusiast', 'Meal Prep Fan', 'Dining Out Often', 'Home Cook', 'Fast Food Occasional'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.foodPreferences,
      subtitle: AppLocalizations.of(context)!.foodPreferencesSubtitle,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: preferences.map((pref) {
            final isSelected = _data.foodPreferences.contains(pref);
            return FilterChip(
              label: Text(pref),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _data.foodPreferences.add(pref);
                  } else {
                    _data.foodPreferences.remove(pref);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCookingFrequencyStep() {
    final frequencies = ['Daily', 'Few times a week', 'Once a week', 'Rarely', 'Never'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.cookingFrequency,
      subtitle: AppLocalizations.of(context)!.cookingFrequencySubtitle,
      children: [
        ...frequencies.map((freq) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectionCard(
            title: freq,
            icon: Icons.restaurant,
            isSelected: _data.cookingFrequency == freq,
            onTap: () => setState(() => _data.cookingFrequency = freq),
          ),
        )),
      ],
    );
  }
  
  Widget _buildWaterIntakeStep() {
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.waterIntake,
      subtitle: AppLocalizations.of(context)!.waterIntakeSubtitle,
      children: [
        _buildMetricField(
          'Daily Water Intake',
          'ml',
          (val) => _data.averageWaterIntake = int.tryParse(val),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [500, 1000, 1500, 2000, 2500].map((amount) {
            return ActionChip(
              label: Text('${amount}ml'),
              onPressed: () => setState(() => _data.averageWaterIntake = amount),
              backgroundColor: _data.averageWaterIntake == amount 
                  ? AppColors.primary.withOpacity(0.2) 
                  : Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSleepScheduleStep() {
    final schedules = ['Early Bird (before 10 PM)', 'Regular (10 PM - 12 AM)', 'Night Owl (after 12 AM)'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.sleepSchedule,
      subtitle: AppLocalizations.of(context)!.sleepScheduleSubtitle,
      children: [
        ...schedules.map((schedule) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectionCard(
            title: schedule,
            icon: Icons.bedtime,
            isSelected: _data.sleepSchedule == schedule,
            onTap: () => setState(() => _data.sleepSchedule = schedule),
          ),
        )),
      ],
    );
  }
  
  Widget _buildWorkoutTimeStep() {
    final times = ['Morning (6 AM - 12 PM)', 'Afternoon (12 PM - 6 PM)', 'Evening (6 PM - 10 PM)', 'Flexible'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.workoutTimePreference,
      subtitle: AppLocalizations.of(context)!.workoutTimePreferenceSubtitle,
      children: [
        ...times.map((time) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectionCard(
            title: time,
            icon: Icons.fitness_center,
            isSelected: _data.workoutTimePreference == time,
            onTap: () => setState(() => _data.workoutTimePreference = time),
          ),
        )),
      ],
    );
  }
  
  Widget _buildHealthConditionsStep() {
    final conditions = ['Diabetes', 'Hypertension', 'Heart Disease', 'Arthritis', 'Asthma', 'Thyroid Issues', 'None'];
    return _buildStepContainer(
      title: AppLocalizations.of(context)!.healthConditions,
      subtitle: AppLocalizations.of(context)!.healthConditionsSubtitle,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: conditions.map((condition) {
            final isSelected = _data.healthConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (condition == 'None') {
                      // If "None" is selected, clear all others
                      _data.healthConditions.clear();
                      _data.healthConditions.add('None');
                    } else {
                      // If another condition is selected, remove "None"
                      _data.healthConditions.remove('None');
                      _data.healthConditions.add(condition);
                    }
                  } else {
                    _data.healthConditions.remove(condition);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}
