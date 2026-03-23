import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class AuthRepository {
  /// Sign in with Google via Supabase OAuth
  /// Returns the authenticated user's email, or null if sign-in fails
  static Future<String?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google Sign-In...');

      // Trigger Google OAuth flow
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.codenyx://login-callback/',
      );

      // Get the authenticated user
      final user = SupabaseService.client.auth.currentUser;

      if (user != null && user.email != null) {
        print('✅ Google Sign-In successful. Email: ${user.email}');
        return user.email!;
      } else {
        print('❌ No user or email after Google sign-in');
        return null;
      }
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Find which team the user belongs to using their email
  /// Returns team_id if found, null otherwise
  static Future<String?> findUserTeam(String email) async {
    try {
      print('🔍 Finding team for email: $email');

      final response = await SupabaseService.client
          .from('team_members')
          .select('team_id')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (response != null) {
        final teamId = response['team_id'] as String;
        print('✅ Team found: $teamId');

        // Mark user as joined
        await SupabaseService.client
            .from('team_members')
            .update({'joined': true})
            .eq('team_id', teamId)
            .eq('email', email.toLowerCase());

        print('✅ User marked as joined');
        return teamId;
      } else {
        print('❌ No team found for email: $email');
        return null;
      }
    } catch (e) {
      print('❌ Error finding team: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    try {
      print('👋 Signing out...');
      await SupabaseService.client.auth.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  /// Get current authenticated user email
  static String? getCurrentUserEmail() {
    return SupabaseService.client.auth.currentUser?.email;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return SupabaseService.client.auth.currentUser != null;
  }

  /// Get team members (unchanged from original)
  static Future<List<Map<String, dynamic>>> getTeamMembers(
    String teamId,
  ) async {
    try {
      print('📋 Fetching team members for: $teamId');

      final response = await SupabaseService.client
          .from('team_members')
          .select()
          .eq('team_id', teamId)
          .order('name', ascending: true);

      print('✅ Team members fetched: ${response.length} members');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  /// Get team info (unchanged from original)
  static Future<Map<String, dynamic>?> getTeamInfo(String teamId) async {
    try {
      print('🏢 Fetching team info for: $teamId');

      final response = await SupabaseService.client
          .from('teams')
          .select()
          .eq('team_id', teamId)
          .maybeSingle();

      print('✅ Team info fetched: $response');
      return response;
    } catch (e) {
      print('Error fetching team info: $e');
      return null;
    }
  }

  /// Mark user as joined (unchanged from original)
  static Future<bool> markUserAsJoined(String teamId, String email) async {
    try {
      await SupabaseService.client
          .from('team_members')
          .update({'joined': true})
          .eq('team_id', teamId)
          .eq('email', email.toLowerCase());

      return true;
    } catch (e) {
      print('Error marking user as joined: $e');
      return false;
    }
  }

  /// Verify team member (deprecated - kept for reference)
  /// Use signInWithGoogle() + findUserTeam() instead
  @deprecated
  static Future<bool> verifyTeamMember({
    required String email,
    required String teamId,
  }) async {
    try {
      print('🔍 Verifying: Email=$email, TeamID=$teamId');

      // Check if team exists
      final teamResponse = await SupabaseService.client
          .from('teams')
          .select()
          .eq('team_id', teamId)
          .maybeSingle();

      print('Team found: $teamResponse');

      if (teamResponse == null) {
        print('❌ Team not found: $teamId');
        return false;
      }

      // Check if email exists in team_members for this team
      final memberResponse = await SupabaseService.client
          .from('team_members')
          .select()
          .eq('team_id', teamId)
          .eq('email', email.toLowerCase())
          .maybeSingle();

      print('Member found: $memberResponse');

      if (memberResponse == null) {
        print('❌ Email not found in team: $email');
        return false;
      }

      // Update joined status to true
      await SupabaseService.client
          .from('team_members')
          .update({'joined': true})
          .eq('team_id', teamId)
          .eq('email', email.toLowerCase());

      print('✅ User verified and joined set to true');
      return true;
    } catch (e) {
      print('Error verifying team member: $e');
      return false;
    }
  }
}
