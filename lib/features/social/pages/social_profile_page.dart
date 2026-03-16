import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/features/social/pages/full_screen_image_page.dart';
import 'package:flow/features/social/pages/setup_social_profile_page.dart';
import 'package:flow/features/social/widgets/text_post_widget.dart';
import 'package:flow/features/social/pages/edit_profile_page.dart';
import 'package:flow/features/social/pages/post_detail_page.dart';
import 'package:flow/features/social/pages/social_settings_page.dart';
import 'package:flow/features/social/pages/saved_posts_page.dart';
import 'package:flow/features/social/pages/archived_posts_page.dart';
import 'package:flow/l10n/app_localizations.dart';

class SocialProfilePage extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const SocialProfilePage({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<SocialProfilePage> createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  Set<String> _likedPosts = {};
  int _streakCount = 0;
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _checkUsernameAndLoad();
  }

  Future<void> _checkUsernameAndLoad() async {
    final hasUsername = await _supabaseService.hasUsername();
    
    if (!hasUsername && mounted) {
      final result = await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SetupSocialProfilePage(),
          fullscreenDialog: true,
        ),
      );
      
      if (result == true && mounted) {
        _loadProfile();
      }
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final userId = widget.userId;
      
      // Fetch profile data
      final profile = await _supabaseService.getProfileById(userId);
      if (profile == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileNotFound)),
          );
        }
        return;
      }

      // Fetch posts, followers, following counts
      final posts = await _supabaseService.getUserPosts(userId);
      final followersCount = await _supabaseService.getFollowersCount(userId);
      final followingCount = await _supabaseService.getFollowingCount(userId);
      final streakCount = await _supabaseService.getStreakCount(userId);
      
      // Check if current user is following this profile
      bool isFollowing = false;
      final currentUserId = _supabaseService.getCurrentUserId();
      final isSelf = userId == currentUserId;

      if (!widget.isCurrentUser && !isSelf) {
        isFollowing = await _supabaseService.isFollowing(userId);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = posts;
          _followersCount = followersCount;
          _followingCount = followingCount;
          _streakCount = streakCount;
          _streakCount = streakCount;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
        _loadLikes();
        _loadBadges();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingProfile(e.toString()))),
        );
      }
    }
  }

  Future<void> _loadLikes() async {
    try {
      final likes = await _supabaseService.getUserLikes();
      if (mounted) {
        setState(() {
          _likedPosts = likes.map((e) => e['post_id'].toString()).toSet();
        });
      }
    } catch (e) {
      print('Error loading likes: $e');
    }
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _supabaseService.getUserBadges(widget.userId);
      if (mounted) {
        setState(() => _badges = badges);
      }
    } catch (e) {
      print('Error loading badges: $e');
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SocialSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text(AppLocalizations.of(context)!.savedPosts),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedPostsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(AppLocalizations.of(context)!.archive),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArchivedPostsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?['username'] ?? 'Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _showMenu,
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(),
                ]),
              ),
            ];
          },
          body: Column(
            children: [
              const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPostsGrid(),
                    Center(child: Text(AppLocalizations.of(context)!.taggedPostsComingSoon)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(_posts.length, 'Posts'),
                    _buildStatColumn(_followersCount, 'Followers'),
                    _buildStatColumn(_followingCount, 'Following'),
                    _buildStatColumn(_streakCount, 'Streak', icon: '🔥'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile?['full_name'] ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(_profile?['bio'] ?? ''),
          if (_badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBadgesSection(),
          ],
          const SizedBox(height: 16),
          if (!widget.isCurrentUser && widget.userId != _supabaseService.getCurrentUserId())
            _buildFollowButton()
          else
            _buildEditProfileButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = _profile?['avatar_url'];
    final bool hasStreak = _streakCount > 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasStreak 
                ? const LinearGradient(
                    colors: [Colors.orange, Colors.red, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: !hasStreak ? Border.all(color: Colors.grey.shade300, width: 1) : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
              child: url == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
            ),
          ),
        ),
        if (hasStreak)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.yellow, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '$_streakCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final challenge = _badges[index]['challenges']; // joined table
          return Tooltip(
            message: challenge['title'] ?? challenge['Name_English'] ?? 'Badge',
            triggerMode: TooltipTriggerMode.tap,
            child: Container(
              width: 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: ClipOval(
                child: challenge['image_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: challenge['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(Icons.star, color: Colors.amber),
                      errorWidget: (context, url, _) => const Icon(Icons.emoji_events, color: Colors.amber),
                    )
                  : const Icon(Icons.emoji_events, color: Colors.amber),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(int count, String label, {String? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
            ],
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            if (_isFollowing) {
              await _supabaseService.unfollowUser(widget.userId);
            } else {
              await _supabaseService.followUser(widget.userId);
            }
            setState(() {
              _isFollowing = !_isFollowing;
              if (_isFollowing) _followersCount++; else _followersCount--;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey.shade200 : AppColors.primary,
          foregroundColor: _isFollowing ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(_isFollowing ? 'Following' : 'Follow'),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
          
          if (result == true && mounted) {
            _loadProfile(); // Reload profile after edit
          }
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(AppLocalizations.of(context)!.editProfile, style: const TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 40),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noPostsYet, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    // Store posts in state variable for grid
    final List<Map<String, dynamic>> _userPosts = _posts;
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final imageUrl = post['image_url'];

        return GestureDetector(
          onTap: () async {
            // Include profile data in the post for SocialPostCard
            final postWithProfile = Map<String, dynamic>.from(post);
            postWithProfile['profiles'] = _profile;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailPage(
                  post: postWithProfile,
                  likedPosts: _likedPosts,
                  onLikeToggle: (postId, isLiked) async {
                    setState(() {
                      if (isLiked) {
                        _likedPosts.remove(postId);
                        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
                      } else {
                        _likedPosts.add(postId);
                        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
                      }
                    });
                    await _supabaseService.toggleLike(postId);
                  },
                ),
              ),
            );

            if (result == true && mounted) {
              _loadProfile(); // Reload if post was deleted
            }
          },
          child: imageUrl != null 
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                ),
              )
            : TextPostWidget(
                text: post['content'] ?? '', 
                height: double.infinity,
                fontSize: 10,
                padding: const EdgeInsets.all(4),
              ),
        );
      },
    );
  }
}
