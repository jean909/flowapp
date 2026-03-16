import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';

class DietsAndProgramsPage extends StatefulWidget {
  const DietsAndProgramsPage({super.key});

  @override
  State<DietsAndProgramsPage> createState() => _DietsAndProgramsPageState();
}

class _DietsAndProgramsPageState extends State<DietsAndProgramsPage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _loadError = false;
  List<Map<String, dynamic>> _diets = [];
  List<Map<String, dynamic>> _programs = [];
  Map<String, dynamic>? _activeDiet;
  Map<String, dynamic>? _activeProgram;

  String _localeName(Map<String, dynamic> item) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'de' && item['name_de'] != null) return item['name_de'] as String;
    if (locale == 'ro' && item['name_ro'] != null) return item['name_ro'] as String;
    return (item['name_en'] ?? item['name_de'] ?? item['name_ro'] ?? '') as String;
  }

  String _localeDescription(Map<String, dynamic> item) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'de' && item['description_de'] != null) return item['description_de'] as String;
    if (locale == 'ro' && item['description_ro'] != null) return item['description_ro'] as String;
    return (item['description_en'] ?? item['description_de'] ?? item['description_ro'] ?? '') as String;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabaseService.getAvailableDiets(),
        _supabaseService.getAvailablePrograms(),
        _supabaseService.getActiveDiet(),
        _supabaseService.getActiveProgram(),
      ]);

      setState(() {
        _diets = List<Map<String, dynamic>>.from(results[0] as List);
        _programs = List<Map<String, dynamic>>.from(results[1] as List);
        _activeDiet = results[2] as Map<String, dynamic>?;
        _activeProgram = results[3] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading diets and programs: $e');
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _activateDiet(String dietId) async {
    try {
      await _supabaseService.activateDiet(dietId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dietActivated),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateProgram(String programId) async {
    try {
      await _supabaseService.activateProgram(programId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.programActivated),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateDiet() async {
    try {
      await _supabaseService.deactivateDiet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dietDeactivated),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateProgram() async {
    try {
      await _supabaseService.deactivateProgram();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.programDeactivated),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dietsAndPrograms),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.diets),
            Tab(text: AppLocalizations.of(context)!.programs),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDietsTab(),
                    _buildProgramsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingPage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppLocalizations.of(context)!.error,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Could not load diets and programs. Tap Retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _loadError = false);
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietsTab() {
    return CustomScrollView(
      slivers: [
        if (_activeDiet != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: _buildActiveCard(
                _activeDiet!,
                isDiet: true,
                onDeactivate: _deactivateDiet,
              ),
            ),
          ),
        if (_diets.isEmpty && _activeDiet == null)
          SliverFillRemaining(
            child: _buildEmptyState(isDiet: true),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final diet = _diets[index];
                  final isActive = _activeDiet != null &&
                      _activeDiet!['diet_id'] == diet['id'];
                  return FadeInUp(
                    delay: Duration(milliseconds: 50 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _buildDietCard(diet, isActive),
                    ),
                  );
                },
                childCount: _diets.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgramsTab() {
    return CustomScrollView(
      slivers: [
        if (_activeProgram != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: _buildActiveCard(
                _activeProgram!,
                isDiet: false,
                onDeactivate: _deactivateProgram,
              ),
            ),
          ),
        if (_programs.isEmpty && _activeProgram == null)
          SliverFillRemaining(
            child: _buildEmptyState(isDiet: false),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final program = _programs[index];
                  final isActive = _activeProgram != null &&
                      _activeProgram!['program_id'] == program['id'];
                  return FadeInUp(
                    delay: Duration(milliseconds: 50 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _buildProgramCard(program, isActive),
                    ),
                  );
                },
                childCount: _programs.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isDiet}) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingPage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDiet ? Icons.restaurant_menu : Icons.fitness_center,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              isDiet
                  ? 'No diets available yet'
                  : 'No programs available yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isDiet
                  ? 'Check back later for nutrition plans.'
                  : 'Check back later for fitness programs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCard(
    Map<String, dynamic> active, {
    required bool isDiet,
    required VoidCallback onDeactivate,
  }) {
    final item = isDiet
        ? (active['diets'] as Map<String, dynamic>?)
        : (active['fitness_programs'] as Map<String, dynamic>?);
    if (item == null) return const SizedBox.shrink();

    final name = _localeName(item);
    final description = _localeDescription(item);
    final compliance = (active['compliance_score'] as num?)?.toDouble() ?? 0.0;
    final completion = (active['completion_percentage'] as num?)?.toDouble() ?? 0.0;
    final currentWeek = active['current_week'] as int? ?? 1;

    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.active.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _showDeactivateDialog(isDiet, onDeactivate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (isDiet)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.compliance}: ${compliance.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: compliance / 100,
                    backgroundColor: Colors.white.withAlpha(51),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.week} $currentWeek - ${completion.toStringAsFixed(0)}% ${AppLocalizations.of(context)!.complete}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    backgroundColor: Colors.white.withAlpha(51),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDietCard(
    Map<String, dynamic> diet,
    bool isActive,
  ) {
    final name = _localeName(diet);
    final description = _localeDescription(diet);
    final difficulty = diet['difficulty'] as String? ?? 'INTERMEDIATE';
    final duration = diet['duration_weeks'] as int? ?? 8;
    final macroRatios = diet['macro_ratios'] as Map<String, dynamic>? ?? {};
    final category = diet['category'] as String? ?? 'GENERAL';
    final micronutrientTargets = diet['micronutrient_targets'] as Map<String, dynamic>? ?? {};
    final vitaminTargets = diet['vitamin_targets'] as Map<String, dynamic>? ?? {};
    final specialConsiderations = diet['special_considerations'] as List<dynamic>? ?? [];
    final recommendedSupplements = diet['recommended_supplements'] as List<dynamic>? ?? [];

    String diffLabel = AppLocalizations.of(context)!.intermediate;
    Color diffColor = AppColors.secondary;
    if (difficulty == 'ADVANCED') {
      diffLabel = AppLocalizations.of(context)!.advanced;
      diffColor = AppColors.accent;
    } else if (difficulty == 'BEGINNER') {
      diffLabel = AppLocalizations.of(context)!.beginner;
      diffColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _showDietDetails(diet, isActive),
      child: Container(
        padding: AppSpacing.paddingXl,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withAlpha(102)
                : Colors.grey.withAlpha(26),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primary.withAlpha(26)
                  : Colors.black.withAlpha(13),
              blurRadius: isActive ? 15 : 10,
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: diffColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primary,
                    size: 30,
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
                        name,
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
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$duration ${AppLocalizations.of(context)!.weeks}',
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
                if (isActive)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (macroRatios.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMacroChip('P', '${(macroRatios['protein_percentage'] as num?)?.toInt() ?? 0}%'),
                  const SizedBox(width: 8),
                  _buildMacroChip('C', '${(macroRatios['carbs_percentage'] as num?)?.toInt() ?? 0}%'),
                  const SizedBox(width: 8),
                  _buildMacroChip('F', '${(macroRatios['fat_percentage'] as num?)?.toInt() ?? 0}%'),
                ],
              ),
            ],
            if (category != 'GENERAL') ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  _getCategoryLabel(category),
                  style: TextStyle(
                    color: _getCategoryColor(category),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive
                    ? null
                    : () => _activateDiet(diet['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isActive
                      ? AppLocalizations.of(context)!.active
                      : AppLocalizations.of(context)!.activate,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildProgramCard(
    Map<String, dynamic> program,
    bool isActive,
  ) {
    final name = _localeName(program);
    final description = _localeDescription(program);
    final difficulty = program['difficulty'] as String? ?? 'INTERMEDIATE';
    final duration = program['duration_weeks'] as int? ?? 12;
    final daysPerWeek = program['days_per_week'] as int? ?? 3;

    String diffLabel = AppLocalizations.of(context)!.intermediate;
    Color diffColor = AppColors.secondary;
    if (difficulty == 'ADVANCED') {
      diffLabel = AppLocalizations.of(context)!.advanced;
      diffColor = AppColors.accent;
    } else if (difficulty == 'BEGINNER') {
      diffLabel = AppLocalizations.of(context)!.beginner;
      diffColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _showProgramDetails(program, isActive),
      child: Container(
        padding: AppSpacing.paddingXl,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withAlpha(102)
                : Colors.grey.withAlpha(26),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primary.withAlpha(26)
                  : Colors.black.withAlpha(13),
              blurRadius: isActive ? 15 : 10,
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: diffColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                    size: 30,
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
                        name,
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
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$duration ${AppLocalizations.of(context)!.weeks}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$daysPerWeek ${AppLocalizations.of(context)!.daysPerWeek}',
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
                if (isActive)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive
                    ? null
                    : () => _activateProgram(program['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isActive
                      ? AppLocalizations.of(context)!.active
                      : AppLocalizations.of(context)!.activate,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildMacroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'PREGNANCY':
        return Colors.pink;
      case 'FERTILITY':
        return Colors.purple;
      case 'POSTPARTUM':
        return Colors.orange;
      case 'HEART_HEALTH':
        return Colors.red;
      case 'IMMUNE_BOOST':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  String _getCategoryLabel(String category) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (category) {
      case 'PREGNANCY':
        return locale == 'de' ? 'Schwangerschaft' : locale == 'ro' ? 'Sarcină' : 'Pregnancy';
      case 'FERTILITY':
        return locale == 'de' ? 'Fruchtbarkeit' : locale == 'ro' ? 'Fertilitate' : 'Fertility';
      case 'POSTPARTUM':
        return locale == 'de' ? 'Postpartal' : locale == 'ro' ? 'Postpartum' : 'Postpartum';
      case 'HEART_HEALTH':
        return locale == 'de' ? 'Herzgesundheit' : locale == 'ro' ? 'Sănătate cardiacă' : 'Heart Health';
      case 'IMMUNE_BOOST':
        return locale == 'de' ? 'Immunsystem' : locale == 'ro' ? 'Imunitate' : 'Immune Boost';
      default:
        return '';
    }
  }

  void _showDietDetails(Map<String, dynamic> diet, bool isActive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DietDetailSheet(
        diet: diet,
        name: _localeName(diet),
        description: _localeDescription(diet),
        isActive: isActive,
        onActivate: () => _activateDiet(diet['id']),
      ),
    );
  }

  void _showProgramDetails(Map<String, dynamic> program, bool isActive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgramDetailSheet(
        program: program,
        name: _localeName(program),
        description: _localeDescription(program),
        isActive: isActive,
        onActivate: () => _activateProgram(program['id']),
      ),
    );
  }

  void _showDeactivateDialog(bool isDiet, VoidCallback onDeactivate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deactivate),
        content: Text(
          isDiet
              ? AppLocalizations.of(context)!.deactivateDietConfirm
              : AppLocalizations.of(context)!.deactivateProgramConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeactivate();
            },
            child: Text(
              AppLocalizations.of(context)!.deactivate,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietDetailSheet extends StatelessWidget {
  final Map<String, dynamic> diet;
  final String name;
  final String description;
  final bool isActive;
  final VoidCallback onActivate;

  const _DietDetailSheet({
    required this.diet,
    required this.name,
    required this.description,
    required this.isActive,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final duration = diet['duration_weeks'] as int? ?? 8;
    final macroRatios = diet['macro_ratios'] as Map<String, dynamic>? ?? {};

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (macroRatios.isNotEmpty) ...[
                    Row(
                      children: [
                        _buildMacroChip('Protein', '${(macroRatios['protein_percentage'] as num?)?.toInt() ?? 0}%'),
                        const SizedBox(width: 8),
                        _buildMacroChip('Carbs', '${(macroRatios['carbs_percentage'] as num?)?.toInt() ?? 0}%'),
                        const SizedBox(width: 8),
                        _buildMacroChip('Fat', '${(macroRatios['fat_percentage'] as num?)?.toInt() ?? 0}%'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
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
                      onPressed: isActive ? null : () {
                        Navigator.pop(context);
                        onActivate();
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
                        isActive
                            ? AppLocalizations.of(context)!.active
                            : AppLocalizations.of(context)!.activate,
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

  Widget _buildMacroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProgramDetailSheet extends StatelessWidget {
  final Map<String, dynamic> program;
  final String name;
  final String description;
  final bool isActive;
  final VoidCallback onActivate;

  const _ProgramDetailSheet({
    required this.program,
    required this.name,
    required this.description,
    required this.isActive,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final duration = program['duration_weeks'] as int? ?? 12;
    final daysPerWeek = program['days_per_week'] as int? ?? 3;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        '$duration ${AppLocalizations.of(context)!.weeks}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.schedule, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        '$daysPerWeek ${AppLocalizations.of(context)!.daysPerWeek}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                      onPressed: isActive ? null : () {
                        Navigator.pop(context);
                        onActivate();
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
                        isActive
                            ? AppLocalizations.of(context)!.active
                            : AppLocalizations.of(context)!.activate,
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
}

