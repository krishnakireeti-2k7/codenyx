import '../../services/supabase_service.dart';

class AuthRepository {
  Future<bool> verifyTeamMember({
    required String email,
    required String teamId,
  }) async {
    final response = await SupabaseService.client
        .from('team_members')
        .select()
        .eq('email', email)
        .eq('team_id', teamId)
        .maybeSingle();

    return response != null;
  }
}
