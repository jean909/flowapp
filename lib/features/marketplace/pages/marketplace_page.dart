import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/features/trackers/widgets/menstruation_onboarding_dialog.dart';
import 'package:flow/core/widgets/buy_coins_sheet.dart';
import 'package:flow/l10n/app_localizations.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAddons = [];
  Set<String> _activeAddonIds = {};
  Map<String, dynamic>? _userProfile;
  int _coins = 0;
  String _planType = 'free';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final addons = await _supabaseService.getAvailableAddons();
    final userAddons = await _supabaseService.getUserAddons();
    final profile = await _supabaseService.getProfile();

    setState(() {
      _allAddons = addons;
      _activeAddonIds = userAddons
          .map((a) => a['addon_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      _userProfile = profile;
      _coins = (profile?['coins'] as num?)?.toInt() ?? 0;
      _planType = (profile?['plan_type'] as String?) ?? 'free';
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredAddons {
    if (_selectedCategory == 'all') return _allAddons;
    return _allAddons.where((a) => a['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.store,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: _showBuyCoinsDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    _coins.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryTabs(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildPlansSection(),
                      if (_planType == 'creator') ...[
                        const SizedBox(height: 32),
                        _buildCreatorHubSection(),
                      ],
                      const SizedBox(height: 32),
                      if (_activeAddonIds.isNotEmpty &&
                          _selectedCategory == 'all') ...[
                        Text(
                          AppLocalizations.of(context)!.myAddons,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAddonGrid(
                          _allAddons
                              .where((a) => _activeAddonIds.contains(a['id']))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context)!.marketplace,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAddonGrid(
                          _allAddons
                              .where((a) => !_activeAddonIds.contains(a['id']))
                              .toList(),
                        ),
                      ] else ...[
                        Text(
                          _selectedCategory == 'all'
                              ? AppLocalizations.of(context)!.allAddons
                              : '${_selectedCategory.toUpperCase()} Add-ons',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAddonGrid(_filteredAddons),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['all', 'tracker', 'analytics', 'ai'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  category == 'all'
                      ? AppLocalizations.of(context)!.categoryAll
                      : (category == 'tracker'
                            ? AppLocalizations.of(context)!.categoryTracker
                            : (category == 'analytics'
                                  ? AppLocalizations.of(
                                      context,
                                    )!.categoryAnalytics
                                  : AppLocalizations.of(context)!.categoryAI)),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddonGrid(List<Map<String, dynamic>> addons) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: addons.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: index * 100),
          child: _buildAddonCard(addons[index]),
        );
      },
    );
  }

  Widget _buildAddonCard(Map<String, dynamic> addon) {
    final addonId = addon['id']?.toString();
    if (addonId == null || addonId.isEmpty) return const SizedBox.shrink();
    final isActive = _activeAddonIds.contains(addonId);
    final isPremium = addon['is_premium'] as bool? ?? false;
    final isComingSoon = addonId == 'workout_tracker' || addonId == 'meal_planner';

    return GestureDetector(
      onTap: isComingSoon ? null : () => _showAddonDetailsDialog(addon),
      child: Opacity(
        opacity: isComingSoon ? 0.6 : 1.0,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isActive
                    ? Border.all(color: AppColors.primary, width: 2)
                    : Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    addon['icon'] ?? '📦',
                    style: const TextStyle(fontSize: 32),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.proLabel,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                addon['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  addon['description'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              if (!isActive) ...[
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${addon['coin_price'] ?? 0} ${AppLocalizations.of(context)!.coins.toLowerCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isActive) {
                      await _supabaseService.deactivateAddon(addonId);
                      _loadData();
                    } else {
                      final cost = (addon['coin_price'] as num?)?.toInt() ?? 0;
                      if (_coins < cost) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.notEnoughCoins,
                            ),
                          ),
                        );
                        return;
                      }

                      // Gender-based check
                      final preferredGender =
                          addon['preferred_gender'] as String?;
                      final userGender = _userProfile?['gender']
                          ?.toString()
                          .toLowerCase();

                      if (preferredGender != null &&
                          userGender != null &&
                          preferredGender != userGender) {
                        final proceed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '${AppLocalizations.of(context)!.genderOptimization} ⚠️',
                            ),
                            content: Text(
                              'This add-on is optimized for $preferredGender users. Your profile indicates you are $userGender. Do you still want to activate it?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppLocalizations.of(context)!.back),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.activateAnyway,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (proceed != true) return;
                      }

                      if (!mounted) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            '${AppLocalizations.of(context)!.confirmActivate} 🛍️',
                          ),
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.costConfirm.replaceAll('coins', cost.toString()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(AppLocalizations.of(context)!.back),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.buyActivate,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      // Deduct coins and activate immediately so user never loses coins without getting the addon
                      final success = await _supabaseService.purchaseWithCoins(
                        cost,
                        'Bought addon: $addonId',
                      );
                      if (!success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.notEnoughCoins)),
                          );
                        }
                        return;
                      }

                      await _supabaseService.activateAddon(addonId);

                      if (addonId == 'menstruation_tracker' && mounted) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => MenstruationOnboardingDialog(
                            onComplete: () async {
                              if (mounted) _loadData();
                            },
                          ),
                        );
                      }
                      if (mounted) _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? AppColors.background
                        : AppColors.primary,
                    foregroundColor: isActive ? Colors.black : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isComingSoon
                        ? 'Coming Soon'
                        : (isActive
                            ? '${AppLocalizations.of(context)!.active} ✓'
                            : AppLocalizations.of(context)!.details),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
                  ],
                ),
              ),
            ),
            if (isComingSoon)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorHubSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purpleAccent, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CREATOR HUB 🎨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Image.asset(
                'assets/images/panda_fitness.png',
                height: 40,
                errorBuilder: (_, __, ___) => const SizedBox(height: 40, width: 40),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create, manage, and sell your own nutrition or fitness plans to the community.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.creatorStudioSoon,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Manage Designs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.publishToolSoon,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'New Plan +',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.subscriptionPlans,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabaseService.getSubscriptionPlans(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${AppLocalizations.of(context)!.error} loading plans',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Fallback if DB is empty for some reason
                return Row(
                  children: [
                    _buildPlanCard(
                      AppLocalizations.of(context)!.freePlan,
                      AppLocalizations.of(context)!.essentialFeatures,
                      '0',
                      Colors.grey,
                      'free',
                    ),
                  ],
                );
              }

              final plans = snapshot.data!;
              return Row(
                children: plans.map((plan) {
                  final id = plan['id'] as String? ?? 'free';
                  final colorHex = plan['color_hex'] as String? ?? '#808080';
                  Color color = Colors.grey;
                  try {
                    final hex = colorHex.replaceAll('#', '');
                    if (hex.length >= 6) {
                      color = Color(int.parse('FF$hex', radix: 16));
                    }
                  } catch (_) {}
                  if (id == 'premium') color = Colors.amber;
                  if (id == 'creator') color = Colors.purpleAccent;

                  final cost = (plan['monthly_coin_cost'] as num?)?.toInt() ?? 0;
                  final title = id == 'free'
                      ? AppLocalizations.of(context)!.freePlan
                      : (id == 'premium'
                            ? AppLocalizations.of(context)!.premiumPlan
                            : AppLocalizations.of(context)!.creatorPlan);
                  final desc = plan['description'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: _buildPlanCard(
                      title,
                      desc,
                      cost.toString(),
                      color,
                      id,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    String title,
    String desc,
    String coins,
    Color color,
    String type,
  ) {
    final isCurrent = _planType == type;

    return Container(
      width: 200,
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        border: isCurrent ? Border.all(color: color, width: 2) : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              if (isCurrent)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                coins,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                '/mo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () => _confirmPlanChange(type, int.tryParse(coins) ?? 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey[200] : color,
                foregroundColor: isCurrent ? Colors.grey : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                elevation: 0,
              ),
              child: Text(
                isCurrent
                    ? AppLocalizations.of(context)!.current
                    : AppLocalizations.of(context)!.upgrade,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPlanChange(String type, int cost) async {
    if (_coins < cost && type != 'free') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notEnoughCoins)),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = type == 'free'
        ? l10n.switchToFreePlan
        : l10n.switchToPlanForCoins(type.toUpperCase(), cost);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.changePlan} 🚀'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l10n.finish),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (type != 'free') {
        final success = await _supabaseService.purchaseWithCoins(
          cost,
          'Upgraded to ${type.toUpperCase()} plan',
        );
        if (!success || !mounted) return;
      }
      await _supabaseService.updateSubscriptionPlan(type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'free' ? l10n.planSetToFree : l10n.planUpgradedTo(type.toUpperCase())),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    }
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
            description: 'Top-up: $amount coins',
          );
          await _supabaseService.updateProfile({'coins': _coins + amount});
          if (mounted) {
            _loadData();
            if (context.mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showAddonDetailsDialog(Map<String, dynamic> addon) {
    final addonId = addon['id']?.toString();
    if (addonId == null || addonId.isEmpty) return;
    final isActive = _activeAddonIds.contains(addonId);
    final cost = (addon['coin_price'] as num?)?.toInt() ?? 0;
    final preferredGender = addon['preferred_gender'] as String?;
    final userGender = _userProfile?['gender']?.toString().toLowerCase();
    final bool genderMismatch =
        preferredGender != null &&
        userGender != null &&
        preferredGender != userGender;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  addon['icon'] ?? '📦',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addon['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (addon['is_premium'] == true)
                        Text(
                          'PREMIUM ADD-ON',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'ABOUT THIS ADD-ON',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              addon['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (genderMismatch) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This addon is optimized for $preferredGender users. Your profile is $userGender.',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (!isActive) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRICE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            '$cost',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            ' coins',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 54,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_coins < cost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.notEnoughCoins),
                            ),
                          );
                          return;
                        }

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '${AppLocalizations.of(context)!.confirmPurchase} 🛍️',
                            ),
                            content: Text(
                              'Do you want to buy ${addon['name']} for $cost ${AppLocalizations.of(context)!.coins.toLowerCase()}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppLocalizations.of(context)!.back),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.buyActivate,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final success = await _supabaseService
                              .purchaseWithCoins(
                                cost,
                                'Bought addon: $addonId',
                              );
                          if (success) {
                            await _supabaseService.activateAddon(addonId);
                            if (mounted) {
                              _loadData();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${addon['name']} activated! ✨',
                                    ),
                                  ),
                                );
                              }
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.notEnoughCoins)),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'BUY NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await _supabaseService.deactivateAddon(addonId);
                    if (mounted) {
                      _loadData();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'DEACTIVATE ADDON',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
