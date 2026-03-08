import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../services/session_service.dart';

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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    loadTeam();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F0F0F),
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0F0F0F),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Decorative accent shapes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    /// TIMER BANNER
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer, color: Colors.grey[300], size: 24),
                          const SizedBox(width: 12),
                          Text(
                            "12h 34m remaining",
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// TEAM INFO
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Team",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              teamId,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              "Team Members",
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),

                            const SizedBox(height: 16),

                            members.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 40,
                                      ),
                                      child: Text(
                                        "No members yet",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// BOTTOM NAVIGATION BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _onNavTapped(index);
          if (index == 1) {
            context.push('/feed');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[500],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: Colors.grey[300], size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['email'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Team Member",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Active",
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
