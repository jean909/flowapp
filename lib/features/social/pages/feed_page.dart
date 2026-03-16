import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/realtime_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/features/social/pages/social_profile_page.dart';
import 'package:flow/features/social/pages/chat_list_page.dart';
import 'package:flow/features/social/pages/create_post_page.dart';
import 'package:flow/features/social/pages/search_users_page.dart';
import 'package:flow/features/social/pages/comments_page.dart';
import 'package:flow/features/social/pages/setup_social_profile_page.dart';
import 'package:flow/features/social/widgets/social_post_card.dart';
import 'dart:async';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key, this.onSwitchToDashboard});

  final VoidCallback? onSwitchToDashboard;

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final RealtimeService _realtimeService = RealtimeService();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  bool _isPopular = false;
  final Set<String> _likedPosts = {}; // Track which posts current user liked
  
  // Realtime subscriptions
  StreamSubscription<Map<String, dynamic>>? _newPostsSubscription;
  StreamSubscription<Map<String, dynamic>>? _likesSubscription;
  StreamSubscription<Map<String, dynamic>>? _postUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _checkUsernameAndLoad();
  }
  
  @override
  void dispose() {
    // Cancel all realtime subscriptions
    _newPostsSubscription?.cancel();
    _likesSubscription?.cancel();
    _postUpdatesSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAndLoad() async {
    final hasUsername = await _supabaseService.hasUsername();
    
    if (!hasUsername && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SetupSocialProfilePage(),
          fullscreenDialog: true,
        ),
      );
      if (!mounted) return;
      if (result == true) {
        _loadFeed();
      } else if (result == 'skip') {
        widget.onSwitchToDashboard?.call();
      }
    } else {
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    try {
      final posts = await _supabaseService.getSocialFeed(popular: _isPopular);
      final stories = await _supabaseService.getStories();
      final profile = await _supabaseService.getProfile();
      if (mounted) {
        setState(() {
          _posts = posts;
          _stories = stories;
          _profileAvatarUrl = profile?['avatar_url'];
          _isLoading = false;
          // Sync liked posts set with server data
          _likedPosts.clear();
          for (var post in posts) {
            if (post['is_liked'] == true) {
              _likedPosts.add(post['id'].toString());
            }
          }
        });
        
        // Setup realtime subscriptions after initial load
        _setupRealtimeSubscriptions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingFeed(e.toString()))),
        );
      }
    }
  }
  
  /// Setup realtime subscriptions for live updates
  void _setupRealtimeSubscriptions() {
    // Subscribe to new posts
    _newPostsSubscription = _realtimeService.subscribeToNewPosts(
      onNewPost: (newPost) {
        if (mounted) {
          setState(() {
            // Add new post at the beginning (most recent first)
            // Only add if not already in the list
            final postId = newPost['id'].toString();
            final exists = _posts.any((p) => p['id'].toString() == postId);
            if (!exists) {
              _posts.insert(0, newPost);
              
              // Show a subtle notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.fiber_new, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New post from ${newPost['profiles']?['username'] ?? 'someone'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      },
    ).listen((newPost) {
      // Stream listener (already handled in callback, but kept for compatibility)
    });
    
    // Subscribe to likes updates
    _likesSubscription = _realtimeService.subscribeToLikes(
      onLikeUpdate: (postId, isLiked, newLikesCount) {
        if (mounted) {
          setState(() {
            // Update the post in the list
            final postIndex = _posts.indexWhere(
              (p) => p['id'].toString() == postId,
            );
            
            if (postIndex != -1) {
              _posts[postIndex]['likes_count'] = newLikesCount;
            }
          });
        }
      },
    ).listen((likeUpdate) {
      // Stream listener - updates are handled in callback
      if (mounted) {
        final postId = likeUpdate['post_id'] as String;
        final newLikesCount = likeUpdate['likes_count'] as int;
        
        setState(() {
          final postIndex = _posts.indexWhere(
            (p) => p['id'].toString() == postId,
          );
          
          if (postIndex != -1) {
            _posts[postIndex]['likes_count'] = newLikesCount;
          }
        });
      }
    });
    
    // Subscribe to post updates (likes_count, comments_count changes)
    _postUpdatesSubscription = _realtimeService.subscribeToPostUpdates(
      onPostUpdate: (postId, updates) {
        if (mounted) {
          setState(() {
            final postIndex = _posts.indexWhere(
              (p) => p['id'].toString() == postId,
            );
            
            if (postIndex != -1) {
              // Update post with new data
              _posts[postIndex].addAll(updates);
            }
          });
        }
      },
    ).listen((update) {
      // Stream listener - updates are handled in callback
      if (mounted) {
        final postId = update['post_id'] as String;
        final updates = update['updates'] as Map<String, dynamic>;
        
        setState(() {
          final postIndex = _posts.indexWhere(
            (p) => p['id'].toString() == postId,
          );
          
          if (postIndex != -1) {
            _posts[postIndex].addAll(updates);
          }
        });
      }
    });
  }

  Widget _buildStories() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length + 1, // +1 for "Add Story"
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryItem();
          }
          final story = _stories[index - 1];
          final profile = story['profiles'];
          return _buildStoryItem(profile?['avatar_url'], profile?['username'] ?? 'User');
        },
      ),
    );
  }

  Widget _buildAddStoryItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profileAvatarUrl != null ? CachedNetworkImageProvider(_profileAvatarUrl!) : null,
                child: _profileAvatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.yourStory, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStoryItem(String? avatarUrl, String username) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.pink, Colors.purple],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 27,
                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                backgroundColor: Colors.grey[200],
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              username,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String? _profileAvatarUrl;
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.access_time, color: !_isPopular ? AppColors.primary : null),
            title: Text(AppLocalizations.of(context)!.recent, style: TextStyle(fontWeight: !_isPopular ? FontWeight.bold : null)),
            onTap: () {
              Navigator.pop(context);
              if (_isPopular) {
                setState(() {
                  _isPopular = false;
                  _isLoading = true;
                });
                _loadFeed();
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.trending_up, color: _isPopular ? AppColors.primary : null),
            title: Text(AppLocalizations.of(context)!.trending, style: TextStyle(fontWeight: _isPopular ? FontWeight.bold : null)),
            onTap: () {
              Navigator.pop(context);
              if (!_isPopular) {
                setState(() {
                  _isPopular = true;
                  _isLoading = true;
                });
                _loadFeed();
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showSortOptions,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.social, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                _isPopular ? 'Popular' : 'Recent',
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
            ],
          ),
        ),
        titleSpacing: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchUsersPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              final currentUserId = _supabaseService.getCurrentUserId();
              if (currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SocialProfilePage(userId: currentUserId, isCurrentUser: true),
                  ),
                );
              }
            },
            tooltip: AppLocalizations.of(context)!.myProfileTooltip,
          ),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.message_outlined), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage())),
          ), // Chat
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadFeed,
              child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _posts.length + 1, // +1 for stories header
              itemBuilder: (context, index) {
                if (index == 0) return _buildStories();
                
                final post = _posts[index - 1];
                return SocialPostCard(
                  post: post,
                  likedPosts: _likedPosts,
                  onLikeToggle: (postId, isLiked) async {
                    // Optimistic UI
                    setState(() {
                      if (isLiked) {
                        _likedPosts.remove(postId);
                        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
                        post['is_liked'] = false;
                      } else {
                        _likedPosts.add(postId);
                        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
                        post['is_liked'] = true;
                      }
                    });

                    try {
                      await _supabaseService.toggleLike(postId);
                    } catch (e) {
                      // Revert on error
                      if (mounted) {
                        setState(() {
                          if (isLiked) {
                            _likedPosts.add(postId);
                            post['likes_count'] = (post['likes_count'] ?? 0) + 1;
                          } else {
                            _likedPosts.remove(postId);
                            post['likes_count'] = (post['likes_count'] ?? 1) - 1;
                          }
                        });
                      }
                    }
                  },
                  onDelete: () async {
                    try {
                      await _supabaseService.deletePost(post['id']);
                      _loadFeed();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
          if (result == true) {
            _loadFeed(); // Reload feed after creating post
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}
