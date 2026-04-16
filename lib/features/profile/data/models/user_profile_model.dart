class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? country;
  final String? phone;
  final String? avatarUrl;
  final bool emailVerified;
  final bool onboardingDone;
  final String status;
  final UserPreferencesModel preferences;
  final SubscriptionModel subscription;
  final UserStatsModel? stats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.country,
    this.phone,
    this.avatarUrl,
    required this.emailVerified,
    required this.onboardingDone,
    required this.status,
    required this.preferences,
    required this.subscription,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: json['emailVerified'].toString() == 'true',
      onboardingDone: json['onboardingDone'].toString() == 'true',
      status: json['status'] as String,
      preferences: UserPreferencesModel.fromJson(json['preferences'] as Map<String, dynamic>),
      subscription: SubscriptionModel.fromJson(json['subscription'] as Map<String, dynamic>),
      stats: json['stats'] != null ? UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'country': country,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'emailVerified': emailVerified,
      'onboardingDone': onboardingDone,
      'status': status,
      'preferences': preferences.toJson(),
      'subscription': subscription.toJson(),
      'stats': stats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

class UserPreferencesModel {
  final String language;
  final String theme;
  final String currency;
  final NotificationPreferencesModel notifications;

  UserPreferencesModel({
    required this.language,
    required this.theme,
    required this.currency,
    required this.notifications,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      language: json['language'] as String,
      theme: json['theme'] as String,
      currency: json['currency'] as String,
      notifications: NotificationPreferencesModel.fromJson(json['notifications'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'currency': currency,
      'notifications': notifications.toJson(),
    };
  }
}

class NotificationPreferencesModel {
  final bool push;
  final bool smartAlerts;

  NotificationPreferencesModel({
    required this.push,
    required this.smartAlerts,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      push: json['push'] as bool? ?? false,
      smartAlerts: json['smart-alerts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push': push,
      'smart-alerts': smartAlerts,
    };
  }
}

class SubscriptionModel {
  final String tier;
  final DateTime? expiresAt;
  final bool autoRenew;

  SubscriptionModel({
    required this.tier,
    this.expiresAt,
    required this.autoRenew,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      tier: json['tier'] as String,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      autoRenew: json['autoRenew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'expiresAt': expiresAt?.toIso8601String(),
      'autoRenew': autoRenew,
    };
  }
}

class UserStatsModel {
  final int totalComments;
  final int totalWatchlists;
  final int memberSinceDays;

  UserStatsModel({
    required this.totalComments,
    required this.totalWatchlists,
    required this.memberSinceDays,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalComments: json['totalComments'] as int? ?? 0,
      totalWatchlists: json['totalWatchlists'] as int? ?? 0,
      memberSinceDays: json['memberSinceDays'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalComments': totalComments,
      'totalWatchlists': totalWatchlists,
      'memberSinceDays': memberSinceDays,
    };
  }
}
