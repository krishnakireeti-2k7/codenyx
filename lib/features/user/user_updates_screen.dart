import 'package:codenyx/core/theme/app_theme.dart';
import 'package:codenyx/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserUpdatesScreen extends StatefulWidget {
  const UserUpdatesScreen({super.key});

  @override
  State<UserUpdatesScreen> createState() => _UserUpdatesScreenState();
}

class _UserUpdatesScreenState extends State<UserUpdatesScreen> {
  String _teamId = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _mentorRequests = [];

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    try {
      final session = await SessionService.getSession();
      final teamId = (session['teamId'] ?? '').toString();

      final announcementsResponse = await Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> mentorRequestsResponse = [];
      if (teamId.isNotEmpty) {
        final mentorResponse = await Supabase.instance.client
            .from('mentor_requests')
            .select()
            .eq('team_id', teamId)
            .order('created_at', ascending: false);

        mentorRequestsResponse = List<Map<String, dynamic>>.from(mentorResponse);
      }

      if (!mounted) return;

      setState(() {
        _teamId = teamId;
        _announcements = List<Map<String, dynamic>>.from(announcementsResponse);
        _mentorRequests = mentorRequestsResponse;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load user updates: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load updates: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingL,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ANNOUNCEMENTS', style: AppTheme.sectionHeader),
            const SizedBox(height: AppTheme.spacingM),
            if (_announcements.isEmpty)
              _buildEmptyCard('No announcements available right now.')
            else
              ..._announcements.map(
                (announcement) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _AnnouncementCard(announcement: announcement),
                ),
              ),
            const SizedBox(height: AppTheme.spacingXL),
            const Text('MENTOR REQUESTS', style: AppTheme.sectionHeader),
            const SizedBox(height: AppTheme.spacingM),
            if (_teamId.isEmpty)
              _buildEmptyCard('No team session found for mentor requests.')
            else if (_mentorRequests.isEmpty)
              _buildEmptyCard('No mentor requests created for your team yet.')
            else
              ..._mentorRequests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _MentorRequestCard(request: request),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Text(message, style: AppTheme.cardBody),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Map<String, dynamic> announcement;

  @override
  Widget build(BuildContext context) {
    final title = (announcement['title'] ?? 'Untitled').toString();
    final message = (announcement['message'] ?? '').toString();
    final createdAt = (announcement['created_at'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.cardTitle),
          const SizedBox(height: AppTheme.spacingS),
          Text(message, style: AppTheme.cardBody),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text('Created: $createdAt', style: AppTheme.metaText),
          ],
        ],
      ),
    );
  }
}

class _MentorRequestCard extends StatelessWidget {
  const _MentorRequestCard({required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final category = (request['category'] ?? 'General').toString();
    final description = (request['description'] ?? '').toString();
    final status = (request['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category, style: AppTheme.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labelForStatus(status),
                  style: AppTheme.metaText.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(description, style: AppTheme.cardBody),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.amber;
    }
  }

  static String _labelForStatus(String status) {
    if (status.isEmpty) return 'Pending';
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}
