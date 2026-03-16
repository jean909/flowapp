import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flow/features/recipes/widgets/recipe_details_sheet.dart';
import 'package:flow/features/recipes/pages/create_recipe_page.dart';
import 'dart:ui';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  int _selectedTab = 0;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _myRecipes = [];
  List<Map<String, dynamic>> _favoriteRecipes = [];
  List<Map<String, dynamic>> _viralRecipes = [];
  bool _isLoading = true;
  String? _selectedCuisine;
  String? _selectedMealType;
  String? _selectedTag;
  String _searchQuery = '';
  Set<String> _favoritedIds = {};
  Map<String, bool> _likedRecipes = {}; // Track liked recipes
  List<String> _availableTags = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Cache for recipes
  static List<Map<String, dynamic>>? _cachedRecipes;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  final List<String> _cuisines = [
    'Italian',
    'French',
    'Spanish',
    'Greek',
    'German',
    'British',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tags = await _supabaseService.getRecipeTags();
      setState(() {
        _availableTags = tags;
      });
    } catch (e) {
      print('[ERROR] Error loading tags: $e');
    }
  }

  Future<void> _loadRecipes({bool forceRefresh = false}) async {
    // Check cache first (unless force refresh or filters applied)
    if (!forceRefresh && 
        _cachedRecipes != null && 
        _cacheTimestamp != null &&
        _selectedCuisine == null &&
        _selectedMealType == null &&
        _selectedTag == null &&
        _searchQuery.isEmpty &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      setState(() {
        _recipes = List.from(_cachedRecipes!);
        _isLoading = false;
      });
      // Still load favorites and likes in background
      _loadFavoritesAndLikes();
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Load all public recipes for Browse tab (not just featured)
      final recipes = await _supabaseService.getRecipes(
        cuisineType: _selectedCuisine,
        mealType: _selectedMealType,
        tag: _selectedTag,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        featured: false, // Show all public recipes, not just featured
      );
      
      // Update cache if no filters applied
      if (_selectedCuisine == null && _selectedMealType == null && 
          _selectedTag == null && _searchQuery.isEmpty) {
        _cachedRecipes = List.from(recipes);
        _cacheTimestamp = DateTime.now();
      }
      
      print('[DEBUG] Loaded ${recipes.length} recipes from Supabase');
      if (recipes.isNotEmpty) {
        print('[DEBUG] First recipe: ${recipes[0]['title_en']}');
      }
      
      final myRecipes = await _supabaseService.getMyRecipes();
      final favorites = await _supabaseService.getFavoriteRecipes();
      
      setState(() {
        _recipes = recipes;
        _myRecipes = myRecipes;
        _favoriteRecipes = favorites;
        _isLoading = false;
      });
      
      // Load favorites and likes in background
      _loadFavoritesAndLikes();
    } catch (e) {
      print('[ERROR] Error loading recipes: $e');
      print('[ERROR] Stack trace: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoritesAndLikes() async {
    try {
      // Load favorite status
      final favoritedSet = <String>{};
      for (var recipe in _recipes) {
        final isFav = await _supabaseService.isRecipeFavorited(recipe['id'] as String);
        if (isFav) favoritedSet.add(recipe['id'] as String);
      }
      
      // Get viral recipes (most liked)
      final viral = List<Map<String, dynamic>>.from(_recipes)
        ..sort((a, b) {
          final likesA = (a['likes_count'] as num?)?.toInt() ?? 0;
          final likesB = (b['likes_count'] as num?)?.toInt() ?? 0;
          return likesB.compareTo(likesA);
        });
      
      // Load liked status
      final likedSet = <String>{};
      for (var recipe in _recipes) {
        final isLiked = await _supabaseService.isRecipeLiked(recipe['id'] as String);
        if (isLiked) likedSet.add(recipe['id'] as String);
      }
      
      if (mounted) {
        setState(() {
          _favoritedIds = favoritedSet;
          _viralRecipes = viral.take(10).toList();
          _likedRecipes = {for (var id in likedSet) id: true};
        });
      }
    } catch (e) {
      print('[ERROR] Error loading favorites/likes: $e');
    }
  }

  Future<void> _toggleFavorite(String recipeId) async {
    final isFavorited = _favoritedIds.contains(recipeId);
    
    setState(() {
      if (isFavorited) {
        _favoritedIds.remove(recipeId);
      } else {
        _favoritedIds.add(recipeId);
      }
    });

    try {
      if (isFavorited) {
        await _supabaseService.unfavoriteRecipe(recipeId);
      } else {
        await _supabaseService.favoriteRecipe(recipeId);
      }
      await _loadRecipes(); // Refresh to update counts
    } catch (e) {
      // Revert on error
      setState(() {
        if (isFavorited) {
          _favoritedIds.add(recipeId);
        } else {
          _favoritedIds.remove(recipeId);
        }
      });
    }
  }

  Future<void> _toggleLike(String recipeId) async {
    final isLiked = _likedRecipes[recipeId] ?? false;
    
    setState(() {
      _likedRecipes[recipeId] = !isLiked;
    });

    try {
      if (isLiked) {
        await _supabaseService.unlikeRecipe(recipeId);
      } else {
        await _supabaseService.likeRecipe(recipeId);
      }
      await _loadRecipes(); // Refresh to update counts
    } catch (e) {
      // Revert on error
      setState(() {
        _likedRecipes[recipeId] = isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: innerBoxIsScrolled ? 120 : 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final isCollapsed = constraints.biggest.height <= 100;
                  return FlexibleSpaceBar(
                    title: AnimatedOpacity(
                      opacity: isCollapsed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: FadeInDown(
                        child: Text(
                          l10n.recipes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                            Colors.orange.shade400,
                            Colors.deepOrange.shade300,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/food_pattern.png',
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.15),
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.2),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            Positioned(
                              left: 16,
                              bottom: 80,
                              child: FadeInLeft(
                                duration: const Duration(milliseconds: 500),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.recipes,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Discover amazing recipes',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_selectedTab == 0 ? (_selectedTag != null || _searchQuery.isNotEmpty ? 140 : 100) : 48),
                child: Container(
                  color: AppColors.primary,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: l10n.browseRecipes),
                          Tab(text: l10n.myRecipes),
                          Tab(text: 'Favorites'),
                        ],
                      ),
                      if (_selectedTab == 0) _buildFilters(),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBrowseRecipes(),
            _buildMyRecipes(),
            _buildFavorites(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: _selectedCuisine ?? AppLocalizations.of(context)!.allCuisines,
                  icon: Icons.restaurant,
                  onTap: () => _showCuisineFilter(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: _selectedMealType ?? AppLocalizations.of(context)!.allMeals,
                  icon: Icons.access_time,
                  onTap: () => _showMealTypeFilter(),
                ),
              ),
            ],
          ),
          if (_selectedTag != null || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_searchQuery.isNotEmpty)
                  Expanded(
                    child: _buildFilterChip(
                      label: AppLocalizations.of(context)!.searchFilterLabel(_searchQuery),
                      icon: Icons.search,
                      onTap: () => _showSearchDialog(),
                      showClose: true,
                      onClose: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _loadRecipes();
                      },
                    ),
                  ),
                if (_selectedTag != null) ...[
                  if (_searchQuery.isNotEmpty) const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      label: AppLocalizations.of(context)!.tagFilterLabel(_selectedTag ?? ''),
                      icon: Icons.label,
                      onTap: () => _showTagFilter(),
                      showClose: true,
                      onClose: () {
                        setState(() => _selectedTag = null);
                        _loadRecipes();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool showClose = false,
    VoidCallback? onClose,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: showClose ? 4 : 12,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showClose && onClose != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  onClose();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCuisineFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.allCuisines, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() => _selectedCuisine = null);
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
            ..._cuisines.map((cuisine) => ListTile(
              title: Text(cuisine),
              onTap: () {
                setState(() => _selectedCuisine = cuisine);
                Navigator.pop(context);
                _loadRecipes();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showMealTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.allMeals, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() => _selectedMealType = null);
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.breakfast),
              onTap: () {
                setState(() => _selectedMealType = 'BREAKFAST');
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.lunch),
              onTap: () {
                setState(() => _selectedMealType = 'LUNCH');
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.dinner),
              onTap: () {
                setState(() => _selectedMealType = 'DINNER');
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.snack),
              onTap: () {
                setState(() => _selectedMealType = 'SNACK');
                Navigator.pop(context);
                _loadRecipes();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    _searchController.text = _searchQuery;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.searchRecipes),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchByName,
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
            _loadRecipes();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
              _loadRecipes();
            },
            child: Text(AppLocalizations.of(context)!.clear),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
              _loadRecipes();
            },
            child: Text(AppLocalizations.of(context)!.search),
          ),
        ],
      ),
    );
  }

  void _showTagFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by Tag',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_availableTags.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(AppLocalizations.of(context)!.noTagsAvailable),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableTags.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: Text(AppLocalizations.of(context)!.allTags, style: const TextStyle(fontWeight: FontWeight.bold)),
                        leading: const Icon(Icons.clear_all),
                        onTap: () {
                          setState(() => _selectedTag = null);
                          Navigator.pop(context);
                          _loadRecipes();
                        },
                      );
                    }
                    final tag = _availableTags[index - 1];
                    return ListTile(
                      title: Text(tag),
                      leading: const Icon(Icons.label),
                      onTap: () {
                        setState(() => _selectedTag = tag);
                        Navigator.pop(context);
                        _loadRecipes();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseRecipes() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_recipes.isEmpty) {
      return FadeIn(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No recipes found',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Viral Recipes Section
          if (_viralRecipes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.viralRecipes,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _viralRecipes.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 240,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildRecipeCard(_viralRecipes[index], index, isViral: true),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          // All Recipes List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return FadeInUp(
                    duration: Duration(milliseconds: 400 + (index * 80)),
                    delay: Duration(milliseconds: index * 50),
                    child: _buildRecipeCard(_recipes[index], index),
                  );
                },
                childCount: _recipes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecipes() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_myRecipes.isEmpty) {
      return FadeIn(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.noRecipesYet,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.createYourFirstRecipe,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _myRecipes.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            duration: Duration(milliseconds: 400 + (index * 80)),
            delay: Duration(milliseconds: index * 50),
            child: _buildRecipeCard(_myRecipes[index], index),
          );
        },
      ),
    );
  }

  Widget _buildFavorites() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_favoriteRecipes.isEmpty) {
      return FadeIn(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No favorite recipes yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon to save recipes',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _favoriteRecipes.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            duration: Duration(milliseconds: 400 + (index * 80)),
            delay: Duration(milliseconds: index * 50),
            child: _buildRecipeCard(_favoriteRecipes[index], index),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, int index, {bool isViral = false}) {
    final recipeId = recipe['id'] as String;
    final l10n = AppLocalizations.of(context)!;
    final title = recipe['title_en'] as String? ?? l10n.untitledRecipe;
    final description = recipe['description_en'] as String? ?? '';
    final imageUrl = recipe['image_url'] as String?;
    final calories = (recipe['calories'] as num?)?.toDouble() ?? 0.0;
    final prepTime = recipe['prep_time_minutes'] as int? ?? 0;
    final cuisine = recipe['cuisine_type'] as String?;
    final avgRating = (recipe['average_rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = (recipe['rating_count'] as int?) ?? 0;
    final likesCount = (recipe['likes_count'] as num?)?.toInt() ?? 0;
    final isFavorited = _favoritedIds.contains(recipeId);
    final isLiked = _likedRecipes[recipeId] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showRecipeDetails(recipe),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Image with gradient overlay
                  Hero(
                    tag: 'recipe_$recipeId',
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: const Duration(milliseconds: 300),
                                  fadeInCurve: Curves.easeIn,
                                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                                ),
                                // Multi-layer gradient overlay for better text readability
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.5, 1.0],
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.85),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  // Like and Favorite buttons in top right corner
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Like button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleLike(recipeId),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isLiked
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLiked
                                      ? Colors.blue.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.thumb_up,
                                    color: isLiked ? Colors.blue : Colors.white,
                                    size: 16,
                                  ),
                                  if (likesCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '$likesCount',
                                      style: TextStyle(
                                        color: isLiked ? Colors.blue : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Favorite button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleFavorite(recipeId),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isFavorited
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isFavorited
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isFavorited ? Icons.favorite : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content overlay with glassmorphism
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.85),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title (now without buttons on same line)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cuisine != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _getCountryFlag(cuisine),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cuisine,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.85),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Stats row with improved design
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildStatChip(
                                    Icons.local_fire_department,
                                    '${calories.toInt()} cal',
                                    Colors.orange,
                                  ),
                                  _buildStatChip(
                                    Icons.access_time,
                                    '$prepTime min',
                                    Colors.blue,
                                  ),
                                  if (avgRating > 0)
                                    _buildStatChip(
                                      Icons.star,
                                      '${avgRating.toStringAsFixed(1)}',
                                      Colors.amber,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // End of Positioned
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading recipes...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.card.withOpacity(0.3),
                highlightColor: AppColors.card.withOpacity(0.1),
                period: const Duration(milliseconds: 1500),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  height: 320,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeDetailsSheet(
        recipe: recipe,
        supabaseService: _supabaseService,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.restaurant_menu, size: 64, color: AppColors.primary.withOpacity(0.5)),
      ),
    );
  }

  void _showCreateRecipeDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRecipePage(),
      ),
    );
    
    // Refresh recipes if a new one was created
    if (result == true) {
      _loadRecipes(forceRefresh: true);
    }
  }

  String _getCountryFlag(String cuisine) {
    final flagMap = {
      'Italian': '🇮🇹',
      'French': '🇫🇷',
      'Spanish': '🇪🇸',
      'Greek': '🇬🇷',
      'German': '🇩🇪',
      'British': '🇬🇧',
      'Mediterranean': '🌊',
      'European': '🇪🇺',
    };
    return flagMap[cuisine] ?? '🌍';
  }
}
