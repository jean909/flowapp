import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Service for managing Supabase Realtime subscriptions
/// Handles real-time updates for social feed, likes, comments, etc.
class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Store active subscriptions
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  
  /// Subscribe to new posts in social feed
  /// Returns a stream of new posts
  Stream<Map<String, dynamic>> subscribeToNewPosts({
    Function(Map<String, dynamic>)? onNewPost,
  }) {
    final channelName = 'social_posts_channel';
    
    // Cancel existing subscription if any
    unsubscribe(channelName);
    
    // Create a stream controller for the stream
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'social_posts',
          callback: (payload) {
            final newPost = Map<String, dynamic>.from(payload.newRecord);
            
            // Fetch full post data with profile info
            _fetchFullPostData(newPost['id'] as String).then((fullPost) {
              if (fullPost != null) {
                controller.add(fullPost);
                if (onNewPost != null) {
                  onNewPost(fullPost);
                }
              }
            });
          },
        )
        .subscribe();
    
    _channels[channelName] = channel;
    
    return controller.stream;
  }
  
  /// Subscribe to likes updates (when someone likes/unlikes a post)
  /// Returns a stream of like updates
  Stream<Map<String, dynamic>> subscribeToLikes({
    Function(String postId, bool isLiked, int newLikesCount)? onLikeUpdate,
  }) {
    final channelName = 'social_likes_channel';
    
    // Cancel existing subscription if any
    unsubscribe(channelName);
    
    // Create a stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'social_likes',
          callback: (payload) {
            final like = Map<String, dynamic>.from(payload.newRecord);
            final postId = like['post_id'] as String;
            
            // Update likes count
            _updatePostLikesCount(postId).then((newCount) {
              final update = {
                'post_id': postId,
                'is_liked': true,
                'likes_count': newCount,
              };
              controller.add(update);
              if (onLikeUpdate != null) {
                onLikeUpdate(postId, true, newCount);
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'social_likes',
          callback: (payload) {
            final oldLike = Map<String, dynamic>.from(payload.oldRecord);
            final postId = oldLike['post_id'] as String;
            
            // Update likes count
            _updatePostLikesCount(postId).then((newCount) {
              final update = {
                'post_id': postId,
                'is_liked': false,
                'likes_count': newCount,
              };
              controller.add(update);
              if (onLikeUpdate != null) {
                onLikeUpdate(postId, false, newCount);
              }
            });
          },
        )
        .subscribe();
    
    _channels[channelName] = channel;
    
    return controller.stream;
  }
  
  /// Subscribe to comments updates
  Stream<Map<String, dynamic>> subscribeToComments({
    Function(String postId, Map<String, dynamic> comment)? onNewComment,
  }) {
    final channelName = 'social_comments_channel';
    
    unsubscribe(channelName);
    
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'social_comments',
          callback: (payload) {
            final newComment = Map<String, dynamic>.from(payload.newRecord);
            final postId = newComment['post_id'] as String;
            
            // Fetch full comment data with profile
            _fetchFullCommentData(newComment['id'] as String).then((fullComment) {
              if (fullComment != null) {
                final update = {
                  'post_id': postId,
                  'comment': fullComment,
                };
                controller.add(update);
                if (onNewComment != null) {
                  onNewComment(postId, fullComment);
                }
              }
            });
          },
        )
        .subscribe();
    
    _channels[channelName] = channel;
    
    return controller.stream;
  }
  
  /// Subscribe to post updates (likes_count, comments_count changes)
  Stream<Map<String, dynamic>> subscribeToPostUpdates({
    Function(String postId, Map<String, dynamic> updates)? onPostUpdate,
  }) {
    final channelName = 'social_posts_updates_channel';
    
    unsubscribe(channelName);
    
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'social_posts',
          callback: (payload) {
            final updatedPost = Map<String, dynamic>.from(payload.newRecord);
            final postId = updatedPost['id'] as String;
            
            final update = {
              'post_id': postId,
              'updates': updatedPost,
            };
            controller.add(update);
            if (onPostUpdate != null) {
              onPostUpdate(postId, updatedPost);
            }
          },
        )
        .subscribe();
    
    _channels[channelName] = channel;
    
    return controller.stream;
  }
  
  /// Fetch full post data with profile information
  Future<Map<String, dynamic>?> _fetchFullPostData(String postId) async {
    try {
      final response = await _client
          .from('social_posts')
          .select('*, profiles(id, full_name, username, avatar_url), social_likes(user_id)')
          .eq('id', postId)
          .maybeSingle();
      
      if (response == null) return null;
      
      final post = Map<String, dynamic>.from(response);
      final userId = _client.auth.currentUser?.id;
      
      // Add is_liked flag
      if (userId != null) {
        final List<dynamic> likes = post['social_likes'] as List<dynamic>? ?? [];
        post['is_liked'] = likes.any((like) => like['user_id'] == userId);
      } else {
        post['is_liked'] = false;
      }
      
      return post;
    } catch (e) {
      print('Error fetching full post data: $e');
      return null;
    }
  }
  
  /// Fetch full comment data with profile
  Future<Map<String, dynamic>?> _fetchFullCommentData(String commentId) async {
    try {
      final response = await _client
          .from('social_comments')
          .select('*, profiles(full_name, avatar_url)')
          .eq('id', commentId)
          .maybeSingle();
      
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching full comment data: $e');
      return null;
    }
  }
  
  /// Update post likes count from database
  Future<int> _updatePostLikesCount(String postId) async {
    try {
      final response = await _client
          .from('social_posts')
          .select('likes_count')
          .eq('id', postId)
          .maybeSingle();
      
      if (response == null) return 0;
      return (response['likes_count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('Error updating likes count: $e');
      return 0;
    }
  }
  
  /// Unsubscribe from a specific channel
  void unsubscribe(String channelName) {
    // Remove channel
    final channel = _channels[channelName];
    if (channel != null) {
      _client.removeChannel(channel);
      _channels.remove(channelName);
    }
  }
  
  /// Unsubscribe from all channels
  void unsubscribeAll() {
    final channelNames = _channels.keys.toList();
    for (final channelName in channelNames) {
      unsubscribe(channelName);
    }
  }
  
  /// Dispose all subscriptions (call in dispose method)
  void dispose() {
    unsubscribeAll();
  }
}

