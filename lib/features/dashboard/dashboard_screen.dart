// dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/layout/web_wrapper.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_repository.dart';
import '../complaints/user_complaints_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/session_service.dart';
import '../social_feed/feed_screen.dart';
import '../user/user_updates_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _hasUnreadUpdates = true;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _pageController.addListener(() {
      setState(() {
        _selectedIndex = _pageController.page?.round() ?? 0;
        if (_selectedIndex == 2) {
          _hasUnreadUpdates = false;
        }
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
                  const WebWrapper(child: UserComplaintsScreen()),
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

              /*// Team section
              const Text("TEAM", style: AppTheme.sectionHeader),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                teamName.isEmpty ? teamId : teamName,
                style: AppTheme.pageTitle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: AppTheme.spacingS),
              if (projectName.isNotEmpty)
                Text(projectName, style: AppTheme.metaText),*/
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
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBackground.withOpacity(0.65),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: "Dashboard",
                  index: 0,
                ),
                _buildNavBarItem(
                  icon: Icons.dynamic_feed_rounded,
                  label: "Feed",
                  index: 1,
                ),
                _buildNavBarItem(
                  icon: Icons.notifications_rounded,
                  label: "Updates",
                  index: 2,
                  showBadge: _hasUnreadUpdates,
                ),
                _buildNavBarItem(
                  icon: Icons.report_rounded,
                  label: "Complaints",
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required int index,
    bool showBadge = false,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppTheme.spacingL : AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentPrimary.withOpacity(0.25),
                    AppTheme.accentSecondary.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPrimary.withOpacity(0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.accentPrimary
                      : AppTheme.textSecondary.withOpacity(0.8),
                  size: 22,
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryBackground,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: AppTheme.navLabel.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final isCurrentUser = member['email'] == userEmail;
    final name = member['name']?.toString() ?? 'Unknown';
    final college = member['college']?.toString() ?? 'Unknown College';
    final linkedinUrl = member['linkedin_url']?.toString() ?? '';
    final hasLinkedin = linkedinUrl.isNotEmpty;
    final isJoined = member['joined'] == true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final List<List<Color>> avatarGradients = [
      [const Color(0xFF4F8EF7), const Color(0xFF845EF7)],
      [const Color(0xFF20C997), const Color(0xFF4F8EF7)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFD93D)],
      [AppTheme.accentPrimary, AppTheme.accentSecondary],
    ];
    final gradient =
        avatarGradients[initial.codeUnitAt(0) % avatarGradients.length];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.accentPrimary.withOpacity(0.05)
            : AppTheme.surfaceLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.accentPrimary.withOpacity(0.35)
              : AppTheme.borderColor.withOpacity(0.6),
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Gradient Avatar ──
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingL),

          // ── Name + College ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name row + "You" chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTheme.cardTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppTheme.accentPrimary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'You',
                          style: AppTheme.metaText.copyWith(
                            color: AppTheme.accentPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                // College + LinkedIn circle on same row
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 12,
                      color: AppTheme.textSecondary.withOpacity(0.45),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        college,
                        style: AppTheme.metaText.copyWith(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withOpacity(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (hasLinkedin) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse(linkedinUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/linkedin-transparent.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppTheme.spacingM),

          // ── Joined / Pending badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isJoined
                  ? Colors.green.withOpacity(0.12)
                  : Colors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: isJoined
                    ? Colors.green.withOpacity(0.28)
                    : Colors.amber.withOpacity(0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isJoined ? Colors.green : Colors.amber,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isJoined ? 'Joined' : 'Pending',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: isJoined ? Colors.green : Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
