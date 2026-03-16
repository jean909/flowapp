import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';

class SportsProgramsPage extends StatefulWidget {
  const SportsProgramsPage({super.key});

  @override
  State<SportsProgramsPage> createState() => _SportsProgramsPageState();
}

class _SportsProgramsPageState extends State<SportsProgramsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _carouselController = PageController(
    viewportFraction: 0.85,
  );

  bool _isLoading = true;
  List<Map<String, dynamic>> _allChallenges = [];
  List<Map<String, dynamic>> _filteredChallenges = [];
  List<Map<String, dynamic>> _popularChallenges = [];
  Map<String, dynamic> _userChallengesMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      _filterChallenges();
      setState(() {}); // Update UI when search text changes
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final challenges = await _supabaseService.getChallenges();
      final userChallenges = await _supabaseService.getUserChallenges();

      final enrolledMap = {
        for (var uc in userChallenges) uc['challenge_id'].toString(): uc,
      };

      // Sort for popular (first 5 for now as we don't have enrolled_count column yet, could add it later)
      final popular = List<Map<String, dynamic>>.from(challenges);

      setState(() {
        _allChallenges = challenges;
        _filteredChallenges = challenges;
        _popularChallenges = popular.take(5).toList();
        _userChallengesMap = enrolledMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterChallenges() {
    final query = _searchController.text.toLowerCase();
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    setState(() {
      _filteredChallenges = _allChallenges.where((c) {
        final name = (isDe ? c['title_de'] : c['title_en']).toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _joinChallenge(Map<String, dynamic> challenge) async {
    try {
      await _supabaseService.joinChallenge(challenge['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.joinedSuccessfully),
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchController.text.isEmpty &&
                          _popularChallenges.isNotEmpty) ...[
                        FadeInDown(
                          delay: const Duration(milliseconds: 100),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.popularNow,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildPopularCarousel(),
                        ),
                      ],
                      FadeInUp(
                        delay: Duration(
                          milliseconds: _searchController.text.isEmpty ? 300 : 100,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            _searchController.text.isEmpty ? 32 : 24,
                            24,
                            16,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.allChallenges,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_filteredChallenges.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final challenge = _filteredChallenges[index];
                      final userChallenge =
                          _userChallengesMap[challenge['id'].toString()];
                      return FadeInUp(
                        delay: Duration(milliseconds: 100 + (index * 50)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildChallengeListItem(
                            challenge,
                            userChallenge,
                          ),
                        ),
                      );
                    }, childCount: _filteredChallenges.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxHeight > 120;
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: isExpanded ? 20 : 60, // More padding when collapsed to avoid back button
              bottom: isExpanded ? 70 : 16, // More bottom padding when expanded to avoid search bar
            ),
            title: Text(
              AppLocalizations.of(context)!.flowChallenges,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isExpanded ? 28 : 20,
              ),
            ),
            centerTitle: false,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildSearchBar(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchChallenges,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildPopularCarousel() {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: _popularChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _popularChallenges[index];
          final userChallenge = _userChallengesMap[challenge['id'].toString()];

          return AnimatedBuilder(
            animation: _carouselController,
            builder: (context, child) {
              double value = 1.0;
              if (_carouselController.position.haveDimensions) {
                value = (_carouselController.page! - index);
                value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeOut.transform(value) * 260,
                  width: Curves.easeOut.transform(value) * 350,
                  child: child,
                ),
              );
            },
            child: _buildPopularCard(challenge, userChallenge),
          );
        },
      ),
    );
  }

  Widget _buildPopularCard(
    Map<String, dynamic> challenge,
    Map<String, dynamic>? userChallenge,
  ) {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final title = isDe ? challenge['title_de'] : challenge['title_en'];
    final icon = challenge['icon'] ?? '🏆';

    return GestureDetector(
      onTap: () => _showChallengeDetails(challenge, userChallenge),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'WOW CHALLENGE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              if (userChallenge != null)
                Text(
                  '${((userChallenge['current_progress'] as num?)?.toDouble() ?? 0 / (challenge['goal_value'] as num).toDouble() * 100).toInt()}% Completed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeListItem(
    Map<String, dynamic> challenge,
    Map<String, dynamic>? userChallenge,
  ) {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final title = isDe ? challenge['title_de'] : challenge['title_en'];
    final difficulty = challenge['difficulty'] ?? 'MEDIUM';
    final reward = '${challenge['reward_coins'] ?? 50} 🪙';
    final icon = challenge['icon'] ?? '🏆';
    final isCompleted =
        userChallenge != null && userChallenge['status'] == 'completed';

    String diffLabel = AppLocalizations.of(context)!.beginner;
    Color diffColor = AppColors.primary;
    if (difficulty == 'HARD') {
      diffLabel = AppLocalizations.of(context)!.advanced;
      diffColor = AppColors.accent;
    } else if (difficulty == 'MEDIUM') {
      diffLabel = AppLocalizations.of(context)!.intermediate;
      diffColor = AppColors.secondary;
    }

    return GestureDetector(
      onTap: () => _showChallengeDetails(challenge, userChallenge),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withAlpha(51)
                : (userChallenge != null
                    ? diffColor.withAlpha(51)
                    : Colors.grey.withAlpha(26)),
            width: isCompleted || userChallenge != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.green.withAlpha(26)
                  : Colors.black.withAlpha(13),
              blurRadius: isCompleted ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: diffColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diffLabel.toUpperCase(),
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reward,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.bolt,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            challenge['goal_type'],
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                if (!isCompleted && userChallenge != null)
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
            if (userChallenge != null && !isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ((userChallenge['current_progress'] as num?)?.toDouble() ?? 0) /
                            (challenge['goal_value'] as num).toDouble(),
                        backgroundColor: Colors.grey[100],
                        color: diffColor,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${((userChallenge['current_progress'] as num?)?.toDouble() ?? 0 / (challenge['goal_value'] as num).toDouble() * 100).toInt()}%',
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChallengeDetails(
    Map<String, dynamic> challenge,
    Map<String, dynamic>? userChallenge,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChallengeDetailSheet(
        challenge: challenge,
        userChallenge: userChallenge,
        onJoin: () => _joinChallenge(challenge),
      ),
    );
  }
}

class _ChallengeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final Map<String, dynamic>? userChallenge;
  final VoidCallback onJoin;

  const _ChallengeDetailSheet({
    required this.challenge,
    required this.userChallenge,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isDe = Localizations.localeOf(context).languageCode == 'de';
    final title = isDe ? challenge['title_de'] : challenge['title_en'];
    final description = isDe
        ? challenge['description_de']
        : challenge['description_en'];
    final rewardCoins = (challenge['reward_coins'] as num?)?.toInt() ?? 50;
    final isEnrolled = userChallenge != null;
    final isCompleted =
        userChallenge != null && userChallenge!['status'] == 'completed';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTags(context, challenge['goal_type'], rewardCoins),
                  const SizedBox(height: 32),
                  if (userChallenge != null) ...[
                    Text(
                      'Your Progress',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${userChallenge!['current_progress']} / ${challenge['goal_value']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${(((userChallenge!['current_progress'] as num?)?.toDouble() ?? 0) / (challenge['goal_value'] as num).toDouble() * 100).toInt()}%',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            ((userChallenge!['current_progress'] as num?)?.toDouble() ?? 0) /
                            (challenge['goal_value'] as num).toDouble(),
                        backgroundColor: Colors.grey[100],
                        color: AppColors.primary,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    AppLocalizations.of(context)!.challengeBenefits,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    Icons.auto_awesome,
                    isDe ? 'Data-Driven' : 'Data-Driven',
                    isDe
                        ? 'Dieser Challenge wird automatisch durch dein Tracking aktualisiert.'
                        : 'This challenge updates automatically based on your real activity logs.',
                  ),
                  _buildBenefitItem(
                    Icons.emoji_events,
                    isDe ? 'Coins Belohnung' : 'Coin Rewards',
                    isDe
                        ? 'Verdiene Flow Coins und schalte neue Funktionen frei.'
                        : 'Earn Flow Coins and unlock new features in the marketplace.',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.description,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: isEnrolled
                          ? null
                          : () {
                              Navigator.pop(context);
                              onJoin();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed'
                            : (isEnrolled
                                  ? AppLocalizations.of(context)!.active
                                  : AppLocalizations.of(context)!.joinNow),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDetailHeader(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              challenge['icon'] ?? '🏆',
              style: const TextStyle(fontSize: 100),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context, String hashtag, int coins) {
    return Wrap(
      spacing: 8,
      children: [
        Chip(
          label: Text(hashtag),
          backgroundColor: const Color(0xFFF1F5F9),
          labelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Chip(
          label: Text(AppLocalizations.of(context)!.coinsCount(coins)),
          backgroundColor: Colors.amber.withAlpha(51),
          labelStyle: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
