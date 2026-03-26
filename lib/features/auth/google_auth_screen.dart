import 'dart:async';

import 'package:codenyx/core/theme/app_theme.dart';
import 'package:codenyx/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({super.key});

  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends State<GoogleAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<AuthState>? _authSubscription;
  bool _handledSignIn = false;

  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
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

    // CRITICAL: Check if we already have a session (happens after OAuth redirect)
    _checkForExistingSession();

    // Setup listener for auth events
    _setupAuthListener();

    _animationController.forward();
  }

  /// Check if there's already a session (from OAuth redirect)
  void _checkForExistingSession() {
    print('🔍 Checking for existing session...');
    final session = Supabase.instance.client.auth.currentSession;
    final email = session?.user.email;

    print('   Session exists: ${session != null}');
    print('   User email: $email');

    if (email != null && !_handledSignIn) {
      print('✅ Found existing session after OAuth!');
      _processSignIn(email);
    }
  }

  /// Setup auth state change listener
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      print('🔥 AUTH EVENT: ${data.event}');
      print('   User: ${data.session?.user.email}');

      // Only process signedIn events
      if (data.event == AuthChangeEvent.signedIn) {
        final email = data.session?.user.email;
        if (email != null && !_handledSignIn) {
          print('📧 Auth state changed to signedIn');
          _processSignIn(email);
        }
      }
    });
  }

  /// Process sign-in: find team, save session, navigate
  Future<void> _processSignIn(String email) async {
    if (_handledSignIn) {
      print('⏭️ Already processing sign-in, skipping');
      return;
    }

    _handledSignIn = true;
    print('🔄 Processing sign-in for: $email');

    try {
      // Find the user's team
      final teamId = await AuthRepository.findUserTeam(email);

      if (!mounted) {
        print('⚠️ Widget not mounted, aborting');
        return;
      }

      if (teamId == null) {
        print('❌ No team found for email');
        setState(() {
          loading = false;
          errorMessage = 'Email not found in any team. Contact organizers.';
        });
        _showErrorSnackBar(errorMessage!);
        _handledSignIn = false;
        return;
      }

      print('✅ Team found: $teamId');

      // Save session to local storage
      await SessionService.saveSession(email, teamId);
      print('✅ Session saved');

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = null;
      });

      // Add small delay to ensure everything is settled
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        print('⚠️ Widget not mounted after delay, aborting navigation');
        return;
      }

      print('🚀 Navigating to /dashboard');
      // Use replace to avoid back button issues
      context.go('/dashboard');
    } catch (e) {
      print('❌ Error during sign-in: $e');
      _handledSignIn = false;

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Sign-in failed: ${e.toString()}';
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    print('🔘 Sign in button tapped');

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      _handledSignIn = false;
      print('🌐 Initiating Google OAuth...');
      await AuthRepository.signInWithGoogle();
      print('⏳ Waiting for OAuth redirect...');
    } catch (e) {
      print('❌ OAuth error: $e');

      if (!mounted) return;

      final errorMsg = 'Sign-in failed: ${e.toString()}';
      setState(() {
        loading = false;
        errorMessage = errorMsg;
      });
      _showErrorSnackBar(errorMsg);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingXL,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppTheme.spacingXL),

                      // Illustration/Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.security_outlined,
                          size: 50,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL * 1.5),

                      // Header Section
                      const Text(
                        "Welcome to CodeNyx",
                        style: AppTheme.pageTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        "Sign in with your Google account registered with the hackathon",
                        style: AppTheme.cardBody.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingXL * 2),

                      // Error Message Display
                      if (errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingL,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red, width: 1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Google Sign-In Button
                      _buildGoogleSignInButton(),
                      const SizedBox(height: AppTheme.spacingXL * 1.5),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        decoration: AppTheme.cardDecoration(
                          borderRadius: AppTheme.radiusLarge,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: AppTheme.accentPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "How it works",
                                    style: AppTheme.cardTitle.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    "Sign in with the Google account you used to register for the hackathon. We'll automatically find your team.",
                                    style: AppTheme.cardBody.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL * 2),

                      // Security Footer
                      Text(
                        "Your data is secure. We only use your email to find your team.",
                        style: AppTheme.metaText.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : signInWithGoogle,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
              alignment: Alignment.center,
              child: loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        const Text(
                          "Signing in...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: AppTheme.accentPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
