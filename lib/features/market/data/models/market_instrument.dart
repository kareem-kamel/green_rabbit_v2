class MarketInstrument {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final String? exchange;
  final String? sector;
  final String? currency;
  final double price;
  final double? previousClose;
  final double change;
  final double changePercent;
  final double? dayHigh;
  final double? dayLow;
  final int? volume;
  final int? marketCap;
  final String? logoUrl;
  final List<double>? sparkline;

  const MarketInstrument({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
    this.sector,
    this.currency,
    required this.price,
    this.previousClose,
    required this.change,
    required this.changePercent,
    this.dayHigh,
    this.dayLow,
    this.volume,
    this.marketCap,
    this.logoUrl,
    this.sparkline,
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
      price: ((json['price'] ?? json['current_price']) as num).toDouble(),
      previousClose: (json['previousClose'] as num?)?.toDouble(),
      change: ((json['change'] ?? json['price_change']) as num).toDouble(),
      changePercent: ((json['changePercent'] ?? json['price_change_percent']) as num).toDouble(),
      dayHigh: (json['dayHigh'] as num?)?.toDouble(),
      dayLow: (json['dayLow'] as num?)?.toDouble(),
      volume: json['volume'] as int?,
      marketCap: json['marketCap'] as int?,
      logoUrl: (json['logoUrl'] ?? json['logo_url']) as String?,
      sparkline: (json['sparkline7d'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'type': type,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'logoUrl': logoUrl,
      'sparkline': sparkline,
    };
  }
}
