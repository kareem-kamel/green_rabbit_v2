import 'package:equatable/equatable.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';

class ChatHistory {
  final String title;
  final bool isActive;

  const ChatHistory({required this.title, this.isActive = false});

  @override
  String toString() => 'ChatHistory(title: $title, isActive: $isActive)';
}

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final List<ChatHistory> history;
  final bool isVoiceMode;
  final bool hasMessages;
  final bool isGenerating;
  final int creditsUsed;
  final int totalCredits;

  const ChatState({
    this.messages = const [],
    this.history = const [],
    this.isVoiceMode = false,
    this.hasMessages = false,
    this.isGenerating = false,
    this.creditsUsed = 5,
    this.totalCredits = 5,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatHistory>? history,
    bool? isVoiceMode,
    bool? hasMessages,
    bool? isGenerating,
    int? creditsUsed,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isVoiceMode: isVoiceMode ?? this.isVoiceMode,
      hasMessages: hasMessages ?? this.hasMessages,
      isGenerating: isGenerating ?? this.isGenerating,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      totalCredits: totalCredits,
    );
  }

  @override
  List<Object?> get props => [messages, history, isVoiceMode, hasMessages, isGenerating, creditsUsed];
}