import 'package:codenyx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Admin Panel', style: AppTheme.cardTitle),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: AppTheme.accentCardDecoration(
                borderRadius: AppTheme.radiusLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ADMIN ACCESS', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Manage core hackathon operations from one place.',
                    style: AppTheme.cardBody.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _AdminActionTile(
              icon: Icons.campaign_outlined,
              title: 'Manage Announcements',
              subtitle: 'Create or update event-wide notices.',
              onTap: () => _showPlaceholder(context, 'Manage Announcements'),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _AdminActionTile(
              icon: Icons.support_agent_outlined,
              title: 'View Mentor Requests',
              subtitle: 'Review incoming support and mentoring requests.',
              onTap: () => _showPlaceholder(context, 'View Mentor Requests'),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _AdminActionTile(
              icon: Icons.report_gmailerrorred_outlined,
              title: 'Complaints',
              subtitle: 'Track complaints and moderation placeholders.',
              onTap: () => _showPlaceholder(context, 'Complaints'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showPlaceholder(BuildContext context, String title) {
    debugPrint('Admin action tapped: $title');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Ink(
          decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(icon, color: AppTheme.accentPrimary, size: 22),
                ),
                const SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.cardTitle),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(subtitle, style: AppTheme.cardBody),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
