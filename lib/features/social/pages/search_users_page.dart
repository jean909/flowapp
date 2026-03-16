import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/features/social/pages/social_profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('recent_social_searches');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _recentSearches = decoded.cast<Map<String, dynamic>>();
        });
      } catch (e) {
        print('Error loading search history: $e');
      }
    }
  }

  Future<void> _saveToHistory(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists to move to top
    _recentSearches.removeWhere((item) => item['id'] == user['id']);
    
    // Insert at beginning
    _recentSearches.insert(0, {
      'id': user['id'],
      'username': user['username'],
      'full_name': user['full_name'],
      'avatar_url': user['avatar_url'],
    });

    // Keep only last 5
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    await prefs.setString('recent_social_searches', jsonEncode(_recentSearches));
    setState(() {});
  }

  Future<void> _removeFromHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((item) => item['id'] == userId);
    await prefs.setString('recent_social_searches', jsonEncode(_recentSearches));
    setState(() {});
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _supabaseService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchUsers,
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Search for users'
                            : 'No users found',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
               : ListView.builder(
                  itemCount: _searchResults.isEmpty && _searchController.text.isEmpty 
                    ? _recentSearches.length 
                    : _searchResults.length,
                  itemBuilder: (context, index) {
                    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Recent Searches',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            _buildUserTile(_recentSearches[index], isHistory: true),
                          ],
                        );
                      }
                      return _buildUserTile(_recentSearches[index], isHistory: true);
                    }
                    return _buildUserTile(_searchResults[index]);
                  },
                ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, {bool isHistory = false}) {
    final username = user['username'] ?? user['full_name'] ?? 'User';
    final fullName = user['full_name'] ?? '';
    final avatarUrl = user['avatar_url'];

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
        backgroundColor: Colors.grey[200],
        child: avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: fullName.isNotEmpty ? Text(fullName) : null,
      trailing: isHistory 
        ? IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: () => _removeFromHistory(user['id']),
          )
        : null,
      onTap: () {
        _saveToHistory(user);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SocialProfilePage(userId: user['id']),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
