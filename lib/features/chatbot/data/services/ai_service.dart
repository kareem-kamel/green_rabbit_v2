import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';

class AIException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  AIException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

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

  static Future<Exception> handleDioError(DioException e) async {
    if (e.response != null) {
      final responseData = e.response!.data;
      if (responseData is Map) {
        if (responseData['success'] == false && responseData['error'] != null) {
          final err = responseData['error'];
          return AIException(
            code: err['code']?.toString() ?? 'UNKNOWN_ERROR',
            message: err['message']?.toString() ?? 'An unknown error occurred.',
            details: err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null,
          );
        }
      } else if (responseData is ResponseBody) {
        try {
          final bytes = await responseData.stream.toList();
          final bodyString = utf8.decode(bytes.expand((x) => x).toList());
          final decoded = json.decode(bodyString);
          if (decoded is Map && decoded['success'] == false && decoded['error'] != null) {
            final err = decoded['error'];
            return AIException(
              code: err['code']?.toString() ?? 'UNKNOWN_ERROR',
              message: err['message']?.toString() ?? 'An unknown error occurred.',
              details: err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null,
            );
          }
        } catch (streamErr) {
          print('Error parsing error stream: $streamErr');
        }
      }
    }
    return Exception(e.message ?? 'A network error occurred.');
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
      if (e is DioException) {
        throw await handleDioError(e);
      }
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
        if (data is Map<String, dynamic> && data['success'] == true) {
          final payload = data['data'];
          if (payload is Map<String, dynamic>) {
            return AIUsageStats.fromJson(payload);
          }
        }
      }
      throw Exception('Failed to get usage stats');
    } catch (e) {
      if (e is DioException) {
        throw await handleDioError(e);
      }
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
        if (data is Map<String, dynamic> && data['success'] == true) {
          final payload = data['data'];
          List<dynamic> list = [];
          if (payload is List) {
            list = payload;
          } else if (payload is Map<String, dynamic>) {
            list = payload['conversations'] as List? ?? [];
          }
          return list
              .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw await handleDioError(e);
      }
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
      if (e is DioException) {
        throw await handleDioError(e);
      }
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
        if (data is Map<String, dynamic> && data['success'] == true) {
          final payload = data['data'];
          List<dynamic> list = [];
          if (payload is List) {
            list = payload;
          } else if (payload is Map<String, dynamic>) {
            list = payload['messages'] as List? ?? [];
          }
          return list
              .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw await handleDioError(e);
      }
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
        'messages': messagesJson,
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
      if (e is DioException) {
        throw await handleDioError(e);
      }
      print('Send message error: $e');
      throw Exception('Send message error: $e');
    }
  }

  String? _extractStreamText(dynamic decoded) {
    if (decoded is! Map) return null;

    if (decoded['success'] == false && decoded['error'] != null) {
      final err = decoded['error'];
      if (err is Map) {
        throw AIException(
          code: err['code']?.toString() ?? 'STREAM_ERROR',
          message: err['message']?.toString() ?? 'AI stream error',
        );
      }
    }

    final type = decoded['type']?.toString();
    if (type == 'token' ||
        type == 'delta' ||
        type == 'content' ||
        type == 'message') {
      final text = decoded['content'] ?? decoded['text'] ?? decoded['delta'];
      if (text != null) return text.toString();
    }

    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty && choices.first is Map) {
      final delta = (choices.first as Map)['delta'];
      if (delta is Map && delta['content'] != null) {
        return delta['content'].toString();
      }
    }

    if (decoded['content'] != null) return decoded['content'].toString();
    if (decoded['text'] != null) return decoded['text'].toString();

    final message = decoded['message'];
    if (message is Map && message['content'] != null) {
      return message['content'].toString();
    }

    return null;
  }

  /// Reveals SSE text for the typing effect. On web, pass chunks through to avoid
  /// hundreds of rebuilds per second (can trigger engine window assertions).
  Stream<String> _streamPieces(String text) async* {
    if (text.isEmpty) return;

    if (kIsWeb) {
      yield text;
      return;
    }

    const sliceSize = 5;
    const sliceDelayMs = 1;
    const linePauseMs = 6;

    final lines = text.split('\n');
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      if (line.isNotEmpty) {
        if (line.length <= sliceSize) {
          yield line;
        } else {
          for (var i = 0; i < line.length; i += sliceSize) {
            final end =
                i + sliceSize > line.length ? line.length : i + sliceSize;
            yield line.substring(i, end);
            if (end < line.length) {
              await Future.delayed(
                const Duration(milliseconds: sliceDelayMs),
              );
            }
          }
        }
      }

      if (lineIndex < lines.length - 1) {
        yield '\n';
        await Future.delayed(const Duration(milliseconds: linePauseMs));
      }
    }
  }

  Stream<String> sendMessageStream(
    String conversationId,
    String content, {
    List<ChatMessage> history = const [],
    CancelToken? cancelToken,
  }) async* {
    try {
      final url = '$_conversationsEndpoint/$conversationId/messages?stream=true';
      final messagesJson = history.map((m) => m.toJson()).toList();
      final data = {
        'content': content,
        'messages': messagesJson,
        'metadata': {
          'temperature': 0.7,
          'maxTokens': 1000,
        },
      };

      final response = await _apiClient.dio.post(
        url,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            ..._getHeaders(),
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Chat stream failed with status ${response.statusCode}');
      }

      final ResponseBody body = response.data;
      bool isErrorEvent = false;

      await for (final line in utf8.decoder
          .bind(body.stream)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;

        if (line.startsWith('event: error')) {
          isErrorEvent = true;
          continue;
        }

        if (!line.startsWith('data:')) continue;

        final payload = line.replaceFirst(RegExp(r'^data:\s*'), '').trim();
        if (payload.isEmpty || payload == '[DONE]') return;

        try {
          final decoded = json.decode(payload);

          if (isErrorEvent ||
              (decoded is Map &&
                  decoded.containsKey('code') &&
                  decoded.containsKey('message'))) {
            final code = decoded['code']?.toString() ?? 'STREAM_ERROR';
            final message =
                decoded['message']?.toString() ?? 'Stream error occurred';
            throw AIException(code: code, message: message);
          }

          if (decoded is Map && decoded['type']?.toString() == 'done') {
            return;
          }

          final text = _extractStreamText(decoded);
          if (text != null && text.isNotEmpty) {
            yield* _streamPieces(text);
          }
        } catch (e) {
          if (e is AIException) rethrow;
          // Non-JSON SSE payloads (plain text tokens).
          if (payload.isNotEmpty &&
              !payload.startsWith('{') &&
              payload != '[DONE]') {
            yield* _streamPieces(payload);
          } else {
            print('Error decoding stream line: $e | line=$line');
          }
        } finally {
          isErrorEvent = false;
        }
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      if (e is AIException) rethrow;
      if (e is DioException) {
        throw await handleDioError(e);
      }
      print('Stream error: $e');
      throw Exception('Stream error: $e');
    }
  }
}
