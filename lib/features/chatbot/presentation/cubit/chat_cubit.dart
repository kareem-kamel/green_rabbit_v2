import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/chatbot_repository.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatbotRepository repository;

  ChatCubit({required this.repository}) : super(ChatState(
    history: const [
      ChatHistory(title: "Intel Stock", isActive: true),
      ChatHistory(title: "Apple go vi"),
      ChatHistory(title: "Nividia Up"),
    ],
    messages: const [
      ChatMessage(content: "Hello there! How may I assist you today?", role: 'assistant', id: '0', conversationId: '0', createdAt: null),
    ]
  ));

  void toggleVoiceMode(bool val) => emit(state.copyWith(isVoiceMode: val));

  void startNewChat() {
    emit(state.copyWith(hasMessages: false, isVoiceMode: false, messages: []));
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: 'current',
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
      List<Conversation> conversations = await repository.getConversations();
      String conversationId;
      
      if (conversations.isNotEmpty) {
        conversationId = conversations.first.id;
      } else {
        // 2. Create one if not
        final newConv = await repository.createConversation("New Chat");
        conversationId = newConv.id;
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
      print('Starting to process stream from repository...');
      await for (final chunk in repository.sendMessageStream(conversationId, text)) {
        if (isClosed) {
          print('Cubit closed while streaming, stopping.');
          return;
        }
        
        print('Cubit received chunk: "$chunk"');
        fullContent += chunk;
        
        final lastMsg = state.messages.last.copyWith(content: fullContent);
        final updatedStreamMessages = List<ChatMessage>.from(state.messages)
          ..[state.messages.length - 1] = lastMsg;
        
        emit(state.copyWith(messages: updatedStreamMessages, isGenerating: true));
      }
      
      print('Stream processing complete. Full response length: ${fullContent.length}');
      emit(state.copyWith(isGenerating: false));
    } catch (e) {
      if (isClosed) return;
      
      // Add error message to chat for visibility
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: 'current',
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