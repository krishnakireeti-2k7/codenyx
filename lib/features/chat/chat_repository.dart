import 'dart:async';

import 'package:codenyx/services/session_service.dart';
import 'package:codenyx/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'message_model.dart';

class ChatRepository {
  const ChatRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<List<MessageModel>> fetchMessages(String teamId, {int limit = 50}) async {
    final response = await _client
        .from('team_messages')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = response
        .map<MessageModel>(
          (rawMessage) => MessageModel.fromMap(
            Map<String, dynamic>.from(rawMessage),
          ),
        )
        .toList();

    messages.sort(_compareMessages);
    return messages;
  }

  Future<MessageModel> sendMessage(String teamId, String message) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found.');
    }

    final userName = await _resolveUserName(teamId, currentUser);

    final response = await _client
        .from('team_messages')
        .insert({
          'team_id': teamId,
          'user_id': currentUser.id,
          'user_name': userName,
          'message': message.trim(),
        })
        .select()
        .single();

    return MessageModel.fromMap(response);
  }

  Stream<MessageModel> subscribeToMessages(String teamId) {
    final controller = StreamController<MessageModel>.broadcast();

    final channel = _client.channel('team_messages:$teamId');

    print("🚀 Subscribing to team: $teamId");

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'team_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'team_id',
            value: teamId,
          ),
          callback: (payload) {
            print("🔥 NEW MESSAGE: ${payload.newRecord}");

            try {
              final message = MessageModel.fromMap(
                Map<String, dynamic>.from(payload.newRecord),
              );
              controller.add(message);
            } catch (e) {
              print("❌ Parse error: $e");
            }
          },
        )
        .subscribe((status, [error]) {
          print("📡 Realtime status: $status");

          if (error != null) {
            print("❌ Realtime error: $error");
            controller.addError(error);
          }
        });

    controller.onCancel = () async {
      print("🛑 Closing realtime channel for team: $teamId");
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  int compareMessages(MessageModel a, MessageModel b) => _compareMessages(a, b);

  Future<String> _resolveUserName(String teamId, User currentUser) async {
    final session = await SessionService.getSession();
    final email = (currentUser.email ?? session['email'] ?? '').toString().trim();

    final metadataName = currentUser.userMetadata?['full_name']?.toString() ??
        currentUser.userMetadata?['name']?.toString();
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    if (email.isNotEmpty) {
      final member = await _client
          .from('team_members')
          .select('name')
          .eq('team_id', teamId)
          .eq('email', email.toLowerCase())
          .maybeSingle();

      final memberName = member?['name']?.toString();
      if (memberName != null && memberName.trim().isNotEmpty) {
        return memberName.trim();
      }

      return email.split('@').first;
    }

    return 'Participant';
  }

  static int _compareMessages(MessageModel a, MessageModel b) {
    final timestampComparison = a.createdAt.compareTo(b.createdAt);
    if (timestampComparison != 0) {
      return timestampComparison;
    }

    final aId = int.tryParse(a.id);
    final bId = int.tryParse(b.id);
    if (aId != null && bId != null) {
      return aId.compareTo(bId);
    }

    return a.id.compareTo(b.id);
  }
}
