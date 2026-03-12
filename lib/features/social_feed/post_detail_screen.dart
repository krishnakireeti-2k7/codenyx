import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/session_service.dart';
import 'feed_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userEmail;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.userEmail,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late List<Map<String, dynamic>> comments = [];
  bool loading = true;
  bool isLiked = false;
  int likeCount = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes_count'] ?? 0;
    _loadComments();
    _checkIfLiked();
  }

  Future<void> _loadComments() async {
    try {
      final data = await FeedRepository.getComments(widget.post['id']);
      setState(() {
        comments = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final liked = await FeedRepository.hasUserLikedPost(
        widget.post['id'],
        widget.userEmail,
      );
      setState(() {
        isLiked = liked;
      });
    } catch (e) {
      print('Error checking like: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      if (isLiked) {
        await FeedRepository.unlikePost(widget.post['id'], widget.userEmail);
        setState(() {
          isLiked = false;
          likeCount--;
        });
      } else {
        await FeedRepository.likePost(widget.post['id'], widget.userEmail);
        setState(() {
          isLiked = true;
          likeCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addComment() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        title: const Text('Add Comment', style: AppTheme.cardTitle),
        content: TextField(
          controller: controller,
          style: AppTheme.cardBody,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What do you think?',
            hintStyle: AppTheme.metaText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: const BorderSide(
                color: AppTheme.accentPrimary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.cardTitle.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment cannot be empty')),
                );
                return;
              }

              try {
                await FeedRepository.addComment(
                  widget.post['id'],
                  widget.userEmail,
                  controller.text,
                );

                Navigator.pop(context);
                _loadComments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment added! ✅')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(
              'Post',
              style: AppTheme.cardTitle.copyWith(color: AppTheme.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    try {
      await FeedRepository.deleteComment(comment['id']);

      setState(() {
        comments.removeWhere((c) => c['id'] == comment['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
    }
  }

  /// DELETE POST - Only available to post author
  void _deletePost() async {
    // Check if user is the post author
    final isAuthor = await FeedRepository.isPostAuthor(
      widget.post['id'],
      widget.userEmail,
    );

    if (!isAuthor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Delete Post?', style: AppTheme.cardTitle),
        content: Text(
          'This action cannot be undone.',
          style: AppTheme.cardBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.cardTitle.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performDeletePost();
            },
            child: Text(
              'Delete',
              style: AppTheme.cardTitle.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PERFORM DELETE - Actually deletes from Supabase
  Future<void> _performDeletePost() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Actually delete from Supabase
      await FeedRepository.deletePost(
        widget.post['id'],
        imageUrl: widget.post['image_url'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Pop back to feed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      print('Error deleting post: $e');

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isPostAuthor = widget.userEmail == post['user_email'];

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post Details', style: AppTheme.pageTitle),
        centerTitle: false,
        // DELETE BUTTON IN 3-DOT MENU (not in AppBar)
        actions: [
          if (isPostAuthor)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
              color: AppTheme.surfaceLight,
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.red),
                      const SizedBox(width: AppTheme.spacingM),
                      Text(
                        'Delete Post',
                        style: AppTheme.cardBody.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// POST HEADER
                    _buildPostHeader(post),

                    const SizedBox(height: AppTheme.spacingXL),

                    /// POST CONTENT
                    _buildPostContent(post),

                    const SizedBox(height: AppTheme.spacingXL),

                    if (post['image_url'] != null &&
                        (post['image_url'] as String).isNotEmpty)
                      const SizedBox(height: AppTheme.spacingXL),

                    /// ACTIONS (Like, Comments)
                    _buildPostActions(),

                    const SizedBox(height: AppTheme.spacingXL),

                    /// COMMENTS SECTION
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> post) {
    return Row(
      children: [
        /// AUTHOR AVATAR
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Center(
            child: Text(
              (post['user_email'] as String)[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingL),

        /// AUTHOR INFO
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['user_email'] ?? 'Unknown', style: AppTheme.cardTitle),
              const SizedBox(height: 4),
              Text(_formatTime(post['created_at']), style: AppTheme.metaText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(Map<String, dynamic> post) {
    final String? content = post['content'];
    final String? imageUrl = post['image_url'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TEXT CONTENT (Twitter style)
        if (content != null && content.trim().isNotEmpty)
          Text(
            content,
            style: AppTheme.cardBody.copyWith(
              fontSize: 17,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),

        /// SPACE BETWEEN TEXT AND IMAGE
        if (content != null &&
            content.trim().isNotEmpty &&
            imageUrl != null &&
            imageUrl.isNotEmpty)
          const SizedBox(height: AppTheme.spacingL),

        /// IMAGE CONTENT
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.textTertiary,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPostImage(Map<String, dynamic> post) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Image.network(
        post['image_url'],
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppTheme.textTertiary,
                size: 48,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostActions() {
    return Row(
      children: [
        /// LIKE BUTTON
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: isLiked
                  ? AppTheme.accentPrimary.withOpacity(0.15)
                  : AppTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isLiked
                    ? AppTheme.accentPrimary.withOpacity(0.3)
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? AppTheme.accentPrimary
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  '$likeCount',
                  style: AppTheme.cardTitle.copyWith(
                    color: isLiked
                        ? AppTheme.accentPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppTheme.spacingM),

        /// COMMENT BUTTON
        Expanded(
          child: GestureDetector(
            onTap: _addComment,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.accentSecondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.accentSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    'Comment',
                    style: AppTheme.cardTitle.copyWith(
                      color: AppTheme.accentSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMMENTS', style: AppTheme.sectionHeader),
        const SizedBox(height: AppTheme.spacingL),

        /// COMMENTS LIST
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.accentPrimary,
                ),
              ),
            ),
          )
        else if (comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text('No comments yet', style: AppTheme.cardBody),
                  const SizedBox(height: AppTheme.spacingM),
                  Text('Be the first to comment!', style: AppTheme.metaText),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingM),
            itemBuilder: (_, index) {
              final comment = comments[index];
              return _buildCommentCard(comment);
            },
          ),

        const SizedBox(height: AppTheme.spacingL),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// COMMENT AUTHOR
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    (comment['user_email'] as String)[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.spacingM),

              Expanded(
                child: Text(
                  comment['user_email'] ?? 'Unknown',
                  style: AppTheme.metaText.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              /// THREE DOT MENU (only if comment author)
              if (comment['user_email'] == widget.userEmail)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  color: AppTheme.surfaceLight,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteComment(comment);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: AppTheme.cardBody.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          /// COMMENT TEXT
          Text(
            comment['comment'] ?? '',
            style: AppTheme.cardBody.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
