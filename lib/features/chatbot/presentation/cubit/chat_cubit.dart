import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/chatbot_repository.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatbotRepository repository;

  ChatCubit({required this.repository}) : super(const ChatState(
    messages: []
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
    // Clear current messages immediately to avoid "merging" UI flashes
    emit(state.copyWith(
      isGenerating: true, 
      activeConversationId: id, 
      hasMessages: true,
      messages: [], // Clear old messages
    ));
    
    try {
      final messages = await repository.getMessages(id);
      
      // Only update if the user hasn't switched to another chat while loading
      if (state.activeConversationId == id) {
        emit(state.copyWith(
          messages: messages,
          isGenerating: false,
        ));
      }
    } catch (e) {
      if (state.activeConversationId == id) {
        emit(state.copyWith(isGenerating: false));
      }
      print('Error loading messages: $e');
    }
  }

  void toggleVoiceMode(bool val) => emit(state.copyWith(isVoiceMode: val));

  void startNewChat() {
    emit(state.copyWith(
      hasMessages: false, 
      isVoiceMode: false, 
      messages: [],
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

      // Pass the previous messages as history to provide context to the AI
      // We exclude the current user message (last message in withAiPlaceholder is the AI placeholder, 
      // the one before that is the current user message)
      final history = withAiPlaceholder.length >= 2 
          ? withAiPlaceholder.sublist(0, withAiPlaceholder.length - 2) 
          : <ChatMessage>[];

      String fullContent = '';
      await for (final chunk in repository.sendMessageStream(conversationId, text, history: history)) {
        if (isClosed) return;
        
        // CRITICAL: Only update state if the user is still in the SAME conversation
        // This prevents messages from "bleeding" into other chats if the user switches quickly.
        if (state.activeConversationId != conversationId) {
          print('User switched conversation, stopping stream update for $conversationId');
          return;
        }
        
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

  // This is a placeholder for non-streaming messages if needed
  Future<void> sendMessageNonStreaming(String text) async {
    if (text.isEmpty) return;
    // ... logic for non-streaming if ever needed
  }

  void stopGenerating() => emit(state.copyWith(isGenerating: false));
}