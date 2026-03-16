import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/social/widgets/social_post_card.dart';
import 'package:flow/features/social/pages/post_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArchivedPostsPage extends StatefulWidget {
  const ArchivedPostsPage({super.key});

  @override
  State<ArchivedPostsPage> createState() => _ArchivedPostsPageState();
}

class _ArchivedPostsPageState extends State<ArchivedPostsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _archivedPosts = [];
  bool _isLoading = true;
  Set<String> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _loadArchivedPosts();
  }

  Future<void> _loadArchivedPosts() async {
    try {
      final archived = await _supabaseService.getArchivedPosts();
      final likes = await _supabaseService.getUserLikes();
      
      if (mounted) {
        setState(() {
          _archivedPosts = archived;
          _likedPosts = likes.map((e) => e['post_id'].toString()).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingArchivedPosts(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.archive),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No archived posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posts you archive will appear here',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadArchivedPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _archivedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _archivedPosts[index];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(
                                post: post,
                                likedPosts: _likedPosts,
                                onLikeToggle: (postId, isLiked) async {
                                  setState(() {
                                    if (isLiked) {
                                      _likedPosts.remove(postId);
                                    } else {
                                      _likedPosts.add(postId);
                                    }
                                  });
                                  await _supabaseService.toggleLike(postId);
                                },
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadArchivedPosts();
                          }
                        },
                        child: SocialPostCard(
                          post: post,
                          likedPosts: _likedPosts,
                          onLikeToggle: (postId, isLiked) async {
                            setState(() {
                              if (isLiked) {
                                _likedPosts.remove(postId);
                              } else {
                                _likedPosts.add(postId);
                              }
                            });
                            await _supabaseService.toggleLike(postId);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

