import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/features/workout/pages/workout_input_page.dart';
import 'package:flow/features/workout/pages/edit_custom_exercise_page.dart';

class ExerciseSearchPage extends StatefulWidget {
  const ExerciseSearchPage({super.key});

  @override
  State<ExerciseSearchPage> createState() => _ExerciseSearchPageState();
}

class _ExerciseSearchPageState extends State<ExerciseSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allExercises = [];
  bool _isLoading = false;
  String _searchFilter = 'all'; // 'all', 'general', 'custom'

  @override
  void initState() {
    super.initState();
    _loadAllExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllExercises() async {
    setState(() => _isLoading = true);
    try {
      final results = await _supabaseService.searchExercises(''); // Empty query returns all
      if (mounted) {
        setState(() {
          _allExercises = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingExercises(e.toString()))),
        );
      }
    }
  }

  void _onSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        if (query.isEmpty) {
          _searchResults = _allExercises;
        }
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final results = await _supabaseService.searchExercises(query);
      
      // Filter based on _searchFilter
      List<Map<String, dynamic>> filteredResults = results;
      if (_searchFilter == 'general') {
        filteredResults = results.where((ex) => ex['is_custom'] != true).toList();
      } else if (_searchFilter == 'custom') {
        filteredResults = results.where((ex) => ex['is_custom'] == true).toList();
      }
      
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSearchingExercises(e.toString()))),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('general', 'Flow'),
          const SizedBox(width: 8),
          _buildFilterChip('custom', 'Custom'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _searchFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _searchFilter = value);
        _onSearch(_searchController.text);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _onExerciseTap(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutInputPage(
          exercise: exercise,
        ),
      ),
    );
  }

  void _onCustomExerciseLongPress(Map<String, dynamic> exercise) {
    if (exercise['is_custom'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditCustomExercisePage(
            exercise: exercise,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayList = _searchController.text.isEmpty ? _allExercises : _searchResults;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.log),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: l10n.searchExerciseHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter chips
          _buildFilterChips(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty 
                              ? 'No exercises found' 
                              : 'No exercises match "${_searchController.text}"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final exercise = displayList[index];
                          final isCustom = exercise['is_custom'] == true;
                          final imageUrl = exercise['image_url'] as String? ?? exercise['video_url'] as String?;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => _onExerciseTap(exercise),
                              onLongPress: isCustom ? () => _onCustomExerciseLongPress(exercise) : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Exercise image/icon
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: (imageUrl != null && imageUrl.isNotEmpty && !isCustom)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  child: const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  child: const Center(
                                                    child: Icon(Icons.fitness_center, color: AppColors.primary, size: 28),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.fitness_center, color: AppColors.primary, size: 28),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Exercise info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exercise['name_en'] ?? exercise['name_de'] ?? 'Exercise',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (isCustom)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Custom',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${exercise['muscle_group'] ?? 'Full Body'} • ${exercise['difficulty'] ?? 'Beginner'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (isCustom)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Long press to edit',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

