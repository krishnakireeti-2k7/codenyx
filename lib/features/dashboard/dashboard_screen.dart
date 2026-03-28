// dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/layout/web_wrapper.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/session_service.dart';
import '../social_feed/feed_screen.dart';
import '../user/user_updates_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String teamId = "";
  String teamName = "";
  String projectName = "";
  String userEmail = "";
  List members = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _pageController.addListener(() {
      setState(() {
        _selectedIndex = _pageController.page?.round() ?? 0;
      });
    });

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // 1. Try saved session first (fast path — works on mobile)
      final session = await SessionService.getSession();
      teamId = session['teamId'] ?? '';
      userEmail = session['email'] ?? '';

      // 2. If session is empty, resolve from Supabase auth (web reload path)
      if (teamId.isEmpty || userEmail.isEmpty) {
        print('⚠️ No saved session — resolving from Supabase auth...');

        final user = Supabase.instance.client.auth.currentUser;
        if (user == null || user.email == null) {
          print('❌ No authenticated user found');
          setState(() => _isLoading = false);
          return;
        }

        final rawEmail = user.email!;
        final normalizedEmail = AuthRepository.normalizeEmail(rawEmail);
        print('RAW EMAIL: "$rawEmail"');
        print('NORMALIZED EMAIL: "$normalizedEmail"');
        print('📧 Dashboard resolving team for: $normalizedEmail');

        final foundTeamId = await AuthRepository.findUserTeam(normalizedEmail);
        if (foundTeamId == null) {
          print('❌ No team found for this user');
          setState(() => _isLoading = false);
          return;
        }

        teamId = foundTeamId;
        userEmail = normalizedEmail;

        // Persist so next load is instant
        await SessionService.saveSession(normalizedEmail, foundTeamId);
        print('✅ Session saved from dashboard');
      }

      print('📊 Loading dashboard data for team: $teamId');

      if (teamId.isNotEmpty) {
        // Fetch team info
        final teamResponse = await SupabaseService.client
            .from('teams')
            .select()
            .eq('team_id', teamId)
            .maybeSingle();

        if (teamResponse != null) {
          teamName = teamResponse['team_name'] ?? '';
          projectName = teamResponse['project_name'] ?? '';
        }

        // Fetch team members
        final membersResponse = await SupabaseService.client
            .from('team_members')
            .select()
            .eq('team_id', teamId)
            .order('name', ascending: true);

        setState(() {
          members = membersResponse;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Logout?', style: AppTheme.cardTitle),
        content: Text(
          'Are you sure you want to logout?',
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
              Navigator.pop(context);
              await AuthRepository.signOut();
              if (!mounted) return;
              GoRouter.of(this.context).go('/');
            },
            child: Text(
              'Logout',
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),

            // Ambient glow
            Positioned(
              top: -80,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentPrimary.withOpacity(0.08),
                  ),
                ),
              ),
            ),

            // PageView with pages
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentPrimary,
                  ),
                ),
              )
            else
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDashboardPage(),
                  WebWrapper(child: FeedScreen(teamId: teamId)),
                  const WebWrapper(child: UserUpdatesScreen()),
                ],
              ),

            // Floating nav bar (bottom) - KEPT IMPORTANT
            Positioned(
              left: AppTheme.spacingL,
              right: AppTheme.spacingL,
              bottom: bottomInset + AppTheme.spacingM,
              child: _buildFloatingNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage() {
    final memberCount = members.length;

    return SafeArea(
      child: WebWrapper(
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
              // Header with logout button
              _buildHeaderWithLogout(),
              const SizedBox(height: AppTheme.spacingL),

              // Quick stats
              _buildQuickStats(memberCount),
              SizedBox(height: kIsWeb ? AppTheme.spacingXL : AppTheme.spacingL),

              // Timer banner
              _buildTimerBanner(),
              SizedBox(height: kIsWeb ? AppTheme.spacingXL * 1.5 : AppTheme.spacingXL),

              // Team section
              const Text("TEAM", style: AppTheme.sectionHeader),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                teamName.isEmpty ? teamId : teamName,
                style: AppTheme.pageTitle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: AppTheme.spacingS),
              if (projectName.isNotEmpty)
                Text(projectName, style: AppTheme.metaText),
              SizedBox(height: kIsWeb ? AppTheme.spacingXL * 1.5 : AppTheme.spacingXL),

              // Team members
              _buildTeamMembers(memberCount),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithLogout() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
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
              colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text('codenyx', style: AppTheme.hackathonTitle),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _handleLogout,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.logout, color: Colors.red, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Logout',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(int memberCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Team ID',
            value: teamId.isEmpty ? '--' : teamId,
            icon: Icons.groups_rounded,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            title: 'Members',
            value: '$memberCount',
            icon: Icons.person_add_alt_1_rounded,
            highlighted: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool highlighted = false,
  }) {
    final accentColor = highlighted
        ? AppTheme.accentPrimary
        : AppTheme.accentSecondary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: highlighted
          ? AppTheme.accentCardDecoration(borderRadius: AppTheme.radiusLarge)
          : AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: AppTheme.spacingM),
          Text(title, style: AppTheme.metaText),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingL,
      ),
      decoration: AppTheme.bannerDecoration(isTimer: true),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppTheme.accentPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Build window",
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "12h 34m remaining",
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppTheme.accentPrimary.withOpacity(0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembers(int memberCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("TEAM MEMBERS", style: AppTheme.sectionHeader),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text('$memberCount', style: AppTheme.metaText),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        if (members.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text("No members yet", style: AppTheme.cardBody),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spacingM),
            itemBuilder: (_, index) => _buildMemberCard(members[index]),
          ),
      ],
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground.withOpacity(0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: "Dashboard",
                  index: 0,
                ),
              ),
              Expanded(
                child: _buildNavBarItem(
                  icon: Icons.dynamic_feed_rounded,
                  label: "Feed",
                  index: 1,
                ),
              ),
              Expanded(
                child: _buildNavBarItem(
                  icon: Icons.notifications_rounded,
                  label: "Updates",
                  index: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNavTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.accentPrimary.withOpacity(0.26),
                      AppTheme.accentSecondary.withOpacity(0.14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentPrimary.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTheme.navLabel.copyWith(
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final isCurrentUser = member['email'] == userEmail;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Row(
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
                (member['email'] as String)[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member['name'] ?? 'Unknown',
                        style: AppTheme.cardTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: AppTheme.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          'You',
                          style: AppTheme.metaText.copyWith(
                            color: AppTheme.accentPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(member['email'] ?? 'Unknown', style: AppTheme.metaText),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: (member['joined'] as bool)
                  ? Colors.green.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (member['joined'] as bool)
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: (member['joined'] as bool)
                      ? Colors.green
                      : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    (member['joined'] as bool) ? "Joined" : "Pending",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      color: (member['joined'] as bool)
                          ? Colors.green
                          : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
