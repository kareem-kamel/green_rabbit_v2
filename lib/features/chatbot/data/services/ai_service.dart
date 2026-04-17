import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';

class AIService {
  final ApiClient _apiClient;

  AIService(this._apiClient);

  String get _summarizeEndpoint => AppConstants.aiSummarizeEndpoint;
  String get _usageEndpoint => AppConstants.aiUsageEndpoint;
  String get _conversationsEndpoint => AppConstants.aiChatConversationsEndpoint;
  
  Map<String, String> _getHeaders() {
    return {
      'X-Idempotency-Key': _generateUuid(),
    };
  }

  String _generateUuid() {
    final random = Random();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 10
    
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-${hex.sublist(10).join()}';
  }

  // --- Summarization ---
  Future<AISummary> summarizeContent(String targetId, String type) async {
    try {
      final response = await _apiClient.dio.post(
        _summarizeEndpoint,
        options: Options(headers: _getHeaders()),
        data: {
          'targetId': targetId,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return AISummary.fromJson(data['data']);
        }
      }
      throw Exception('Failed to summarize content');
    } catch (e) {
      throw Exception('Summarization error: $e');
    }
  }

  // --- Usage Statistics ---
  Future<AIUsageStats> getUsageStats() async {
    try {
      final response = await _apiClient.dio.get(
        _usageEndpoint,
        options: Options(headers: _getHeaders()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return AIUsageStats.fromJson(data['data']);
        }
      }
      throw Exception('Failed to get usage stats');
    } catch (e) {
      throw Exception('Usage stats error: $e');
    }
  }

  // --- Conversations ---
  Future<List<Conversation>> listConversations() async {
    try {
      final response = await _apiClient.dio.get(
        _conversationsEndpoint,
        options: Options(headers: _getHeaders()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          return list.map((item) => Conversation.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('List conversations error: $e');
      throw Exception('List conversations error: $e');
    }
  }

  Future<Conversation> createConversation(String title) async {
    try {
      final data = {'title': title};
      final response = await _apiClient.dio.post(
        _conversationsEndpoint,
        options: Options(headers: _getHeaders()),
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['data'] != null) {
          return Conversation.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to create conversation');
    } catch (e) {
      print('Create conversation error: $e');
      throw Exception('Create conversation error: $e');
    }
  }

  Future<bool> deleteConversation(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '$_conversationsEndpoint/$id',
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- Messages ---
  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    try {
      final url = '$_conversationsEndpoint/$conversationId/messages';
      final response = await _apiClient.dio.get(
        url,
        options: Options(headers: _getHeaders()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get messages error: $e');
      throw Exception('Get messages error: $e');
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String content, {List<ChatMessage> history = const []}) async {
    try {
      final url = '$_conversationsEndpoint/$conversationId/messages';
      final messagesJson = history.map((m) => m.toJson()).toList();
      final data = {
        'content': content,
        'messages': messagesJson, // The backend likely expects history in 'messages'
      };
      
      final response = await _apiClient.dio.post(
        url,
        options: Options(headers: _getHeaders()),
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['data'] != null && responseData['data']['message'] != null) {
          final messageData = responseData['data']['message'] as Map<String, dynamic>;
          messageData['conversationId'] = conversationId;
          return ChatMessage.fromJson(messageData);
        }
      }
      throw Exception('Failed to send message');
    } catch (e) {
      print('Send message error: $e');
      throw Exception('Send message error: $e');
    }
  }

  Stream<String> sendMessageStream(String conversationId, String content, {List<ChatMessage> history = const []}) async* {
    try {
      final url = '$_conversationsEndpoint/$conversationId/messages?stream=true';
      final messagesJson = history.map((m) => m.toJson()).toList();
      final data = {
        'content': content,
        'messages': messagesJson,
        'metadata': {
          'temperature': 0.7,
          'maxTokens': 1000,
        }
      };
      
      final response = await _apiClient.dio.post(
        url,
        data: data,
        options: Options(
          headers: _getHeaders(),
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final ResponseBody stream = response.data;
        await for (final chunk in utf8.decoder.bind(stream.stream)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isEmpty) continue;
            
            try {
              if (trimmedLine.startsWith('data:')) {
                final cleanedLine = trimmedLine.replaceFirst('data:', '').trim();
                if (cleanedLine == '[DONE]') return;
                
                final decoded = json.decode(cleanedLine);
                final type = decoded['type']?.toString();
                
                if (type == 'token') {
                  final text = decoded['content']?.toString() ?? '';
                  if (text.isNotEmpty) {
                    // Split by spaces but keep the spaces in the list
                    final words = text.split(RegExp(r'(?<=\s)|(?=\s)'));
                    for (final word in words) {
                      yield word;
                      // Extremely fast delay for that "active typing" feel without being slow
                      await Future.delayed(const Duration(milliseconds: 1));
                    }
                  }
                } else if (type == 'done') {
                  return; 
                }
              }
            } catch (e) {
              print('Error decoding stream line: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Stream error: $e');
      throw Exception('Stream error: $e');
    }
  }
}
