import 'package:green_rabbit/features/market/data/models/market_instrument.dart';

class AlertModel {
  final String id;
  final MarketInstrument instrument;
  final double targetPrice;
  final String type;
  final String typeDisplay;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? triggeredAt;
  final double? triggeredPrice;
  final double? priceDifference;
  final double? priceDifferencePercent;

  AlertModel({
    required this.id,
    required this.instrument,
    required this.targetPrice,
    required this.type,
    required this.typeDisplay,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.triggeredAt,
    this.triggeredPrice,
    this.priceDifference,
    this.priceDifferencePercent,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      instrument: MarketInstrument.fromJson(json['instrument'] as Map<String, dynamic>),
      targetPrice: (json['targetPrice'] as num).toDouble(),
      type: json['type'] as String,
      typeDisplay: json['typeDisplay'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      triggeredAt: json['triggeredAt'] != null ? DateTime.parse(json['triggeredAt'] as String) : null,
      triggeredPrice: (json['triggeredPrice'] as num?)?.toDouble(),
      priceDifference: (json['priceDifference'] as num?)?.toDouble(),
      priceDifferencePercent: (json['priceDifferencePercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instrument': instrument.toJson(),
      'targetPrice': targetPrice,
      'type': type,
      'typeDisplay': typeDisplay,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'triggeredPrice': triggeredPrice,
      'priceDifference': priceDifference,
      'priceDifferencePercent': priceDifferencePercent,
    };
  }
}

class AlertsSummary {
  final int total;
  final int active;
  final int triggered;

  AlertsSummary({
    required this.total,
    required this.active,
    required this.triggered,
  });

  factory AlertsSummary.fromJson(Map<String, dynamic> json) {
    return AlertsSummary(
      total: json['total'] as int,
      active: json['active'] as int,
      triggered: json['triggered'] as int,
    );
  }
}
