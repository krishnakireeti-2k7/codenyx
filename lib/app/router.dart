import 'package:go_router/go_router.dart';
import '../features/auth/team_join_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../services/session_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final loggedIn = await SessionService.isLoggedIn();

    if (!loggedIn) {
      return '/';
    }

    if (loggedIn && state.uri.path == '/') {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TeamJoinScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // FeedScreen is now part of DashboardScreen via PageView
    // No separate /feed route needed
  ],
);
