import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatbotRepository {
  final AIService _aiService;

  ChatbotRepository(this._aiService);

  // Summarize content
  Future<AISummary> summarizeContent(String targetId, String type) {
    return _aiService.summarizeContent(targetId, type);
  }

  // Get AI usage statistics
  Future<AIUsageStats> getUsageStats() {
    return _aiService.getUsageStats();
  }

  // Conversations
  Future<List<Conversation>> getConversations() {
    return _aiService.listConversations();
  }

  Future<Conversation> createConversation(String title) {
    return _aiService.createConversation(title);
  }

  Future<bool> deleteConversation(String id) {
    return _aiService.deleteConversation(id);
  }

  // Messages
  Future<List<ChatMessage>> getMessages(String conversationId) {
    return _aiService.getConversationMessages(conversationId);
  }

  Future<ChatMessage> sendMessage(String conversationId, String content, {List<ChatMessage> history = const []}) {
    return _aiService.sendMessage(conversationId, content, history: history);
  }

  Stream<String> sendMessageStream(String conversationId, String content, {List<ChatMessage> history = const []}) {
    return _aiService.sendMessageStream(conversationId, content, history: history);
  }
}
