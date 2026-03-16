import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flow/features/social/pages/social_profile_page.dart';
import 'package:flow/features/social/pages/comments_page.dart';
import 'package:flow/features/social/widgets/text_post_widget.dart';
import 'package:flow/features/social/pages/full_screen_image_page.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';

class SocialPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Set<String> likedPosts;
  final Function(String, bool) onLikeToggle;
  final VoidCallback? onDelete;

  const SocialPostCard({
    super.key,
    required this.post,
    required this.likedPosts,
    required this.onLikeToggle,
    this.onDelete,
  });

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  final SupabaseService _supabaseService = SupabaseService();

  void _showPostOptions() {
    final currentUserId = _supabaseService.getCurrentUserId();
    final isMyPost = widget.post['user_id'] == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyPost)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.deletePost, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onDelete != null) widget.onDelete!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.share),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final profile = post['profiles'];
    final username = profile?['username'] ?? 'user';
    final avatarUrl = profile?['avatar_url'];
    final postId = post['id'].toString();
    final isLiked = widget.likedPosts.contains(postId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SocialProfilePage(userId: profile?['id'] ?? 'mock')),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: Colors.grey[200],
                  child: avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (profile?['full_name'] != null)
                      Text(
                        profile?['full_name'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showPostOptions,
              ),
            ],
          ),
        ),
        
        // Image or Text Post
        if (post['image_url'] != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImagePage(
                    imageUrl: post['image_url'],
                    caption: post['content'],
                    likesCount: post['likes_count'] ?? 0,
                    commentsCount: post['comments_count'] ?? 0,
                  ),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: post['image_url'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
              placeholder: (context, url) => Container(height: 400, color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                height: 400, 
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
              ),
            ),
          )
        else if (post['content']?.toString().isNotEmpty == true)
          TextPostWidget(text: post['content'] ?? ''),

        // Actions & Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _buildInteractionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                count: post['likes_count'] ?? 0,
                color: isLiked ? Colors.red : Colors.black,
                onTap: () => widget.onLikeToggle(postId, isLiked),
              ),
              _buildInteractionButton(
                icon: Icons.mode_comment_outlined,
                count: post['comments_count'] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsPage(
                        postId: post['id'],
                        initialCommentCount: post['comments_count'] ?? 0,
                      ),
                    ),
                  );
                },
              ),
              _buildInteractionButton(
                icon: Icons.repeat, // Repost icon
                count: post['reposts_count'] ?? 0,
                onTap: () async {
                  final isReposted = await _supabaseService.toggleRepost(postId);
                  if (mounted) {
                    setState(() {
                      post['reposts_count'] = (post['reposts_count'] ?? 0) + (isReposted ? 1 : -1);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined, size: 24),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 26),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '$username ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post['content']),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getTimeAgo(post['created_at']),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = DateTime.parse(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}
