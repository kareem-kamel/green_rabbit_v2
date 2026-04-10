import 'dart:math';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatbotRepository {
  final AIService _aiService;

  ChatbotRepository(this._aiService);

  Future<ChatMessage> fetchAIResponse(String userPrompt) async {
    final aiText = await _aiService.getAIResponse(userPrompt);

    return ChatMessage(
      id: Random().nextInt(10000).toString(),
      text: aiText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}