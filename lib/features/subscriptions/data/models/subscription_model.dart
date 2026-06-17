class PaymentMethodModel {
  final String last4;
  final String brand;
  final String type;

  PaymentMethodModel({
    required this.last4,
    required this.brand,
    this.type = 'card',
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? 'card',
    );
  }

  Map<String, dynamic> toJson() => {
    'last4': last4,
    'brand': brand,
    'type': type,
  };
}

class SubscriptionModel {
  final String id;
  final String planId;
  final String planName;
  final String status; // 'active', 'canceled', 'expired', 'none'
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final List<String> features;
  final PaymentMethodModel? paymentMethod;
  final bool isFullPro;

  SubscriptionModel({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.features = const [],
    this.paymentMethod,
    this.isFullPro = false,
  });

  bool get isActive => status == 'active';
  bool get isTrial => planId.contains('trial');
  bool get isClassic => planId.contains('classic');

  int get totalDays {
    if (currentPeriodStart == null || currentPeriodEnd == null) return 0;
    return currentPeriodEnd!.difference(currentPeriodStart!).inDays;
  }

  int get daysUsed {
    if (currentPeriodStart == null) return 0;
    final used = DateTime.now().difference(currentPeriodStart!).inDays;
    return used > totalDays ? totalDays : used;
  }

  int get daysRemaining {
    if (currentPeriodEnd == null) return 0;
    final remaining = currentPeriodEnd!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (totalDays == 0) return 0.0;
    return daysUsed / totalDays;
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    // Check if the json contains a nested "subscription" field (like in the verify response)
    final Map<String, dynamic> subJson = json.containsKey('subscription') && json['subscription'] is Map<String, dynamic>
        ? json['subscription'] as Map<String, dynamic>
        : json;

    final planIdValue = subJson['planId'] ?? subJson['providerProductId'] ?? '';
    final isPro = planIdValue.toString().toLowerCase().contains('pro') || 
                  subJson['planName']?.toString().toLowerCase().contains('pro') == true;

    return SubscriptionModel(
      id: subJson['id'] ?? '',
      planId: planIdValue,
      planName: subJson['planName'] ?? (isPro ? 'Pro Plan' : 'Classic Plan'),
      status: subJson['status'] ?? 'none',
      currentPeriodStart: subJson['currentPeriodStart'] != null
          ? DateTime.parse(subJson['currentPeriodStart'])
          : (subJson['startsAt'] != null ? DateTime.parse(subJson['startsAt']) : null),
      currentPeriodEnd: subJson['currentPeriodEnd'] != null
          ? DateTime.parse(subJson['currentPeriodEnd'])
          : (subJson['endsAt'] != null ? DateTime.parse(subJson['endsAt']) : null),
      cancelAtPeriodEnd: subJson['cancelAtPeriodEnd'] ??
          (subJson['autoRenew'] != null ? !(subJson['autoRenew'] as bool) : false),
      features: List<String>.from(subJson['features'] ?? []),
      paymentMethod: subJson['paymentMethod'] != null
          ? PaymentMethodModel.fromJson(subJson['paymentMethod'])
          : null,
      isFullPro: subJson['isFullPro'] ?? isPro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'status': status,
      'currentPeriodStart': currentPeriodStart?.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'features': features,
      'paymentMethod': paymentMethod?.toJson(),
      'isFullPro': isFullPro,
    };
  }

  factory SubscriptionModel.none() {
    return SubscriptionModel(
      id: '',
      planId: '',
      planName: 'Free',
      status: 'none',
    );
  }
}
