import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(ChatState(
    history: const [
      ChatHistory(title: "Intel Stock", isActive: true),
      ChatHistory(title: "Apple go vi"),
      ChatHistory(title: "Nividia Up"),
    ],
    messages: const [
      ChatMessage(text: "Hello there! How may I assist you today?", isUser: false),
    ]
  ));

  void toggleVoiceMode(bool val) => emit(state.copyWith(isVoiceMode: val));

  void startNewChat() {
    emit(state.copyWith(hasMessages: false, isVoiceMode: false, messages: []));
  }

  void sendMessage(String text) {
    if (text.isEmpty) return;

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(ChatMessage(text: text, isUser: true));

    emit(state.copyWith(
      hasMessages: true,
      messages: updatedMessages,
      isGenerating: true,
      creditsUsed: (state.creditsUsed + 1).clamp(0, state.totalCredits),
    ));

    // Fake AI Response delay
    Future.delayed(const Duration(seconds: 2), () {
      if (isClosed) return;
      
      final aiMessages = List<ChatMessage>.from(state.messages)
        ..add(const ChatMessage(
          text: "I'm here to help! What else would you like to explore?",
          isUser: false,
        ));
      
      emit(state.copyWith(isGenerating: false, messages: aiMessages));
    });
  }

  void stopGenerating() => emit(state.copyWith(isGenerating: false));
}