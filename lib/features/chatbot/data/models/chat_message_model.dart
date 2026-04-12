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
  final int? tokensUsed;
  final ChatFeedback? feedback;
  final DateTime? createdAt;
  final bool hasChart;

  bool get isUser => role == 'user';

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.tokensUsed,
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
      tokensUsed: json['tokensUsed'] is int ? json['tokensUsed'] as int : null,
      feedback: json['feedback'] != null ? ChatFeedback.fromJson(json['feedback'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      hasChart: json['hasChart'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, role, content, tokensUsed, feedback, createdAt, hasChart];

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    int? tokensUsed,
    ChatFeedback? feedback,
    DateTime? createdAt,
    bool? hasChart,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokensUsed: tokensUsed ?? this.tokensUsed,
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
      tokensUsed: json['tokensUsed'] is int ? json['tokensUsed'] as int : 0,
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
    return AIUsageStats(
      currentPeriod: AIUsagePeriod.fromJson(json['currentPeriod'] as Map<String, dynamic>),
      requests: AIUsageRequests.fromJson(json['requests'] as Map<String, dynamic>),
      tier: json['tier']?.toString() ?? 'free',
      resetAt: json['resetAt'] != null ? DateTime.tryParse(json['resetAt'].toString()) : null,
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
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      tokensUsed: json['tokensUsed'] is int ? json['tokensUsed'] as int : 0,
      tokensLimit: json['tokensLimit'] is int ? json['tokensLimit'] as int : 0,
      tokensRemaining: json['tokensRemaining'] is int ? json['tokensRemaining'] as int : 0,
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
      summarizations: json['summarizations'] is int ? json['summarizations'] as int : 0,
      chatMessages: json['chatMessages'] is int ? json['chatMessages'] as int : 0,
      totalRequests: json['totalRequests'] is int ? json['totalRequests'] as int : 0,
    );
  }

  @override
  List<Object?> get props => [summarizations, chatMessages, totalRequests];
}
