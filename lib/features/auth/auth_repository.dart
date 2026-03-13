import '../../services/supabase_service.dart';

class AuthRepository {
  /// Verify if user email exists in the team
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

  /// Get all team members for a team
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

  /// Get team info
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

  /// Mark user as joined
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
}
