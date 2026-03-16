import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';

class AboutFlowPage extends StatefulWidget {
  const AboutFlowPage({super.key});

  @override
  State<AboutFlowPage> createState() => _AboutFlowPageState();
}

class _AboutFlowPageState extends State<AboutFlowPage> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  String _packageName = 'com.jean909.flow.flow';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    // Use hardcoded values from pubspec.yaml
    setState(() {
      _version = '1.0.0';
      _buildNumber = '1';
      _packageName = 'com.jean909.flow.flow';
      _isLoading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.aboutFlow),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildMissionSection(),
                  const SizedBox(height: 32),
                  _buildFeaturesSection(),
                  const SizedBox(height: 32),
                  _buildTeamSection(),
                  const SizedBox(height: 32),
                  _buildLegalSection(),
                  const SizedBox(height: 32),
                  _buildVersionInfo(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInDown(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(77),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.flow,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yourCompleteHealthWellnessCompanion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: _buildSectionCard(
        icon: Icons.flag,
        title: l10n.ourMission,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ourMissionDesc1,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ourMissionDesc2,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: _buildSectionCard(
        icon: Icons.stars,
        title: l10n.keyFeatures,
        child: Column(
          children: [
            _buildFeatureItem(Icons.restaurant, l10n.comprehensiveNutritionTracking, l10n.comprehensiveNutritionTrackingDesc),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.fitness_center, l10n.workoutExerciseLogging, l10n.workoutExerciseLoggingDesc),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.restaurant_menu, l10n.aiGeneratedRecipes, l10n.aiGeneratedRecipesDesc),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.insights, l10n.vitalityBreakdown, l10n.vitalityBreakdownDesc),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.emoji_events, l10n.challengesGamification, l10n.challengesGamificationDesc),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.people, l10n.socialCommunity, l10n.socialCommunityDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: _buildSectionCard(
        icon: Icons.group,
        title: l10n.theFlowTeam,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.theFlowTeamDesc1,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.theFlowTeamDesc2,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: _buildSectionCard(
        icon: Icons.gavel,
        title: l10n.legalPrivacy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalPrivacyDesc,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            _buildLegalItem(
              l10n.privacyPolicy,
              Icons.privacy_tip,
              () => _launchURL('https://flow.com/privacy'),
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              l10n.termsOfService,
              Icons.description,
              () => _launchURL('https://flow.com/terms'),
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              l10n.contactUs,
              Icons.email,
              () => _launchURL('mailto:support@flow.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.versionInformation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVersionRow(l10n.version, _version),
            const SizedBox(height: 8),
            _buildVersionRow(l10n.buildNumber, _buildNumber),
            const SizedBox(height: 8),
            _buildVersionRow(l10n.packageName, _packageName),
            const SizedBox(height: 16),
            Text(
              l10n.copyright(DateTime.now().year),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
