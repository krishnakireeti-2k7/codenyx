import 'package:codenyx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';
import 'manage_announcements_screen.dart';
import 'manage_mentor_requests_screen.dart';

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingL),
            child: GestureDetector(
              onTap: () async {
                await AuthRepository.signOut();
                if (!context.mounted) return;
                context.go('/');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageAnnouncementsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            _AdminActionTile(
              icon: Icons.support_agent_outlined,
              title: 'View Mentor Requests',
              subtitle: 'Review incoming support and mentoring requests.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageMentorRequestsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            _AdminActionTile(
              icon: Icons.report_gmailerrorred_outlined,
              title: 'Complaints',
              subtitle: 'Track complaints and moderation placeholders.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complaints module coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
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
