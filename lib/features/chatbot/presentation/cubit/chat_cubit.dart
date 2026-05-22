import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/chatbot_repository.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatbotRepository repository;
  CancelToken? _activeCancelToken;
  DateTime? _lastStreamEmitAt;
  static const _streamEmitIntervalMs = 48;

  ChatCubit({required this.repository}) : super(const ChatState(
    messages: [],
  )) {
    loadHistory();
    loadUsageStats();
  }

  Future<void> loadHistory() async {
    try {
      final history = await repository.getConversations();
      emit(state.copyWith(history: history));
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> loadUsageStats() async {
    try {
      final stats = await repository.getUsageStats();
      emit(state.copyWith(
        creditsUsed: stats.currentPeriod.tokensUsed,
        totalCredits: stats.currentPeriod.tokensLimit > 0
            ? stats.currentPeriod.tokensLimit
            : 100,
      ));
    } catch (e) {
      print('Error loading usage stats: $e');
    }
  }

  Future<void> selectConversation(String id) async {
    emit(state.copyWith(
      isGenerating: true,
      activeConversationId: id,
      hasMessages: true,
      messages: [],
    ));

    try {
      final messages = await repository.getMessages(id);

      if (state.activeConversationId == id) {
        emit(state.copyWith(
          messages: messages,
          isGenerating: false,
        ));
      }
    } catch (e) {
      if (state.activeConversationId == id) {
        emit(state.copyWith(
          isGenerating: false,
          messages: [
            _errorMessage(
              id,
              _formatError(e),
            ),
          ],
          hasMessages: true,
        ));
      }
      print('Error loading messages: $e');
    }
  }

  void toggleVoiceMode(bool val) => emit(state.copyWith(isVoiceMode: val));

  void startNewChat() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
    emit(state.copyWith(
      hasMessages: false,
      isVoiceMode: false,
      messages: [],
      isGenerating: false,
      clearActiveConversationId: true,
    ));
  }

  Future<void> deleteConversation(String id) async {
    try {
      final success = await repository.deleteConversation(id);
      if (success) {
        if (state.activeConversationId == id) {
          startNewChat();
        }
        loadHistory();
      }
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  ChatMessage _errorMessage(String conversationId, String text) {
    return ChatMessage(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'assistant',
      content: text,
      createdAt: DateTime.now(),
    );
  }

  String _formatError(Object e) {
    if (e is AIException) return e.message;
    return e.toString().replaceAll('Exception: ', '');
  }

  bool _isReplyInFlightError(Object e) {
    final msg = _formatError(e).toLowerCase();
    return msg.contains('already in flight') ||
        msg.contains('reply_in_flight');
  }

  String _replyInFlightUserMessage() {
    return 'Your last reply was stopped on this device, but the server is '
        'still finishing that request. Wait a few seconds and try again, or '
        'tap New Chat to continue in a fresh thread.';
  }

  bool _shouldEmitStreamUpdate() {
    final now = DateTime.now();
    if (_lastStreamEmitAt == null ||
        now.difference(_lastStreamEmitAt!).inMilliseconds >=
            _streamEmitIntervalMs) {
      _lastStreamEmitAt = now;
      return true;
    }
    return false;
  }

  void _emitStreamingAssistantMessage(
    String conversationId,
    String fullContent,
  ) {
    if (isClosed || state.activeConversationId != conversationId) return;
    if (state.messages.isEmpty || state.messages.last.isUser) return;

    final messages = List<ChatMessage>.from(state.messages);
    messages[messages.length - 1] =
        messages.last.copyWith(content: fullContent);
    emit(state.copyWith(messages: messages, isGenerating: true));
  }

  void _setAssistantError(String conversationId, String text) {
    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty &&
        !messages.last.isUser &&
        messages.last.content.isEmpty) {
      messages.removeLast();
    }
    messages.add(_errorMessage(conversationId, text));
    emit(state.copyWith(messages: messages, isGenerating: false));
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty || state.isGenerating) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: state.activeConversationId ?? 'current',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage);

    emit(state.copyWith(
      hasMessages: true,
      messages: updatedMessages,
      isGenerating: true,
    ));

    _activeCancelToken?.cancel();
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;

    try {
      String conversationId;
      if (state.activeConversationId != null) {
        conversationId = state.activeConversationId!;
      } else {
        final newConv = await repository.createConversation(
          text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
        conversationId = newConv.id;
        emit(state.copyWith(activeConversationId: conversationId));
        loadHistory();
      }

      final aiMessage = ChatMessage(
        id: 'asst_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      );

      final withAiPlaceholder = List<ChatMessage>.from(state.messages)
        ..add(aiMessage);

      emit(state.copyWith(messages: withAiPlaceholder));

      final history = withAiPlaceholder.length >= 2
          ? withAiPlaceholder.sublist(0, withAiPlaceholder.length - 2)
          : <ChatMessage>[];

      String fullContent = '';
      const maxAttempts = 4;
      Object? lastError;
      _lastStreamEmitAt = null;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (cancelToken.isCancelled) return;

        try {
          fullContent = '';
          await for (final chunk in repository.sendMessageStream(
            conversationId,
            text,
            history: history,
            cancelToken: cancelToken,
          )) {
            if (isClosed || cancelToken.isCancelled) return;

            if (state.activeConversationId != conversationId) {
              return;
            }

            fullContent += chunk;

            if (_shouldEmitStreamUpdate()) {
              _emitStreamingAssistantMessage(conversationId, fullContent);
            }
          }
          _lastStreamEmitAt = null;
          if (fullContent.isNotEmpty) {
            _emitStreamingAssistantMessage(conversationId, fullContent);
          }
          lastError = null;
          break;
        } catch (e) {
          if (isClosed || cancelToken.isCancelled) return;
          if (e is DioException && CancelToken.isCancel(e)) return;

          lastError = e;
          if (_isReplyInFlightError(e) && attempt < maxAttempts - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }

      if (cancelToken.isCancelled) {
        emit(state.copyWith(isGenerating: false));
        return;
      }

      if (lastError != null) {
        throw lastError!;
      }

      if (fullContent.trim().isEmpty) {
        _setAssistantError(
          conversationId,
          'No response received from the AI. Please try again.',
        );
      } else {
        emit(state.copyWith(isGenerating: false));
      }

      loadUsageStats();
    } catch (e) {
      if (isClosed) return;
      if (e is DioException && CancelToken.isCancel(e)) {
        emit(state.copyWith(isGenerating: false));
        return;
      }

      print('=== CHATBOT ERROR ===');
      print('Error: $e');

      final message = _isReplyInFlightError(e)
          ? _replyInFlightUserMessage()
          : _formatError(e);

      _setAssistantError(
        state.activeConversationId ?? 'current',
        message,
      );
    } finally {
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  void stopGenerating() {
    _lastStreamEmitAt = null;
    _activeCancelToken?.cancel();
    _activeCancelToken = null;

    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && !messages.last.isUser) {
      final last = messages.last;
      if (last.content.trim().isEmpty) {
        messages.removeLast();
      } else {
        messages[messages.length - 1] = last.copyWith(
          content: '${last.content.trim()}\n\n*(Response stopped)*',
        );
      }
    }

    emit(state.copyWith(isGenerating: false, messages: messages));
  }
}
