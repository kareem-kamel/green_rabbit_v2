import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      messageCount: json['messageCount'] is int ? json['messageCount'] as int : 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, title, messageCount, createdAt, updatedAt];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final List<String>? imagePaths;
  final int? tokensUsed;
  final int? tokensIn;
  final int? tokensOut;
  final String? status;
  final String? finishReason;
  final ChatFeedback? feedback;
  final DateTime? createdAt;
  final bool hasChart;

  bool get isUser => role == 'user';

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.imagePaths,
    this.tokensUsed,
    this.tokensIn,
    this.tokensOut,
    this.status,
    this.finishReason,
    this.feedback,
    this.createdAt,
    this.hasChart = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      imagePaths: json['imagePaths'] != null
          ? (json['imagePaths'] as List<dynamic>).map((e) => e.toString()).toList()
          : (json['imagePath'] != null ? [json['imagePath'].toString()] : null),
      tokensUsed: json['tokensUsed'] is int ? json['tokensUsed'] as int : null,
      tokensIn: json['tokensIn'] is int ? json['tokensIn'] as int : null,
      tokensOut: json['tokensOut'] is int ? json['tokensOut'] as int : null,
      status: json['status']?.toString(),
      finishReason: json['finishReason']?.toString(),
      feedback: json['feedback'] != null ? ChatFeedback.fromJson(json['feedback'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      hasChart: json['hasChart'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        imagePaths,
        tokensUsed,
        tokensIn,
        tokensOut,
        status,
        finishReason,
        feedback,
        createdAt,
        hasChart
      ];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'role': role,
      'content': content,
    };
    if (imagePaths != null) {
      map['imagePaths'] = imagePaths;
    }
    return map;
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    List<String>? imagePaths,
    int? tokensUsed,
    int? tokensIn,
    int? tokensOut,
    String? status,
    String? finishReason,
    ChatFeedback? feedback,
    DateTime? createdAt,
    bool? hasChart,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      status: status ?? this.status,
      finishReason: finishReason ?? this.finishReason,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      hasChart: hasChart ?? this.hasChart,
    );
  }
}

class ChatFeedback extends Equatable {
  final String rating;
  final DateTime? submittedAt;

  const ChatFeedback({
    required this.rating,
    this.submittedAt,
  });

  factory ChatFeedback.fromJson(Map<String, dynamic> json) {
    return ChatFeedback(
      rating: json['rating']?.toString() ?? '',
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [rating, submittedAt];
}

class AISummary extends Equatable {
  final String id;
  final String type;
  final String targetId;
  final String summary;
  final String sourceTitle;
  final int tokensUsed;
  final DateTime? generatedAt;

  const AISummary({
    required this.id,
    required this.type,
    required this.targetId,
    required this.summary,
    required this.sourceTitle,
    required this.tokensUsed,
    this.generatedAt,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    return AISummary(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      sourceTitle: json['sourceTitle']?.toString() ?? '',
      tokensUsed: _asInt(json['tokensUsed'], fallback: 0),
      generatedAt: json['generatedAt'] != null ? DateTime.tryParse(json['generatedAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, type, targetId, summary, sourceTitle, tokensUsed, generatedAt];
}

class AIUsageStats extends Equatable {
  final AIUsagePeriod currentPeriod;
  final AIUsageRequests requests;
  final String tier;
  final DateTime? resetAt;

  const AIUsageStats({
    required this.currentPeriod,
    required this.requests,
    required this.tier,
    this.resetAt,
  });

  factory AIUsageStats.fromJson(Map<String, dynamic> json) {
    final periodJson = json['currentPeriod'] ?? json['current_period'];
    final requestsJson = json['requests'];

    return AIUsageStats(
      currentPeriod: periodJson is Map<String, dynamic>
          ? AIUsagePeriod.fromJson(periodJson)
          : const AIUsagePeriod(
              startDate: '',
              endDate: '',
              tokensUsed: 0,
              tokensLimit: 100,
              tokensRemaining: 100,
            ),
      requests: requestsJson is Map<String, dynamic>
          ? AIUsageRequests.fromJson(requestsJson)
          : const AIUsageRequests(
              summarizations: 0,
              chatMessages: 0,
              totalRequests: 0,
            ),
      tier: json['tier']?.toString() ?? 'free',
      resetAt: json['resetAt'] != null
          ? DateTime.tryParse(json['resetAt'].toString())
          : (json['reset_at'] != null
              ? DateTime.tryParse(json['reset_at'].toString())
              : null),
    );
  }

  @override
  List<Object?> get props => [currentPeriod, requests, tier, resetAt];
}

class AIUsagePeriod extends Equatable {
  final String startDate;
  final String endDate;
  final int tokensUsed;
  final int tokensLimit;
  final int tokensRemaining;

  const AIUsagePeriod({
    required this.startDate,
    required this.endDate,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.tokensRemaining,
  });

  factory AIUsagePeriod.fromJson(Map<String, dynamic> json) {
    return AIUsagePeriod(
      startDate: (json['startDate'] ?? json['start_date'])?.toString() ?? '',
      endDate: (json['endDate'] ?? json['end_date'])?.toString() ?? '',
      tokensUsed: _asInt(json['tokensUsed'] ?? json['tokens_used']),
      tokensLimit: _asInt(json['tokensLimit'] ?? json['tokens_limit'], fallback: 100),
      tokensRemaining: _asInt(json['tokensRemaining'] ?? json['tokens_remaining']),
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, tokensUsed, tokensLimit, tokensRemaining];
}

class AIUsageRequests extends Equatable {
  final int summarizations;
  final int chatMessages;
  final int totalRequests;

  const AIUsageRequests({
    required this.summarizations,
    required this.chatMessages,
    required this.totalRequests,
  });

  factory AIUsageRequests.fromJson(Map<String, dynamic> json) {
    return AIUsageRequests(
      summarizations: _asInt(json['summarizations']),
      chatMessages: _asInt(json['chatMessages'] ?? json['chat_messages']),
      totalRequests: _asInt(json['totalRequests'] ?? json['total_requests']),
    );
  }

  @override
  List<Object?> get props => [summarizations, chatMessages, totalRequests];
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
