import '../../../market/data/models/market_instrument.dart';

class WatchlistModel {
  final String id;
  final String name;
  final int instrumentsCount;
  final List<MarketInstrument> instruments;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchlistModel({
    required this.id,
    required this.name,
    required this.instrumentsCount,
    required this.instruments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      instrumentsCount: json['instrumentsCount'] as int? ?? 0,
      instruments: (json['instruments'] as List<dynamic>?)
              ?.map((e) => MarketInstrument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instrumentsCount': instrumentsCount,
      'instruments': instruments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
