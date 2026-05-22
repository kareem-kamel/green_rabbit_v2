import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import 'package:green_rabbit/core/network/sse_post_stream.dart';
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

  bool _isStreamDoneEvent(Map decoded) {
    final type = decoded['type']?.toString().toLowerCase();
    return type == 'done' ||
        type == 'end' ||
        type == 'complete' ||
        type == 'finished';
  }

  String? _extractStreamText(dynamic decoded) {
    if (decoded == null) return null;
    if (decoded is String) return decoded.isEmpty ? null : decoded;
    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);

    if (map['success'] == false && map['error'] != null) {
      final err = map['error'];
      if (err is Map) {
        throw AIException(
          code: err['code']?.toString() ?? 'STREAM_ERROR',
          message: err['message']?.toString() ?? 'AI stream error',
        );
      }
    }

    if (_isStreamDoneEvent(map)) return null;

    if (map['success'] == true && map['data'] != null) {
      final nested = _extractStreamText(map['data']);
      if (nested != null) return nested;
    }

    final type = map['type']?.toString().toLowerCase();
    if (type != null &&
        type != 'done' &&
        type != 'end' &&
        type != 'error' &&
        type != 'message_start' &&
        type != 'start') {
      final piece = map['content'] ??
          map['text'] ??
          map['delta'] ??
          map['token'] ??
          map['value'] ??
          map['chunk'];
      if (piece != null && piece is! Map && piece is! List) {
        return piece.toString();
      }
      if (piece is Map) {
        return _extractStreamText(piece);
      }
    }

    final choices = map['choices'];
    if (choices is List && choices.isNotEmpty && choices.first is Map) {
      final choice = Map<String, dynamic>.from(choices.first as Map);
      final delta = choice['delta'];
      if (delta is Map && delta['content'] != null) {
        return delta['content'].toString();
      }
      if (choice['text'] != null) return choice['text'].toString();
    }

    if (map['content'] != null && map['content'] is! Map && map['content'] is! List) {
      return map['content'].toString();
    }
    if (map['text'] != null) return map['text'].toString();

    final message = map['message'];
    if (message is Map) {
      final nested = _extractStreamText(message);
      if (nested != null) return nested;
    }

    final assistant = map['assistant_message'] ?? map['assistantMessage'];
    if (assistant is Map) {
      final nested = _extractStreamText(assistant);
      if (nested != null) return nested;
    }

    return null;
  }

  /// Pass through API tokens; [ChatCubit] applies ChatGPT-style typewriter pacing.
  Stream<String> _streamPieces(String text) async* {
    if (text.isEmpty) return;
    yield text;
  }

  Stream<String> _parseSsePayload(String payload, String eventType) async* {
    final trimmed = payload.trim();
    if (trimmed.isEmpty || trimmed == '[DONE]') return;

    if (eventType == 'error') {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is Map) {
          final code = decoded['code']?.toString() ?? 'STREAM_ERROR';
          final message =
              decoded['message']?.toString() ?? 'Stream error occurred';
          throw AIException(code: code, message: message);
        }
      } catch (e) {
        if (e is AIException) rethrow;
      }
      throw AIException(code: 'STREAM_ERROR', message: trimmed);
    }

    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map) {
        if (decoded.containsKey('code') &&
            decoded.containsKey('message') &&
            decoded['success'] != true) {
          throw AIException(
            code: decoded['code']?.toString() ?? 'STREAM_ERROR',
            message: decoded['message']?.toString() ?? 'Stream error',
          );
        }
        if (_isStreamDoneEvent(decoded)) return;
        final text = _extractStreamText(decoded);
        if (text != null && text.isNotEmpty) {
          yield* _streamPieces(text);
        }
        return;
      }
    } catch (e) {
      if (e is AIException) rethrow;
    }

    yield* _streamPieces(trimmed);
  }

  Stream<String> sendMessageStream(
    String conversationId,
    String content, {
    List<ChatMessage> history = const [],
    CancelToken? cancelToken,
  }) async* {
    try {
      final path =
          '$_conversationsEndpoint/$conversationId/messages?stream=true';
      final messagesJson = history.map((m) => m.toJson()).toList();
      final data = {
        'content': content,
        'messages': messagesJson,
        'metadata': {
          'temperature': 0.7,
          'maxTokens': 1000,
        },
      };

      final sseHeaders = {
        ..._getHeaders(),
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      };

      var eventType = '';
      var tokenEvents = 0;

      final lineStream = openSsePostLineStream(
        resolveToken: _apiClient.resolveAuthToken,
        baseUrl: AppConstants.apiBaseUrl,
        path: path,
        body: data,
        extraHeaders: sseHeaders,
        cancelToken: cancelToken,
        dioPostStream: (p, d, token, headers) => _apiClient.postStreamResponse(
          p,
          data: d,
          cancelToken: token,
          headers: headers,
        ),
      );

      await for (final line in lineStream) {
        if (line.isEmpty) {
          eventType = '';
          continue;
        }

        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          final payload = line.replaceFirst(RegExp(r'^data:\s*'), '');
          await for (final piece in _parseSsePayload(payload, eventType)) {
            tokenEvents++;
            yield piece;
          }
          continue;
        }

        if (line.startsWith('{')) {
          await for (final piece in _parseSsePayload(line, eventType)) {
            tokenEvents++;
            yield piece;
          }
        }
      }

      if (kDebugMode) {
        print('[CHAT_STREAM] parsed token events=$tokenEvents (platform=${kIsWeb ? 'web' : 'io'})');
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
