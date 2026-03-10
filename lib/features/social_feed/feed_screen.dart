import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/session_service.dart';
import 'create_post_screen.dart';
import 'feed_repository.dart';

class FeedScreen extends StatefulWidget {
  final String teamId;

  const FeedScreen({super.key, required this.teamId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;
  late ScrollController _scrollController;
  int _currentOffset = 0;
  List<Map<String, dynamic>> _allPosts = [];
  String? _userEmail;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserEmail();
    _postsFuture = FeedRepository.fetchPosts(offset: _currentOffset);
  }

  Future<void> _loadUserEmail() async {
    final session = await SessionService.getSession();
    setState(() {
      _userEmail = session['email'];
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentOffset += 20;
    });

    try {
      final newPosts = await FeedRepository.fetchPosts(offset: _currentOffset);
      setState(() {
        _allPosts.addAll(newPosts);
      });
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _currentOffset = 0;
      _allPosts = [];
      _postsFuture = FeedRepository.fetchPosts(offset: 0);
    });
  }

  void _openCreatePostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          teamId: widget.teamId,
          onPostCreated: _refreshFeed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentPrimary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text('Error loading feed', style: AppTheme.cardTitle),
                      const SizedBox(height: AppTheme.spacingM),
                      GestureDetector(
                        onTap: _refreshFeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingL,
                            vertical: AppTheme.spacingM,
                          ),
                          decoration: AppTheme.cardDecoration(),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                _allPosts = [];
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text(
                        'No posts yet',
                        style: AppTheme.pageTitle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Be the first to share your progress!',
                        style: AppTheme.cardBody,
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      GestureDetector(
                        onTap: _openCreatePostScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingL,
                            vertical: AppTheme.spacingM,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentPrimary.withOpacity(0.2),
                                AppTheme.accentSecondary.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.accentPrimary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.accentPrimary,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              const Text(
                                'Create First Post',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  color: AppTheme.accentPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              _allPosts = snapshot.data!;

              return RefreshIndicator(
                onRefresh: _refreshFeed,
                color: AppTheme.accentPrimary,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    AppTheme.spacingM,
                    AppTheme.spacingL,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandHeader(),
                      const SizedBox(height: AppTheme.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Social Feed", style: AppTheme.pageTitle),
                          GestureDetector(
                            onTap: _openCreatePostScreen,
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppTheme.accentPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        "Stay updated with your team",
                        style: AppTheme.cardBody,
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      const Text(
                        "RECENT ACTIVITY",
                        style: AppTheme.sectionHeader,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      ..._allPosts.map((post) => _buildPostCard(post)),
                      if (_isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingL,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset('assets/logo/gdg-logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                AppTheme.colorRed,
                AppTheme.colorOrange,
                AppTheme.colorYellow,
                AppTheme.colorGreen,
                AppTheme.colorBlue,
                AppTheme.colorPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text('codenyx', style: AppTheme.hackathonTitle),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isHighlighted =
        post['likes_count'] != null && post['likes_count'] > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: isHighlighted
          ? AppTheme.accentCardDecoration()
          : AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with author
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    (post['user_email'] as String)[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user_email'] ?? 'Unknown',
                      style: AppTheme.cardTitle.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(post['created_at']),
                      style: AppTheme.metaText,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Post content
          Text(post['content'] ?? '', style: AppTheme.cardBody),

          const SizedBox(height: AppTheme.spacingL),

          // Post image if exists
          if (post['image_url'] != null &&
              (post['image_url'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Image.network(
                  post['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: AppTheme.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Post actions (like, comment)
          Row(
            children: [
              GestureDetector(
                onTap: _userEmail != null
                    ? () => _toggleLike(post['id'])
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: AppTheme.accentPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes_count'] ?? 0}',
                        style: AppTheme.metaText.copyWith(
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              GestureDetector(
                onTap: () => _showCommentDialog(post['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.accentSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Comment',
                        style: AppTheme.metaText.copyWith(
                          color: AppTheme.accentSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLike(String postId) async {
    if (_userEmail == null) return;

    try {
      final hasLiked = await FeedRepository.hasUserLikedPost(
        postId,
        _userEmail!,
      );

      if (hasLiked) {
        await FeedRepository.unlikePost(postId, _userEmail!);
      } else {
        await FeedRepository.likePost(postId, _userEmail!);
      }

      _refreshFeed();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _showCommentDialog(String postId) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Add Comment', style: AppTheme.cardTitle),
        content: TextField(
          controller: commentController,
          style: AppTheme.cardBody,
          decoration: InputDecoration(
            hintText: 'Your comment...',
            hintStyle: AppTheme.metaText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
          maxLines: 3,
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
              if (commentController.text.isNotEmpty && _userEmail != null) {
                try {
                  await FeedRepository.addComment(
                    postId,
                    _userEmail!,
                    commentController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshFeed();
                  }
                } catch (e) {
                  print('Error adding comment: $e');
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
