class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final NotificationMetadata data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: NotificationMetadata.fromJson(json['data'] as Map<String, dynamic>),
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data.toJson(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NotificationMetadata {
  final String? alertId;
  final String? instrumentId;
  final String? instrumentSymbol;
  final String? type;
  final String? deepLink;

  NotificationMetadata({
    this.alertId,
    this.instrumentId,
    this.instrumentSymbol,
    this.type,
    this.deepLink,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      alertId: json['alertId'] as String?,
      instrumentId: json['instrumentId'] as String?,
      instrumentSymbol: json['instrumentSymbol'] as String?,
      type: json['type'] as String?,
      deepLink: json['deepLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'instrumentId': instrumentId,
      'instrumentSymbol': instrumentSymbol,
      'type': type,
      'deepLink': deepLink,
    };
  }
}
