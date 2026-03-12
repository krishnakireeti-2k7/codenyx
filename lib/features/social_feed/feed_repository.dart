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
            'id, user_email, team_id, content, image_url, created_at, likes(count)',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = List<Map<String, dynamic>>.from(response);

      for (var post in posts) {
        post['likes_count'] =
            (post['likes'] != null && post['likes'].isNotEmpty)
            ? post['likes'][0]['count']
            : 0;
      }

      return posts;
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  static Future<void> deleteComment(String commentId) async {
    try {
      await SupabaseService.client
          .from('comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      print('Error deleting comment: $e');
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

  /// Check if post belongs to user (authorization check)
  static Future<bool> isPostAuthor(String postId, String userEmail) async {
    try {
      final response = await SupabaseService.client
          .from('posts')
          .select('user_email')
          .eq('id', postId)
          .single();

      return response['user_email'] == userEmail;
    } catch (e) {
      print('Error checking post author: $e');
      return false;
    }
  }

  /// Delete image from Supabase Storage
  static Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      // Extract file name from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/feed-images/filename.jpg
      final fileName = imageUrl.split('/').last;

      await SupabaseService.client.storage.from('feed-images').remove([
        fileName,
      ]);

      print('Image deleted from storage: $fileName');
    } catch (e) {
      print('Error deleting image from storage: $e');
      // Don't rethrow - continue even if image deletion fails
    }
  }

  /// Delete a post and its associated image
  static Future<void> deletePost(String postId, {String? imageUrl}) async {
    try {
      // Delete image from storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteImageFromStorage(imageUrl);
      }

      // Delete all likes associated with the post
      await SupabaseService.client.from('likes').delete().eq('post_id', postId);

      // Delete all comments associated with the post
      await SupabaseService.client
          .from('comments')
          .delete()
          .eq('post_id', postId);

      // Delete the post itself
      await SupabaseService.client.from('posts').delete().eq('id', postId);

      print('Post deleted successfully: $postId');
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
