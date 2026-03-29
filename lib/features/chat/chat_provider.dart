import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_repository.dart';
import 'message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return const ChatRepository();
});

final teamMessagesControllerProvider =
    Provider.autoDispose.family<TeamMessagesController, String>((ref, teamId) {
      final repository = ref.watch(chatRepositoryProvider);
      final controller = TeamMessagesController(
        repository: repository,
        teamId: teamId,
      );

      ref.onDispose(controller.dispose);
      return controller;
    });

final teamMessagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, teamId) {
      final controller = ref.watch(teamMessagesControllerProvider(teamId));
      return controller.stream;
    });

class TeamMessagesController {
  TeamMessagesController({
    required ChatRepository repository,
    required this.teamId,
  }) : _repository = repository {
    _bootstrap();
  }

  final ChatRepository _repository;
  final String teamId;
  final _streamController = StreamController<List<MessageModel>>.broadcast();
  final _knownMessageIds = <String>{};
  final _messages = <MessageModel>[];
  StreamSubscription<MessageModel>? _realtimeSubscription;

  Stream<List<MessageModel>> get stream => _streamController.stream;

  Future<void> _bootstrap() async {
    try {
      final initialMessages = await _repository.fetchMessages(teamId);
      _messages
        ..clear()
        ..addAll(initialMessages);
      _knownMessageIds
        ..clear()
        ..addAll(initialMessages.map((message) => message.id));

      _emit();

      _realtimeSubscription = _repository
          .subscribeToMessages(teamId)
          .listen(_insertMessage, onError: _streamController.addError);
    } catch (error, stackTrace) {
      _streamController.addError(error, stackTrace);
    }
  }

  void insertConfirmed(MessageModel message) {
    _insertMessage(message);
  }

  void _insertMessage(MessageModel message) {
    if (_knownMessageIds.contains(message.id)) {
      return;
    }

    _knownMessageIds.add(message.id);
    _messages.add(message);
    _messages.sort(_repository.compareMessages);

    if (_messages.length > 50) {
      final removed = _messages.removeAt(0);
      _knownMessageIds.remove(removed.id);
    }

    _emit();
  }

  void _emit() {
    if (_streamController.isClosed) {
      return;
    }

    _streamController.add(List<MessageModel>.unmodifiable(_messages));
  }

  Future<void> dispose() async {
    await _realtimeSubscription?.cancel();
    await _streamController.close();
  }
}
