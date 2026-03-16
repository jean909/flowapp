import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchSection(),
            const SizedBox(height: 32),
            _buildCategorySection(
              l10n.gettingStarted,
              Icons.rocket_launch,
              _getGettingStartedFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.nutritionTracking,
              Icons.restaurant,
              _getNutritionTrackingFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.workoutsActivities,
              Icons.fitness_center,
              _getWorkoutFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.recipesMealPlanning,
              Icons.restaurant_menu,
              _getRecipeFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.challengesProgress,
              Icons.emoji_events,
              _getChallengeFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.vitalityBreakdown,
              Icons.insights,
              _getVitalityFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.aiFeatures,
              Icons.smart_toy,
              _getAIFAQs(),
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              l10n.accountData,
              Icons.account_circle,
              _getAccountFAQs(),
            ),
            const SizedBox(height: 32),
            _buildContactSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.searchForHelp,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, IconData icon, List<FAQItem> faqs) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        children: [
          Text(
            faq.answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.stillNeedHelp,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.supportTeamHere,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('mailto:support@flow.com?subject=Flow App Support');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.email),
              label: Text(l10n.contactSupport),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FAQItem> _getGettingStartedFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.howDoIGetStarted,
        answer: l10n.howDoIGetStartedAnswer,
      ),
      FAQItem(
        question: l10n.howDoISetTargets,
        answer: l10n.howDoISetTargetsAnswer,
      ),
      FAQItem(
        question: l10n.whatAreCoins,
        answer: l10n.whatAreCoinsAnswer,
      ),
    ];
  }

  List<FAQItem> _getNutritionTrackingFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.howDoILogMeal,
        answer: l10n.howDoILogMealAnswer,
      ),
      FAQItem(
        question: l10n.canILogMealsPhotos,
        answer: l10n.canILogMealsPhotosAnswer,
      ),
      FAQItem(
        question: l10n.howDoesVoiceInputWork,
        answer: l10n.howDoesVoiceInputWorkAnswer,
      ),
      FAQItem(
        question: l10n.whatIfFoodNotInDatabase,
        answer: l10n.whatIfFoodNotInDatabaseAnswer,
      ),
      FAQItem(
        question: l10n.howAccurateNutritionTracking,
        answer: l10n.howAccurateNutritionTrackingAnswer,
      ),
    ];
  }

  List<FAQItem> _getWorkoutFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.howDoILogWorkout,
        answer: l10n.howDoILogWorkoutAnswer,
      ),
      FAQItem(
        question: l10n.canICreateWorkoutPlans,
        answer: l10n.canICreateWorkoutPlansAnswer,
      ),
      FAQItem(
        question: l10n.howAreCaloriesBurnedCalculated,
        answer: l10n.howAreCaloriesBurnedCalculatedAnswer,
      ),
    ];
  }

  List<FAQItem> _getRecipeFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.howDoIFindRecipes,
        answer: l10n.howDoIFindRecipesAnswer,
      ),
      FAQItem(
        question: l10n.canICreateRecipes,
        answer: l10n.canICreateRecipesAnswer,
      ),
      FAQItem(
        question: l10n.howDoIAddRecipeToMealLog,
        answer: l10n.howDoIAddRecipeToMealLogAnswer,
      ),
    ];
  }

  List<FAQItem> _getChallengeFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.whatAreFlowChallenges,
        answer: l10n.whatAreFlowChallengesAnswer,
      ),
      FAQItem(
        question: l10n.howDoIJoinChallenge,
        answer: l10n.howDoIJoinChallengeAnswer,
      ),
      FAQItem(
        question: l10n.howIsChallengeProgressCalculated,
        answer: l10n.howIsChallengeProgressCalculatedAnswer,
      ),
    ];
  }

  List<FAQItem> _getVitalityFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.whatIsVitalityBreakdown,
        answer: l10n.whatIsVitalityBreakdownAnswer,
      ),
      FAQItem(
        question: l10n.whatIsVitalityShield,
        answer: l10n.whatIsVitalityShieldAnswer,
      ),
      FAQItem(
        question: l10n.howDoIViewNutrientTrends,
        answer: l10n.howDoIViewNutrientTrendsAnswer,
      ),
      FAQItem(
        question: l10n.canIViewPastDaysNutrition,
        answer: l10n.canIViewPastDaysNutritionAnswer,
      ),
    ];
  }

  List<FAQItem> _getAIFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.whatIsAICoach,
        answer: l10n.whatIsAICoachAnswer,
      ),
      FAQItem(
        question: l10n.howDoesFoodRecognitionWork,
        answer: l10n.howDoesFoodRecognitionWorkAnswer,
      ),
      FAQItem(
        question: l10n.isMyDataUsedToTrainAI,
        answer: l10n.isMyDataUsedToTrainAIAnswer,
      ),
    ];
  }

  List<FAQItem> _getAccountFAQs() {
    final l10n = AppLocalizations.of(context)!;
    return [
      FAQItem(
        question: l10n.howDoIExportData,
        answer: l10n.howDoIExportDataAnswer,
      ),
      FAQItem(
        question: l10n.canIDeleteAccount,
        answer: l10n.canIDeleteAccountAnswer,
      ),
      FAQItem(
        question: l10n.howDoIChangePassword,
        answer: l10n.howDoIChangePasswordAnswer,
      ),
      FAQItem(
        question: l10n.isMyDataSecure,
        answer: l10n.isMyDataSecureAnswer,
      ),
    ];
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

