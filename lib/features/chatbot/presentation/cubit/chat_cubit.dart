import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/chatbot_repository.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatbotRepository repository;

  ChatCubit({required this.repository}) : super(const ChatState(
    messages: [
      ChatMessage(content: "Hello there! How may I assist you today?", role: 'assistant', id: '0', conversationId: '0', createdAt: null),
    ]
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
        totalCredits: stats.currentPeriod.tokensLimit,
      ));
    } catch (e) {
      print('Error loading usage stats: $e');
    }
  }

  Future<void> selectConversation(String id) async {
    emit(state.copyWith(isGenerating: true, activeConversationId: id, hasMessages: true));
    try {
      final messages = await repository.getMessages(id);
      emit(state.copyWith(
        messages: messages.isEmpty 
          ? [const ChatMessage(content: "Hello there! How may I assist you today?", role: 'assistant', id: '0', conversationId: '0', createdAt: null)]
          : messages,
        isGenerating: false,
      ));
    } catch (e) {
      emit(state.copyWith(isGenerating: false));
      print('Error loading messages: $e');
    }
  }

  void toggleVoiceMode(bool val) => emit(state.copyWith(isVoiceMode: val));

  void startNewChat() {
    emit(state.copyWith(
      hasMessages: false, 
      isVoiceMode: false, 
      messages: [const ChatMessage(content: "Hello there! How may I assist you today?", role: 'assistant', id: '0', conversationId: '0', createdAt: null)],
      activeConversationId: null,
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

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
      creditsUsed: (state.creditsUsed + 1).clamp(0, state.totalCredits),
    ));

    try {
      // 1. Check if we have an active conversation
      String conversationId;
      if (state.activeConversationId != null) {
        conversationId = state.activeConversationId!;
      } else {
        // 2. Create one if not
        final newConv = await repository.createConversation(text.length > 30 ? "${text.substring(0, 30)}..." : text);
        conversationId = newConv.id;
        emit(state.copyWith(activeConversationId: conversationId));
        // Refresh history to show the new conversation in sidebar
        loadHistory();
      }

      // 3. Send message (Streaming)
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

      String fullContent = '';
      await for (final chunk in repository.sendMessageStream(conversationId, text)) {
        if (isClosed) return;
        
        fullContent += chunk;
        
        final lastMsg = state.messages.last.copyWith(content: fullContent);
        final updatedStreamMessages = List<ChatMessage>.from(state.messages)
          ..[state.messages.length - 1] = lastMsg;
        
        emit(state.copyWith(messages: updatedStreamMessages, isGenerating: true));
      }
      
      emit(state.copyWith(isGenerating: false));
      loadUsageStats();
    } catch (e) {
      if (isClosed) return;
      
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: state.activeConversationId ?? 'current',
        role: 'assistant',
        content: "Sorry, I'm having trouble connecting to the AI. Please check your network and try again.",
        createdAt: DateTime.now(),
      );

      final aiMessages = List<ChatMessage>.from(state.messages)
        ..add(errorMsg);

      emit(state.copyWith(isGenerating: false, messages: aiMessages));
    }
  }

  void stopGenerating() => emit(state.copyWith(isGenerating: false));
}