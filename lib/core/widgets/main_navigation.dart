import 'package:flutter/material.dart';
import 'package:flow/features/dashboard/pages/dashboard_page.dart';
import 'package:flow/features/programs/pages/programs_page.dart';
import 'package:flow/features/social/pages/feed_page.dart';
import 'package:flow/features/dashboard/pages/add_options_modal.dart';
import 'package:flow/features/analytics/pages/progress_page.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/main.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/profile/pages/profile_page.dart';
import 'package:flow/features/profile/pages/about_flow_page.dart';
import 'package:flow/features/profile/pages/export_data_page.dart';
import 'package:flow/features/profile/pages/help_support_page.dart';
import 'package:flow/features/workout/pages/planned_workouts_page.dart';
import 'package:flow/features/recipes/pages/recipes_page.dart';
import 'package:flow/features/journal/pages/journal_history_page.dart';
import 'package:share_plus/share_plus.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _selectedIndex = 0;
  int _streakCount = 0;
  int _coins = 100;
  String _planType = 'free';
  Map<String, dynamic>? _profile;
  final SupabaseService _supabaseService = SupabaseService();

  void _loadUserData() async {
    final streak = await _supabaseService.getStreakCount();
    final profile = await _supabaseService.getProfile();
    if (mounted) {
      setState(() {
        _streakCount = streak;
        _coins = (profile?['coins'] as num?)?.toInt() ?? 100;
        _planType = (profile?['plan_type'] as String?) ?? 'free';
        _profile = profile;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  List<Widget> get _pages => [
    const DashboardPage(),
    const ProgressPage(),
    SocialFeedPage(onSwitchToDashboard: () => setState(() => _selectedIndex = 0)),
    const RecipesPage(),
  ];

  void _handleLogout() async {
    await _supabaseService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SplashPage()),
        (route) => false,
      );
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.md),
      minVerticalPadding: AppSpacing.md,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.exitApp),
        content: Text(AppLocalizations.of(context)!.exitAppConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && mounted) {
          // Exit app
          // On Android, this will minimize the app
          // On iOS, this will close the app
        }
      },
      child: Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  // Overlay for opacity
                  Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.fireplace, '${AppLocalizations.of(context)!.dailyStreaks}: $_streakCount', () {}, color: Colors.orange),
            _buildDrawerItem(Icons.share, AppLocalizations.of(context)!.shareProgress, () {
              Navigator.pop(context);
              final l10n = AppLocalizations.of(context)!;
              final text = _streakCount > 0 ? l10n.shareProgressStreak(_streakCount) : l10n.shareProgressDefault;
              Share.share(text);
            }),
            _buildDrawerItem(Icons.person_outline, AppLocalizations.of(context)!.myProfile, () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              // Reload profile data when returning from profile page
              if (result == true) {
                // Profile was updated, reload data if needed
              }
            }),
            _buildDrawerItem(Icons.calendar_today, AppLocalizations.of(context)!.plannedWorkouts, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannedWorkoutsPage()));
            }),
            _buildDrawerItem(Icons.history, AppLocalizations.of(context)!.journalHistory, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalHistoryPage()));
            }),
            _buildDrawerItem(Icons.settings_outlined, AppLocalizations.of(context)!.settings, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceholderPage(title: AppLocalizations.of(context)!.settings)));
            }),
            _buildDrawerItem(Icons.help_outline, AppLocalizations.of(context)!.helpSupport, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage()));
            }),
            _buildDrawerItem(Icons.download, AppLocalizations.of(context)!.exportData, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportDataPage()));
            }),
            _buildDrawerItem(Icons.info_outline, AppLocalizations.of(context)!.aboutFlow, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutFlowPage()));
            }),
            const Spacer(),
            const Divider(),
            _buildDrawerItem(
              Icons.logout,
              AppLocalizations.of(context)!.logout,
              () {
                Navigator.pop(context);
                _handleLogout();
              },
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
          ],
          ),
        ),
      ),
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              BottomNavigationBar(
                currentIndex: _selectedIndex == 0 ? 0 : _selectedIndex == 1 ? 1 : _selectedIndex == 2 ? 3 : 4,
                onTap: (index) {
                  if (index == 2) {
                    // Show ADD modal
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddOptionsModal(),
                    );
                  } else {
                    // Map indices: 0->0 (Home), 1->1 (Progress), 2->ADD (skip), 3->2 (Social), 4->3 (Recipes)
                    final pageIndex = index < 2 ? index : index - 1;
                    setState(() => _selectedIndex = pageIndex);
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.card,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    activeIcon: const Icon(Icons.dashboard),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.insights_outlined),
                    activeIcon: const Icon(Icons.insights),
                    label: AppLocalizations.of(context)!.insights,
                  ),
                  // Placeholder for ADD button (will be overlaid)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.add, size: 0),
                    activeIcon: Icon(Icons.add, size: 0),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people_outline),
                    activeIcon: const Icon(Icons.people),
                    label: AppLocalizations.of(context)!.social,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.restaurant_menu_outlined),
                    activeIcon: const Icon(Icons.restaurant_menu),
                    label: AppLocalizations.of(context)!.recipes,
                  ),
                ],
              ),
              // Large ADD button in the center
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 32,
                top: -20,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddOptionsModal(),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.primary.withAlpha(128)),
            const SizedBox(height: 24),
            Text(
              '$title coming soon',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}