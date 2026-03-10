// dashboard_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/session_service.dart';
import '../social_feed/feed_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String teamId = "";
  List members = [];
  int _selectedIndex = 0;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    loadTeam();
    _pageController = PageController(initialPage: 0);

    _pageController.addListener(() {
      setState(() {
        _selectedIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> loadTeam() async {
    final prefs = await SessionService.getSession();
    teamId = prefs['teamId'];

    final response = await SupabaseService.client
        .from('team_members')
        .select()
        .eq('team_id', teamId);

    setState(() {
      members = response;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),

          // subtle ambient glow
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

          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildDashboardPage(),
              FeedScreen(teamId: teamId),
            ],
          ),

          Positioned(
            left: AppTheme.spacingL,
            right: AppTheme.spacingL,
            bottom: bottomInset + AppTheme.spacingM,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    final memberCount = members.length;

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
            _buildBrandHeader(),
            const SizedBox(height: AppTheme.spacingL),
            _buildQuickStats(memberCount),
            const SizedBox(height: AppTheme.spacingL),
            _buildTimerBanner(),
            const SizedBox(height: AppTheme.spacingXL),
            const Text("TEAM", style: AppTheme.sectionHeader),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              teamId.isEmpty ? "Loading team..." : teamId,
              style: AppTheme.pageTitle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            _buildTeamMembers(memberCount),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
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
          child: const Text('Dashboard', style: AppTheme.metaText),
        ),
      ],
    );
  }

  Widget _buildQuickStats(int memberCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Team',
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
          Column(
            children: [
              ...members.asMap().entries.map(
                (entry) => _buildMemberCard(entry.value, entry.key),
              ),
            ],
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
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                label,
                style: AppTheme.navLabel.copyWith(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(borderRadius: AppTheme.radiusLarge),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppTheme.accentPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['email'] ?? 'Unknown', style: AppTheme.cardTitle),
                const SizedBox(height: 4),
                Text("Team Member", style: AppTheme.metaText),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                fontFamily: 'DM Sans',
                color: AppTheme.accentPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
