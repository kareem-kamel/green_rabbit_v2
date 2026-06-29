import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../data/repository/chatbot_repository.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import 'package:green_rabbit/core/errors/failures.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatbotRepository repository;
  CancelToken? _activeCancelToken;
  Timer? _revealTimer;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;

  /// ChatGPT-style typewriter: UI trails the live stream slightly.
  static const _revealTickMs = 18;

  ChatCubit({required this.repository}) : super(const ChatState(
    messages: [],
  )) {
    loadHistory();
    loadUsageStats();
  }

  @override
  Future<void> close() {
    _activeCancelToken?.cancel();
    _revealTimer?.cancel();
    _speech.stop();
    return super.close();
  }

  Future<void> loadHistory() async {
    try {
      final history = await repository.getConversations();
      emit(state.copyWith(history: history));
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> loadUsageStats() async {
    try {
      final stats = await repository.getUsageStats();
      emit(state.copyWith(
        creditsUsed: stats.currentPeriod.tokensUsed,
        totalCredits: stats.currentPeriod.tokensLimit > 0
            ? stats.currentPeriod.tokensLimit
            : 100,
      ));
    } catch (e) {
      print('Error loading usage stats: $e');
    }
  }

  Future<void> selectConversation(String id) async {
    emit(state.copyWith(
      isGenerating: true,
      activeConversationId: id,
      hasMessages: true,
      messages: [],
    ));

    try {
      final messages = await repository.getMessages(id);

      if (state.activeConversationId == id) {
        emit(state.copyWith(
          messages: messages,
          isGenerating: false,
        ));
      }
    } catch (e) {
      if (state.activeConversationId == id) {
        emit(state.copyWith(
          isGenerating: false,
          messages: [
            _errorMessage(
              id,
              _formatError(e),
            ),
          ],
          hasMessages: true,
        ));
      }
      print('Error loading messages: $e');
    }
  }

  void toggleVoiceMode(bool val) {
    if (val) {
      emit(state.copyWith(isVoiceMode: true, clearError: true));
      // Don't auto-start listening here, let the UI trigger it via the large button
    } else {
      stopListening(submit: false);
      emit(state.copyWith(isVoiceMode: false));
    }
  }

  Future<void> startListening() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          emit(state.copyWith(
            error: 'Microphone permission is required for voice input.',
          ));
          return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            emit(state.copyWith(isListening: false));
          }
        },
        onError: (errorNotification) {
          print('STT Error: ${errorNotification.errorMsg}');
          emit(state.copyWith(
            isListening: false,
            error: 'Speech recognition error. Please try again.',
          ));
        },
      );

      _isSpeechInitialized = available;

      if (_isSpeechInitialized) {
        if (_speech.isListening) {
          await _speech.stop();
        }

        emit(state.copyWith(isListening: true, speechText: '', clearError: true));
        
        await _speech.listen(
          onResult: (result) {
            emit(state.copyWith(speechText: result.recognizedWords));
            if (result.finalResult) {
              // Auto-stop listening when speech ends, but stay in Voice Mode
              stopListening(submit: true);
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5), // Increased from 2 to 5 for more time
          partialResults: true,
          listenMode: stt.ListenMode.dictation, // Switched back to dictation for better flow
          cancelOnError: true,
        );
      } else {
        emit(state.copyWith(
          error: 'Speech recognition not available on this device.',
        ));
      }
    } catch (e) {
      print('Speech start error: $e');
      emit(state.copyWith(
        isListening: false,
        error: 'Failed to start microphone.',
      ));
    }
  }

  Future<void> stopListening({bool submit = true}) async {
    final text = state.speechText;
    
    if (_speech.isListening) {
      await _speech.stop();
    }
    
    emit(state.copyWith(
      isListening: false, 
      speechText: '', 
    ));
    
    if (submit && text.trim().isNotEmpty) {
      sendMessage(text.trim());
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void startNewChat() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
    emit(state.copyWith(
      hasMessages: false,
      isVoiceMode: false,
      messages: [],
      isGenerating: false,
      clearActiveConversationId: true,
      selectedImages: [],
    ));
  }

  void addSelectedImage(String imagePath) {
    final updatedImages = List<String>.from(state.selectedImages)..add(imagePath);
    emit(state.copyWith(selectedImages: updatedImages));
  }

  void removeSelectedImage(String imagePath) {
    final updatedImages = List<String>.from(state.selectedImages)..remove(imagePath);
    emit(state.copyWith(selectedImages: updatedImages));
  }

  void clearSelectedImages() {
    emit(state.copyWith(selectedImages: []));
  }

  Future<void> summarize(String entityId, String entityType, {String? url}) async {
    emit(state.copyWith(
      isGenerating: true,
      hasMessages: true,
      messages: [],
      activeConversationId: 'summary',
    ));

    _activeCancelToken?.cancel();
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;
    _cancelRevealTimer();

    final aiMessage = ChatMessage(
      id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: 'summary',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(messages: [aiMessage]));

    var streamTarget = '';
    var streamDisplayed = '';

    try {
      // Start typewriter timer
      _revealTimer = Timer.periodic(const Duration(milliseconds: _revealTickMs), (timer) {
        if (isClosed || cancelToken.isCancelled) {
          timer.cancel();
          return;
        }
        final newDisplayed = _advanceTypewriter(streamDisplayed, streamTarget);
        if (newDisplayed != streamDisplayed) {
          streamDisplayed = newDisplayed;
          _emitStreamingAssistantMessage('summary', streamDisplayed);
        }
      });

      await for (final chunk in repository.summarizeContentStream(
        entityId,
        entityType,
        url: url,
        cancelToken: cancelToken,
      )) {
        if (cancelToken.isCancelled) break;
        streamTarget = _mergeStreamChunk(streamTarget, chunk);
        // Update immediately if there's a lot of backlog
        if (streamTarget.length - streamDisplayed.length > 200) {
          streamDisplayed = _advanceTypewriter(streamDisplayed, streamTarget);
          _emitStreamingAssistantMessage('summary', streamDisplayed);
        }
      }
      
      // Wait for typewriter to catch up
      await _waitForRevealCatchUp(
        conversationId: 'summary',
        target: streamTarget,
        displayed: streamDisplayed,
        isCancelled: () => cancelToken.isCancelled || isClosed,
      );
      _cancelRevealTimer();
      
      // print('[DEBUG] Summarize post-stream: emitting full target len=${streamTarget.length}');
      emit(state.copyWith(isGenerating: false));
    } catch (e) {
      _cancelRevealTimer();
      if (!cancelToken.isCancelled) {
        emit(state.copyWith(
          isGenerating: false,
          messages: [
            _errorMessage(
              'summary',
              _formatError(e),
            ),
          ],
        ));
      }
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      final success = await repository.deleteConversation(id);
      if (success) {
        if (state.activeConversationId == id) {
          startNewChat();
        }
        loadHistory();
      }
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  ChatMessage _errorMessage(String conversationId, String text) {
    return ChatMessage(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'assistant',
      content: text,
      createdAt: DateTime.now(),
    );
  }

  String _formatError(Object e) {
    // Handle specific failure types
    if (e is NoInternetFailure) {
      return e.message;
    }
    
    if (e is ServerFailure) {
      return 'Our server encountered a problem. Please try again later.';
    }
    
    if (e is CacheFailure) {
      return 'There was an issue loading your data. Please try again.';
    }
    
    // Handle AI exceptions - show message from API but sanitize if needed
    if (e is AIException) {
      // Always show AIException messages (they're meant for users)
      final msg = e.message;
      if (msg.toLowerCase().contains('aborted')) {
        return 'The request was stopped. This could be due to poor internet connection or a server issue. Please try again.';
      }
      return msg;
    }
    
    // Handle Dio exceptions
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection issue. Please check your internet and try again.';
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            return 'Authentication issue. Please log in again.';
          } else if (e.response?.statusCode == 429) {
            return 'Too many requests. Please wait a moment and try again.';
          } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
            return 'Our server is having issues. Please try again later.';
          }
          return 'Something went wrong. Please try again.';
        case DioExceptionType.cancel:
          return 'The request was stopped. Please try again if you want to continue.';
        case DioExceptionType.unknown:
        default:
          if (e.message?.toLowerCase().contains('aborted') ?? false) {
            return 'The request was stopped. This could be due to poor internet connection or a server issue. Please try again.';
          }
          return 'Something went wrong. Please try again.';
      }
    }
    
    // Default generic error message (safe and user-friendly)
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.toLowerCase().contains('aborted')) {
      return 'The request was stopped. This could be due to poor internet connection or a server issue. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  bool _isReplyInFlightError(Object e) {
    // Check raw exception instead of formatted error
    String getRawMessage(Object err) {
      if (err is AIException) return err.message.toLowerCase();
      if (err is DioException) {
        if (err.response != null && err.response?.data is Map) {
          final data = err.response?.data as Map;
          final errMsg = data['error']?['message']?.toString().toLowerCase() ?? '';
          if (errMsg.isNotEmpty) return errMsg;
        }
        return err.message?.toLowerCase() ?? '';
      }
      return err.toString().toLowerCase();
    }
    
    final rawMsg = getRawMessage(e);
    return rawMsg.contains('already in flight') ||
         rawMsg.contains('reply_in_flight');
  }

  String _replyInFlightUserMessage() {
    return 'Your last reply was stopped on this device, but the server is '
        'still finishing that request. Wait a few seconds and try again, or '
        'tap New Chat to continue in a fresh thread.';
  }

  /// Backend may send deltas (append) or cumulative content (replace).
  String _mergeStreamChunk(String current, String incoming) {
    print('[DEBUG] _mergeStreamChunk: current len=${current.length}, incoming len=${incoming.length}');
    if (incoming.isEmpty) return current;
    
    String merged;
    if (current.isEmpty) {
      merged = incoming;
    } else if (incoming.length >= current.length && incoming.startsWith(current)) {
      merged = incoming;
    } else {
      merged = current + incoming;
    }

    // Aggressively strip "TL;DR" or "Summary" from the start of the accumulated text
    // We do this every time to catch cases where the prefix is split across multiple chunks
    final result = merged.replaceFirst(
      RegExp(r'^\s*([\*#_~]*)\s*(TL;DR|Summary|TLDR)[:\s\-\*]*([\*#_~]*)\s*', caseSensitive: false), 
      ''
    );
    print('[DEBUG] _mergeStreamChunk: final result len=${result.length}');
    return result;
  }

  void _cancelRevealTimer() {
    _revealTimer?.cancel();
    _revealTimer = null;
  }

  int _revealCharsPerTick(int backlog) {
    if (backlog > 500) return 30;
    if (backlog > 200) return 15;
    if (backlog > 100) return 8;
    if (backlog > 40) return 4;
    return 2;
  }

  String _advanceTypewriter(String displayed, String target) {
    if (displayed.length >= target.length) return displayed;

    final backlog = target.length - displayed.length;
    var take = _revealCharsPerTick(backlog);
    var end = displayed.length + take;
    if (end > target.length) end = target.length;

    // Prefer stopping after a space when we're not catching up fast.
    if (backlog < 48 && end < target.length) {
      final slice = target.substring(displayed.length, end);
      if (!slice.contains(' ') && !slice.contains('\n')) {
        final spaceAfter = target.indexOf(' ', end);
        final newlineAfter = target.indexOf('\n', end);
        var boundary = -1;
        if (spaceAfter != -1) boundary = spaceAfter;
        if (newlineAfter != -1 &&
            (boundary == -1 || newlineAfter < boundary)) {
          boundary = newlineAfter;
        }
        if (boundary != -1 && boundary - displayed.length <= take + 10) {
          end = boundary + 1;
          if (end > target.length) end = target.length;
        }
      }
    }

    return target.substring(0, end);
  }

  Future<void> _waitForRevealCatchUp({
    required String conversationId,
    required String target,
    required String displayed,
    required bool Function() isCancelled,
  }) async {
    var shown = displayed;
    // print('[DEBUG] _waitForRevealCatchUp start: shown len = ${shown.length}, target len = ${target.length}');
    while (shown.length < target.length && !isCancelled()) {
      shown = _advanceTypewriter(shown, target);
      // print('[DEBUG] _waitForRevealCatchUp: updating to shown len = ${shown.length}');
      _emitStreamingAssistantMessage(conversationId, shown);
      await Future.delayed(const Duration(milliseconds: _revealTickMs ~/ 2));
    }
    // print('[DEBUG] _waitForRevealCatchUp end: shown len = ${shown.length}');
  }

  void _emitStreamingAssistantMessage(
    String conversationId,
    String fullContent,
  ) {
    if (isClosed || state.activeConversationId != conversationId) return;
    if (state.messages.isEmpty || state.messages.last.isUser) return;
    // Skip updating if message already has user-stopped suffix
    if (state.messages.last.content.contains('(Response ended by the user)')) {
      return;
    }

    final messages = List<ChatMessage>.from(state.messages);
    messages[messages.length - 1] =
        messages.last.copyWith(content: fullContent);
    emit(state.copyWith(messages: messages, isGenerating: true));
  }

  void _setAssistantError(String conversationId, String text) {
    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty &&
        !messages.last.isUser &&
        messages.last.content.isEmpty) {
      messages.removeLast();
    }
    messages.add(_errorMessage(conversationId, text));
    emit(state.copyWith(messages: messages, isGenerating: false));
  }

  Future<void> sendMessage(String text, {bool skipAddingUserMessage = false}) async {
    if (text.isEmpty && state.selectedImages.isEmpty) return;
    if (state.isGenerating) return;

    List<ChatMessage> updatedMessages;
    if (skipAddingUserMessage) {
      // Skip adding user's message (it's already in the list)
      updatedMessages = List<ChatMessage>.from(state.messages);
    } else {
      // Normal case: add user's message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: state.activeConversationId ?? 'current',
        role: 'user',
        content: text,
        imagePaths: state.selectedImages.isNotEmpty ? List.from(state.selectedImages) : null,
        createdAt: DateTime.now(),
      );

      updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(userMessage);
    }

    emit(state.copyWith(
      hasMessages: true,
      messages: updatedMessages,
      isGenerating: true,
      selectedImages: [], // Clear selected images after sending
    ));

    _activeCancelToken?.cancel();
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;
    _cancelRevealTimer();

    try {
      String conversationId;
      if (state.activeConversationId != null) {
        conversationId = state.activeConversationId!;
      } else {
        final newConv = await repository.createConversation(
          text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
        conversationId = newConv.id;
        emit(state.copyWith(activeConversationId: conversationId));
        loadHistory();
      }

      final aiMessage = ChatMessage(
        id: 'asst_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      );

      final withAiPlaceholder = List<ChatMessage>.from(state.messages)
        ..add(aiMessage);

      emit(state.copyWith(messages: withAiPlaceholder));

      final history = withAiPlaceholder.length >= 2
          ? withAiPlaceholder.sublist(0, withAiPlaceholder.length - 2)
          : <ChatMessage>[];

      var streamTarget = '';
      var streamDisplayed = '';
      const maxAttempts = 4;
      Object? lastError;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (cancelToken.isCancelled) return;

        try {
          streamTarget = '';
          streamDisplayed = '';
          _cancelRevealTimer();

          // Start typewriter timer
          _revealTimer = Timer.periodic(const Duration(milliseconds: _revealTickMs), (timer) {
            if (isClosed || cancelToken.isCancelled) {
              timer.cancel();
              return;
            }
            final newDisplayed = _advanceTypewriter(streamDisplayed, streamTarget);
            if (newDisplayed != streamDisplayed) {
              streamDisplayed = newDisplayed;
              _emitStreamingAssistantMessage(conversationId, streamDisplayed);
            }
          });

          await for (final chunk in repository.sendMessageStream(
                conversationId,
                text,
                history: history,
                cancelToken: cancelToken,
              )) {
                print('[DEBUG] sendMessageStream received chunk: len=${chunk.length}, chunk="${chunk.substring(0, chunk.length > 100 ? 100 : chunk.length)}"');
                if (isClosed || cancelToken.isCancelled) return;
                if (state.activeConversationId != conversationId) return;
                streamTarget = _mergeStreamChunk(streamTarget, chunk);
                // Update immediately if there's a lot of backlog
                if (streamTarget.length - streamDisplayed.length > 200) {
                  streamDisplayed = _advanceTypewriter(streamDisplayed, streamTarget);
                  _emitStreamingAssistantMessage(conversationId, streamDisplayed);
                }
              }
          
          // Wait for typewriter to catch up
          await _waitForRevealCatchUp(
            conversationId: conversationId,
            target: streamTarget,
            displayed: streamDisplayed,
            isCancelled: () => cancelToken.isCancelled || isClosed,
          );
          _cancelRevealTimer();

          // print('[DEBUG] Post-stream: emitting full target len=${streamTarget.length}');
          if (kDebugMode) {
            // print('[CHAT_STREAM] UI final len=${streamTarget.length} chars');
          }
          lastError = null;
          break;
        } catch (e) {
          _cancelRevealTimer();

          if (isClosed || cancelToken.isCancelled) return;
          if (e is DioException && CancelToken.isCancel(e)) return;

          lastError = e;
          if (_isReplyInFlightError(e) && attempt < maxAttempts - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }

      // stopGenerating() already handles emitting final state when user cancels
      if (cancelToken.isCancelled) {
        return;
      }

      if (lastError != null) {
        throw lastError;
      }

      if (streamTarget.trim().isEmpty) {
        _setAssistantError(
          conversationId,
          'No response received from the AI. Please try again.',
        );
      } else {
        emit(state.copyWith(isGenerating: false));
      }

      loadUsageStats();
    } catch (e) {
      if (isClosed) return;
      if (e is DioException && CancelToken.isCancel(e)) {
        emit(state.copyWith(isGenerating: false));
        return;
      }

      print('=== CHATBOT ERROR ===');
      print('Error: $e');

      final message = _isReplyInFlightError(e)
          ? _replyInFlightUserMessage()
          : _formatError(e);

      _setAssistantError(
        state.activeConversationId ?? 'current',
        message,
      );
    } finally {
      _cancelRevealTimer();
      emit(state.copyWith(isGenerating: false));
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  void stopGenerating() {
    _cancelRevealTimer();
    _activeCancelToken?.cancel();
    _activeCancelToken = null;

    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty && !messages.last.isUser) {
      final last = messages.last;
      if (last.content.trim().isEmpty) {
        messages.removeLast();
      } else {
        messages[messages.length - 1] = last.copyWith(
          content: '${last.content.trim()}\n\n*(Response ended by the user)*',
        );
      }
    }

    emit(state.copyWith(isGenerating: false, messages: messages));
  }

  void retryLastMessage() {
    if (state.isGenerating) return;
    
    // Find the last user message in the current list
    final userMessages = state.messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return;
    
    final lastUserMessage = userMessages.last;
    
    // Remove the error message(s) if any from the end
    final updatedMessages = List<ChatMessage>.from(state.messages);
    while (updatedMessages.isNotEmpty && !updatedMessages.last.isUser) {
      updatedMessages.removeLast();
    }
    
    emit(state.copyWith(messages: updatedMessages));
    sendMessage(lastUserMessage.content, skipAddingUserMessage: true);
  }
}
