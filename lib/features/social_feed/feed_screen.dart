import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hackathon name header
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            AppTheme.accentPrimary,
                            AppTheme.accentSecondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'codenyx',
                        style: AppTheme.hackathonTitle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXL),

                const Text("Social Feed", style: AppTheme.pageTitle),

                const SizedBox(height: AppTheme.spacingM),

                Text("Stay updated with your team", style: AppTheme.cardBody),

                const SizedBox(height: AppTheme.spacingXXL),

                const Text("RECENT ACTIVITY", style: AppTheme.sectionHeader),

                const SizedBox(height: AppTheme.spacingL),

                // Feed items
                ..._buildFeedItems(),

                const SizedBox(height: 100), // Space for nav bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeedItems() {
    final feedItems = [
      {
        'icon': Icons.emoji_events_outlined,
        'title': 'Team Update',
        'description': 'Check out the latest team announcements',
        'time': '2 hours ago',
        'isHighlighted': true,
      },
      {
        'icon': Icons.person_add_outlined,
        'title': 'New Member Joined',
        'description': 'Welcome to the team! 🎉',
        'time': '4 hours ago',
        'isHighlighted': false,
      },
      {
        'icon': Icons.assignment_outlined,
        'title': 'Submission Deadline',
        'description': 'Don\'t forget to submit your work',
        'time': '1 day ago',
        'isHighlighted': false,
      },
      {
        'icon': Icons.code_outlined,
        'title': 'Code Review Complete',
        'description': 'Your submission has been reviewed',
        'time': '2 days ago',
        'isHighlighted': false,
      },
    ];

    return feedItems
        .map(
          (item) => _buildFeedCard(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            description: item['description'] as String,
            time: item['time'] as String,
            isHighlighted: item['isHighlighted'] as bool,
          ),
        )
        .toList();
  }

  Widget _buildFeedCard({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isHighlighted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: isHighlighted
          ? AppTheme.accentCardDecoration()
          : AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppTheme.accentPrimary.withOpacity(0.15)
                  : AppTheme.accentSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              color: isHighlighted
                  ? AppTheme.accentPrimary
                  : AppTheme.accentSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.cardTitle),
                const SizedBox(height: AppTheme.spacingM),
                Text(description, style: AppTheme.cardBody),
                const SizedBox(height: AppTheme.spacingM),
                Text(time, style: AppTheme.metaText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
