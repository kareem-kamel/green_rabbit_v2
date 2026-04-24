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
  final int? displayOrder;
  final String? addedAt;

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
    this.displayOrder,
    this.addedAt,
  });

  factory MarketInstrument.fromJson(Map<String, dynamic> json) {
    dynamic findValue(List<String> keys) {
      for (final key in keys) {
        // 1. Check root
        if (json.containsKey(key) && json[key] != null) return json[key];
        
        // 2. Check common nested parents (often APIs wrap data in these)
        for (final parent in ['stats', 'quote', 'instrument', 'price', 'volume', 'info', 'data', 'details', 'summary', 'item']) {
          if (json.containsKey(parent) && json[parent] is Map) {
            final parentMap = json[parent] as Map<String, dynamic>;
            if (parentMap.containsKey(key) && parentMap[key] != null) return parentMap[key];
          }
        }
      }
      return null;
    }

    double? toDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        // Aggressively clean: remove everything except digits, dots, and minus sign
        // This handles cases like "$1,234.56" or "1 234.56"
        final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned);
      }
      if (val is Map) {
        // If we accidentally got a map (like 'price' object itself), try to find a value inside it
        return toDouble(val['current'] ?? val['price'] ?? val['value'] ?? val['last'] ?? val['close'] ?? val['amount'] ?? val['rate']);
      }
      return null;
    }

    num? toNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val;
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
        return num.tryParse(cleaned);
      }
      if (val is Map) {
        return toNum(val['current'] ?? val['volume'] ?? val['value'] ?? val['vol'] ?? val['24hVolume'] ?? val['total'] ?? val['amount']);
      }
      return null;
    }

    return MarketInstrument(
      id: (findValue(['id', 'instrumentId', 'uuid']) ?? '').toString(),
      symbol: (findValue(['symbol', 'symbolName', 'ticker']) ?? '').toString(),
      name: (findValue(['name', 'displayName', 'shortName', 'longName']) ?? '').toString(),
      type: (json['type'] ?? json['instrumentType'] ?? json['assetClass'] ?? findValue(['type', 'assetClass']))?.toString() ?? '',
      exchange: findValue(['exchange', 'exchangeName', 'primaryExchange'])?.toString(),
      sector: findValue(['sector', 'sectorName', 'category'])?.toString(),
      currency: findValue(['currency', 'currencyCode', 'quoteCurrency'])?.toString(),
      price: toDouble(findValue(['price', 'currentPrice', 'lastPrice', 'last', 'close', 'current', 'rate', 'priceUsd'])),
      previousClose: toDouble(findValue(['previousClose', 'prevClose', 'regularMarketPreviousClose', 'close', 'lastClose'])),
      change: toDouble(findValue(['change', 'dayChange', 'priceChange', 'absoluteChange', 'diff'])),
      changePercent: toDouble(findValue(['changePercent', 'percentChange', 'dayChangePercent', 'change_percent', 'percent_change'])),
      dayHigh: toDouble(findValue(['dayHigh', 'high', 'day_high', 'regularMarketDayHigh', 'h'])),
      dayLow: toDouble(findValue(['dayLow', 'low', 'day_low', 'regularMarketDayLow', 'l'])),
      volume: toNum(findValue(['volume', 'vol', '24hVolume', 'regularMarketVolume', 'v', 'totalVolume'])),
      marketCap: toNum(findValue(['marketCap', 'mktCap', 'market_cap', 'market_cap_usd', 'cap'])),
      logoUrl: (json['logoUrl'] ?? json['logo_url'] ?? json['iconUrl'] ?? json['image'])?.toString(),
      sparkline7d: _parseSparkline(findValue(['sparkline7d', 'sparkline', 'chartData', 'history', 'sparkline_7d'])),
      displayOrder: json['displayOrder'] as int?,
      addedAt: json['addedAt'] as String?,
    );
  }

  static List<double>? _parseSparkline(dynamic data) {
    if (data is! List) return null;
    return data.map((e) {
      if (e == null) return 0.0;
      if (e is num) return e.toDouble();
      if (e is String) return double.tryParse(e) ?? 0.0;
      return 0.0;
    }).toList();
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
      'displayOrder': displayOrder,
      'addedAt': addedAt,
    };
  }
}
