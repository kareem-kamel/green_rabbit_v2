import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';

class AIService {
  String get _baseUrl => dotenv.get('BASE_URL');
  String get _summarizeEndpoint => dotenv.get('AI_SUMMARIZE_ENDPOINT');
  String get _usageEndpoint => dotenv.get('AI_USAGE_ENDPOINT');
  String get _conversationsEndpoint => dotenv.get('AI_CHAT_CONVERSATIONS_ENDPOINT');
  
  String get _token => dotenv.get('API_TOKEN');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
    'X-Pinggy-No-Screen': 'true',
    'X-Idempotency-Key': _generateUuid(),
  };

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
      final response = await http.post(
        Uri.parse('$_baseUrl$_summarizeEndpoint'),
        headers: _headers,
        body: json.encode({
          'targetId': targetId,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final response = await http.get(
        Uri.parse('$_baseUrl$_usageEndpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final response = await http.get(
        Uri.parse('$_baseUrl$_conversationsEndpoint'),
        headers: _headers,
      );

      print('List Conversations URL: ${Uri.parse('$_baseUrl$_conversationsEndpoint')}');
      print('List Conversations Status: ${response.statusCode}');
      print('List Conversations Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final body = {'title': title};
      final response = await http.post(
        Uri.parse('$_baseUrl$_conversationsEndpoint'),
        headers: _headers,
        body: json.encode(body),
      );

      print('Create Conversation URL: ${Uri.parse('$_baseUrl$_conversationsEndpoint')}');
      print('Create Conversation Body: ${json.encode(body)}');
      print('Create Conversation Status: ${response.statusCode}');
      print('Create Conversation Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return Conversation.fromJson(data['data'] as Map<String, dynamic>);
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
      final response = await http.delete(
        Uri.parse('$_baseUrl$_conversationsEndpoint/$id'),
        headers: _headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- Messages ---
  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    try {
      final url = '$_baseUrl$_conversationsEndpoint/$conversationId/messages';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('Get Messages URL: $url');
      print('Get Messages Status: ${response.statusCode}');
      print('Get Messages Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      final url = '$_baseUrl$_conversationsEndpoint/$conversationId/messages';
      final body = {'content': content, 'stream': false};
      
      print('Send Message URL: $url');
      print('Send Message Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(body),
      );

      print('Send Message Status: ${response.statusCode}');
      print('Send Message Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['message'] != null) {
          final messageData = data['data']['message'] as Map<String, dynamic>;
          // Inject the conversationId into the message data since it's needed by the model
          messageData['conversationId'] = conversationId;
          return ChatMessage.fromJson(messageData);
        }
      }
      
      print('API Error [${response.statusCode}]: ${response.body}');
      throw Exception('Failed to send message: ${response.statusCode}');
    } catch (e) {
      print('Send message error: $e');
      throw Exception('Send message error: $e');
    }
  }

  Stream<String> sendMessageStream(String conversationId, String content) async* {
    try {
      final url = '$_baseUrl$_conversationsEndpoint/$conversationId/messages?stream=true';
      final body = {
        'content': content,
        'metadata': {
          'temperature': 0.7,
          'maxTokens': 1000,
        }
      };
      
      print('--- STREAMING REQUEST START ---');
      print('URL: $url');
      print('Headers: $_headers');
      print('Body: ${json.encode(body)}');
      print('-------------------------------');

      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(_headers);
      request.body = json.encode(body);

      final client = http.Client();
      final response = await client.send(request);

      print('Stream Response Status: ${response.statusCode}');
      print('Stream Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Stream connected successfully, listening for chunks...');
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          print('--- RAW CHUNK START ---');
          print('Chunk: "$chunk"');
          print('-----------------------');
          
          final lines = chunk.split('\n');
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isEmpty) continue;
            
            print('Processing line: "$trimmedLine"');
            
            try {
              // 1. Handle "data: {...}" format
              if (trimmedLine.startsWith('data:')) {
                final cleanedLine = trimmedLine.replaceFirst('data:', '').trim();
                if (cleanedLine == '[DONE]') {
                  print('Stream received [DONE] signal');
                  return;
                }
                
                final decoded = json.decode(cleanedLine);
                final text = decoded['data']?['message']?['content'] ?? 
                             decoded['message']?['content'] ?? 
                             decoded['content'] ?? '';
                
                print('Parsed from SSE data: "$text"');
                if (text.isNotEmpty) yield text;
              } 
              // 2. Handle raw JSON line without "data:" prefix
              else if (trimmedLine.startsWith('{')) {
                final decoded = json.decode(trimmedLine);
                final text = decoded['data']?['message']?['content'] ?? 
                             decoded['message']?['content'] ?? 
                             decoded['content'] ?? '';
                
                print('Parsed from raw JSON line: "$text"');
                if (text.isNotEmpty) yield text;
              }
              // 3. Handle raw text (not JSON)
              else {
                print('Yielding as raw text line: "$trimmedLine"');
                yield trimmedLine;
              }
            } catch (e) {
              print('Error parsing line: $trimmedLine - Error: $e');
              yield trimmedLine;
            }
          }
        }
        print('Stream closed by server.');
      } else {
        print('Stream connection failed with status: ${response.statusCode}');
        yield "Error: ${response.statusCode}";
      }
    } catch (e) {
      print('Critical Streaming Error: $e');
      yield "Connection Error: $e";
    }
  }
}
