import 'package:equatable/equatable.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final List<Conversation> history;
  final String? activeConversationId;
  final bool isVoiceMode;
  final bool hasMessages;
  final bool isGenerating;
  final int creditsUsed;
  final int totalCredits;
  final bool isListening;
  final String speechText;

  const ChatState({
    this.messages = const [],
    this.history = const [],
    this.activeConversationId,
    this.isVoiceMode = false,
    this.hasMessages = false,
    this.isGenerating = false,
    this.creditsUsed = 5,
    this.totalCredits = 5,
    this.isListening = false,
    this.speechText = '',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<Conversation>? history,
    String? activeConversationId,
    bool? isVoiceMode,
    bool? hasMessages,
    bool? isGenerating,
    int? creditsUsed,
    int? totalCredits,
    bool? isListening,
    String? speechText,
    bool clearActiveConversationId = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      activeConversationId: clearActiveConversationId ? null : (activeConversationId ?? this.activeConversationId),
      isVoiceMode: isVoiceMode ?? this.isVoiceMode,
      hasMessages: hasMessages ?? this.hasMessages,
      isGenerating: isGenerating ?? this.isGenerating,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      totalCredits: totalCredits ?? this.totalCredits,
      isListening: isListening ?? this.isListening,
      speechText: speechText ?? this.speechText,
    );
  }

  @override
  List<Object?> get props => [messages, history, activeConversationId, isVoiceMode, hasMessages, isGenerating, creditsUsed, totalCredits, isListening, speechText];
}