import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import 'package:green_rabbit/core/errors/failures.dart';
import 'dart:io';
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
    if (e.error is AppFailure) {
      return e.error as AppFailure;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.error is SocketException ||
        (e.message?.contains('SocketException') ?? false) ||
        (e.error?.toString().contains('SocketException') ?? false)) {
      return const NoInternetFailure();
    }
    if (e.response != null) {
      final responseData = e.response!.data;
      
      // Handle Map response (already decoded)
      if (responseData is Map) {
        final err = responseData['error'] ?? (responseData['success'] == false ? responseData : null);
        if (err != null && err is Map) {
          return AIException(
            code: err['code']?.toString() ?? 'UNKNOWN_ERROR',
            message: err['message']?.toString() ?? 'An unknown error occurred.',
            details: err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null,
          );
        }
      } 
      // Handle String response (raw JSON from sse_post_stream or elsewhere)
      else if (responseData is String && responseData.isNotEmpty) {
        try {
          final decoded = json.decode(responseData);
          if (decoded is Map) {
            final err = decoded['error'] ?? (decoded['success'] == false ? decoded : null);
            if (err != null && err is Map) {
              return AIException(
                code: err['code']?.toString() ?? 'UNKNOWN_ERROR',
                message: err['message']?.toString() ?? 'An unknown error occurred.',
                details: err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null,
              );
            }
          }
        } catch (_) {}
      }
      // Handle ResponseBody (stream)
      else if (responseData is ResponseBody) {
        try {
          final bytes = await responseData.stream.toList();
          final bodyString = utf8.decode(bytes.expand((x) => x).toList());
          print('DEBUG: AI API Error Body: $bodyString'); // Added debug print
          final decoded = json.decode(bodyString);
          if (decoded is Map) {
            final err = decoded['error'] ?? (decoded['success'] == false ? decoded : null);
            if (err != null && err is Map) {
              return AIException(
                code: err['code']?.toString() ?? 'UNKNOWN_ERROR',
                message: err['message']?.toString() ?? 'An unknown error occurred.',
                details: err['details'] is Map ? Map<String, dynamic>.from(err['details']) : null,
              );
            }
          }
        } catch (e) {
          print('DEBUG: Error parsing AI error body: $e');
        }
      }
    }
    
    // If we reach here, we couldn't parse a structured error from the body.
    // Try to see if the message itself is useful (we set it in sse_post_stream).
    final msg = e.message ?? '';
    if (msg.contains('failed (') && msg.contains(') for')) {
       return Exception(msg);
    }
    
    return Exception(msg.isNotEmpty ? msg : 'A network error occurred.');
  }

  // --- Summarization ---
  Future<AISummary> summarizeContent(String targetId, String type, {String? url}) async {
    try {
      final response = await _apiClient.dio.post(
        _summarizeEndpoint,
        options: Options(headers: _getHeaders()),
        data: {
          'targetId': targetId,
          'type': type,
          if (url != null && url.isNotEmpty) 'url': url,
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

  Stream<String> summarizeContentStream(
    String targetId,
    String type, {
    String? url,
    CancelToken? cancelToken,
  }) async* {
    try {
      final path = '$_summarizeEndpoint?stream=true';
      final data = {
        'targetId': targetId,
        'type': type,
        if (url != null && url.isNotEmpty) 'url': url,
      };

      final lineStream = openSsePostLineStream(
        resolveToken: _apiClient.resolveAuthToken,
        baseUrl: _apiClient.dio.options.baseUrl,
        path: path,
        body: data,
        extraHeaders: _getHeaders(),
        cancelToken: cancelToken,
        dioPostStream: (p, d, c, h) => _apiClient.dio.post(
          p,
          data: d,
          cancelToken: c,
          options: Options(
            headers: h,
            responseType: ResponseType.stream,
          ),
        ),
      );

      String eventType = 'message';
      await for (final line in lineStream) {
        if (line.isEmpty) {
          eventType = 'message';
          continue;
        }

        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          final payload = line.substring(5).trim();
          yield* _parseSsePayload(payload, eventType);
          eventType = 'message';
          continue;
        }

        // If the line is not empty and doesn't start with SSE prefixes,
        // it might be a raw JSON object or raw text chunk.
        yield* _parseSsePayload(line, eventType);
        eventType = 'message';
      }
    } catch (e) {
      if (e is DioException) {
        throw await handleDioError(e);
      }
      rethrow;
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

  Future<ChatMessage> sendMessage(String conversationId, String content, {List<ChatMessage> history = const [], String? imagePath}) async {
    try {
      final url = '$_conversationsEndpoint/$conversationId/messages';
      final messagesJson = history.map((m) => m.toJson()).toList();
      dynamic data;
      
      if (imagePath != null && imagePath.isNotEmpty) {
        data = FormData.fromMap({
          'content': content,
          'messages': jsonEncode(messagesJson),
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: 'image.${imagePath.split('.').last}',
          ),
        });
      } else {
        data = {
          'content': content,
          'messages': messagesJson,
        };
      }
      
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
    final result = type == 'done' ||
        type == 'end' ||
        type == 'complete' ||
        type == 'finished';
    debugPrint('[DEBUG _isStreamDoneEvent] decoded=$decoded, type=$type → result=$result');
    return result;
  }

  String? _extractStreamText(dynamic decoded) {
    debugPrint('[DEBUG _extractStreamText] ENTER decoded=$decoded, type=${decoded.runtimeType}');
    if (decoded == null) {
      debugPrint('[DEBUG _extractStreamText] EXIT (decoded == null');
      return null;
    }
    if (decoded is String) {
      debugPrint('[DEBUG _extractStreamText] EXIT (is String=$decoded');
      return decoded.isEmpty ? null : decoded;
    }
    if (decoded is! Map) {
      debugPrint('[DEBUG _extractStreamText] EXIT (not Map or String');
      return null;
    }

    final map = Map<String, dynamic>.from(decoded);
    debugPrint('[DEBUG _extractStreamText] map keys=${map.keys}');

    if (map['success'] == false && map['error'] != null) {
      debugPrint('[DEBUG _extractStreamText] Found error map');
      final err = map['error'];
      if (err is Map) {
        throw AIException(
          code: err['code']?.toString() ?? 'STREAM_ERROR',
          message: err['message']?.toString() ?? 'AI stream error',
        );
      }
    }

    if (_isStreamDoneEvent(map)) {
      debugPrint('[DEBUG _extractStreamText] EXIT (_isStreamDoneEvent returned true');
      return null;
    }

    if (map['success'] == true && map['data'] != null) {
      debugPrint('[DEBUG _extractStreamText] Checking success: true, checking data');
      final nested = _extractStreamText(map['data']);
      if (nested != null) return nested;
    }

    // Check for any possible text content regardless of the event type!
    final piece = map['content'] ??
        map['text'] ??
        map['delta'] ??
        map['token'] ??
        map['value'] ??
        map['chunk'] ??
        map['partial'] ??
        map['output'] ??
        map['message'] ??
        map['response'];
    debugPrint('[DEBUG _extractStreamText] Checking for piece: $piece');
    if (piece != null && piece is! Map && piece is! List) {
      return piece.toString();
    }
    if (piece is Map) {
      final nestedPiece = _extractStreamText(piece);
      if (nestedPiece != null) return nestedPiece;
    }

    final type = map['type']?.toString().toLowerCase();
    debugPrint('[DEBUG _extractStreamText] type=$type');
    if (type != null &&
        type != 'done' &&
        type != 'end' &&
        type != 'error' &&
        type != 'message_start' &&
        type != 'start') {
      // Already checked piece above
    }

    debugPrint('[DEBUG _extractStreamText] Checking choices');
    final choices = map['choices'];
    if (choices is List && choices.isNotEmpty && choices.first is Map) {
      final choice = Map<String, dynamic>.from(choices.first as Map);
      final delta = choice['delta'];
      if (delta is Map && delta['content'] != null) {
        debugPrint('[DEBUG _extractStreamText] FOUND choice delta content found');
        return delta['content'].toString();
      }
      if (choice['text'] != null) {
        debugPrint('[DEBUG _extractStreamText] FOUND choice text');
        return choice['text'].toString();
      }
    }

    if (map['content'] != null && map['content'] is! Map && map['content'] is! List) {
      debugPrint('[DEBUG _extractStreamText] FOUND map.content');
      return map['content'].toString();
    }
    if (map['text'] != null && map['text'] is! Map && map['text'] is! List) {
      debugPrint('[DEBUG _extractStreamText] FOUND map.text');
      return map['text'].toString();
    }
    if (map['summary'] != null && map['summary'] is! Map && map['summary'] is! List) {
      debugPrint('[DEBUG _extractStreamText] FOUND map.summary');
      return map['summary'].toString();
    }
    if (map['result'] != null && map['result'] is! Map && map['result'] is! List) {
      debugPrint('[DEBUG _extractStreamText] FOUND map.result');
      return map['result'].toString();
    }

    debugPrint('[DEBUG _extractStreamText] Checking message');
    final message = map['message'];
    if (message is Map) {
      final nested = _extractStreamText(message);
      if (nested != null) return nested;
    }

    debugPrint('[DEBUG _extractStreamText] Checking assistant_message');
    final assistant = map['assistant_message'] ?? map['assistantMessage'];
    if (assistant is Map) {
      final nested = _extractStreamText(assistant);
      if (nested != null) return nested;
    }

    debugPrint('[DEBUG _extractStreamText] EXIT with null');
    return null;
  }

  /// Pass through API tokens; [ChatCubit] applies ChatGPT-style typewriter pacing.
  Stream<String> _streamPieces(String text) async* {
    if (text.isEmpty) return;
    yield text;
  }

  Stream<String> _parseSsePayload(String payload, String eventType) async* {
    final trimmed = payload.trim();
    debugPrint('[DEBUG _parseSsePayload] payload="$trimmed", eventType="$eventType"');
    if (trimmed.isEmpty || trimmed == '[DONE]') return;

    if (eventType == 'error') {
      debugPrint('[DEBUG _parseSsePayload] Got error event');
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
      debugPrint('[DEBUG _parseSsePayload] decoded JSON=$decoded');
      if (decoded is Map) {
        if (decoded.containsKey('code') &&
            decoded.containsKey('message') &&
            decoded['success'] != true) {
          throw AIException(
            code: decoded['code']?.toString() ?? 'STREAM_ERROR',
            message: decoded['message']?.toString() ?? 'Stream error',
          );
        }
        if (_isStreamDoneEvent(decoded)) {
          debugPrint('[DEBUG _parseSsePayload] Got stream done event');
          return;
        }
        final text = _extractStreamText(decoded);
        debugPrint('[DEBUG _parseSsePayload] _extractStreamText returned="$text"');
        if (text != null && text.isNotEmpty) {
          yield* _streamPieces(text);
        }
        return;
      }
    } catch (e) {
      debugPrint('[DEBUG _parseSsePayload] Error parsing JSON: $e');
      if (e is AIException) rethrow;
    }

    debugPrint('[DEBUG _parseSsePayload] Yielding raw trimmed text="$trimmed"');
    yield* _streamPieces(trimmed);
  }

  Stream<String> sendMessageStream(
    String conversationId,
    String content, {
    List<ChatMessage> history = const [],
    String? imagePath,
    CancelToken? cancelToken,
  }) async* {
    try {
      final path =
          '$_conversationsEndpoint/$conversationId/messages?stream=true';
      final messagesJson = history.map((m) => m.toJson()).toList();
      FormData? formData;
      Map<String, dynamic>? jsonData;
      
      if (imagePath != null && imagePath.isNotEmpty) {
        // Create multipart form data with image
        formData = FormData.fromMap({
          'content': content,
          'messages': jsonEncode(messagesJson),
          'metadata': jsonEncode({
            'temperature': 0.7,
            'maxTokens': 1000,
          }),
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: 'image.${imagePath.split('.').last}',
          ),
        });
      } else {
        // Regular JSON data
        jsonData = {
          'content': content,
          'messages': messagesJson,
          'metadata': {
            'temperature': 0.7,
            'maxTokens': 1000,
          },
        };
      }

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
        body: formData ?? jsonData,
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
