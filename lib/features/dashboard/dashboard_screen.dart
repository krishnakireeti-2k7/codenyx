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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    loadTeam();
    _setupAnimations();
    _pageController = PageController(initialPage: 0);

    _pageController.addListener(() {
      setState(() {
        _selectedIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),

          // PageView for smooth navigation
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [_buildDashboardPage(), const FeedScreen()],
          ),

          /// BOTTOM NAVIGATION BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: AppTheme.navBarDecoration(),
              padding: EdgeInsets.only(
                left: AppTheme.spacingL,
                right: AppTheme.spacingL,
                top: AppTheme.spacingM,
                bottom:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacingM,
              ),
              child: Container(
                decoration: AppTheme.cardDecoration(
                  borderRadius: AppTheme.radiusLarge,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarItem(
                      icon: Icons.home_filled,
                      label: "Dashboard",
                      index: 0,
                    ),
                    _buildNavBarItem(
                      icon: Icons.feed,
                      label: "Social Feed",
                      index: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Stack(
      children: [
        // Main content
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Hackathon name header
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingL,
                      right: AppTheme.spacingL,
                      top: AppTheme.spacingM,
                      bottom: AppTheme.spacingL,
                    ),
                    child: Row(
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
                  ),

                  /// TIMER BANNER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingL,
                      ),
                      decoration: AppTheme.bannerDecoration(isTimer: true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: AppTheme.accentPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          const Text(
                            "12h 34m remaining",
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  /// TEAM INFO
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Your Team", style: AppTheme.pageTitle),

                          const SizedBox(height: AppTheme.spacingM),

                          Text(teamId, style: AppTheme.cardBody),

                          const SizedBox(height: AppTheme.spacingXXL),

                          const Text(
                            "TEAM MEMBERS",
                            style: AppTheme.sectionHeader,
                          ),

                          const SizedBox(height: AppTheme.spacingL),

                          members.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Text(
                                      "No members yet",
                                      style: AppTheme.cardBody,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ...members.asMap().entries.map(
                                      (entry) => _buildMemberCard(
                                        entry.value,
                                        entry.key,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 100), // Space for nav bar
                        ],
                      ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.accentPrimary.withOpacity(0.2),
                      AppTheme.accentSecondary.withOpacity(0.15),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.navLabel.copyWith(
                  color: isSelected
                      ? AppTheme.accentPrimary
                      : AppTheme.textSecondary,
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
      decoration: AppTheme.cardDecoration(),
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
