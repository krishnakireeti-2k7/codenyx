import '../../services/supabase_service.dart';

class FeedRepository {
  /// Create a new post
  static Future<Map<String, dynamic>> createPost({
    required String userEmail,
    required String teamId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('posts')
          .insert({
            'user_email': userEmail,
            'team_id': teamId,
            'content': content,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  /// Fetch all posts with pagination
  static Future<List<Map<String, dynamic>>> fetchPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('posts')
          .select(
            'id, user_email, team_id, content, image_url, created_at, '
            'likes(count).count().as(likes_count)',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  /// Get a single post by ID
  static Future<Map<String, dynamic>> getPost(String postId) async {
    try {
      final response = await SupabaseService.client
          .from('posts')
          .select()
          .eq('id', postId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching post: $e');
      rethrow;
    }
  }

  /// Like a post
  static Future<void> likePost(String postId, String userEmail) async {
    try {
      await SupabaseService.client.from('likes').insert({
        'post_id': postId,
        'user_email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  /// Unlike a post
  static Future<void> unlikePost(String postId, String userEmail) async {
    try {
      await SupabaseService.client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_email', userEmail);
    } catch (e) {
      print('Error unliking post: $e');
      rethrow;
    }
  }

  /// Check if user has liked a post
  static Future<bool> hasUserLikedPost(String postId, String userEmail) async {
    try {
      final response = await SupabaseService.client
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_email', userEmail);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if user liked post: $e');
      return false;
    }
  }

  /// Get likes count for a post
  static Future<int> getLikesCount(String postId) async {
    try {
      final response = await SupabaseService.client
          .from('likes')
          .select()
          .eq('post_id', postId);

      return response.length;
    } catch (e) {
      print('Error getting likes count: $e');
      return 0;
    }
  }

  /// Add a comment to a post
  static Future<Map<String, dynamic>> addComment(
    String postId,
    String userEmail,
    String comment,
  ) async {
    try {
      final response = await SupabaseService.client
          .from('comments')
          .insert({
            'post_id': postId,
            'user_email': userEmail,
            'comment': comment,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for a post
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  /// Delete a post (only by author)
  static Future<void> deletePost(String postId) async {
    try {
      await SupabaseService.client.from('posts').delete().eq('id', postId);
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  /// Real-time updates handled through manual refresh
  /// For production, implement Supabase Realtime properly
  static Future<void> refreshFeed() async {
    // This can be called manually when user pulls to refresh
    // Or can be integrated with Supabase Realtime when properly configured
    print('Feed refreshed');
  }
}
