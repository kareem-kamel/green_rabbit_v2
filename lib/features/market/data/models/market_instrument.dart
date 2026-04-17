class MarketInstrument {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final String? exchange;
  final String? sector;
  final String? currency;
  final double? price;
  final double? previousClose;
  final double? change;
  final double? changePercent;
  final double? dayHigh;
  final double? dayLow;
  final num? volume;
  final num? marketCap;
  final String? logoUrl;
  final List<double>? sparkline7d;

  const MarketInstrument({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
    this.sector,
    this.currency,
    this.price,
    this.previousClose,
    this.change,
    this.changePercent,
    this.dayHigh,
    this.dayLow,
    this.volume,
    this.marketCap,
    this.logoUrl,
    this.sparkline7d,
  });

  factory MarketInstrument.fromJson(Map<String, dynamic> json) {
    return MarketInstrument(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      currency: json['currency'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      previousClose: (json['previousClose'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      dayHigh: (json['dayHigh'] as num?)?.toDouble(),
      dayLow: (json['dayLow'] as num?)?.toDouble(),
      volume: json['volume'] as num?,
      marketCap: json['marketCap'] as num?,
      logoUrl: json['logoUrl'] as String?,
      sparkline7d: (json['sparkline7d'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'type': type,
      'exchange': exchange,
      'sector': sector,
      'currency': currency,
      'price': price,
      'previousClose': previousClose,
      'change': change,
      'changePercent': changePercent,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'volume': volume,
      'marketCap': marketCap,
      'logoUrl': logoUrl,
      'sparkline7d': sparkline7d,
    };
  }
}
