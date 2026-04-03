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
    return SubscriptionModel(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? 'none',
      currentPeriodStart: json['currentPeriodStart'] != null ? DateTime.parse(json['currentPeriodStart']) : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null ? DateTime.parse(json['currentPeriodEnd']) : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
      features: List<String>.from(json['features'] ?? []),
      paymentMethod: json['paymentMethod'] != null ? PaymentMethodModel.fromJson(json['paymentMethod']) : null,
      isFullPro: json['isFullPro'] ?? false,
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
