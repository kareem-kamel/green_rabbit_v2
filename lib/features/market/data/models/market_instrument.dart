import '../../../../core/constants/app_constants.dart';
import 'market_instrument_detail.dart';

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
  final String? lastUpdatedAt;
  final CryptoMetricsInfo? cryptoMetrics;

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
    this.lastUpdatedAt,
    this.cryptoMetrics,
  });

  factory MarketInstrument.fromJson(Map<String, dynamic> json) {
    dynamic findValue(List<String> keys) {
      for (final key in keys) {
        // 1. Check root
        if (json.containsKey(key) && json[key] != null) return json[key];
        
        // 2. Check common nested parents (often APIs wrap data in these)
        for (final parent in ['stats', 'quote', 'instrument', 'price', 'volume', 'info', 'data', 'details', 'summary', 'item']) {
          if (json.containsKey(parent) && json[parent] is Map) {
            final parentMap = Map<String, dynamic>.from(json[parent] as Map);
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

    final parsedSymbol = (findValue(['symbol', 'symbolName', 'ticker']) ?? '').toString();
    final parsedExchange = findValue(['exchange', 'exchangeName', 'primaryExchange'])?.toString();
    final parsedName = (findValue(['name', 'displayName', 'shortName', 'longName']) ?? '').toString();
    final displayName = AppConstants.getInstrumentDisplayName(parsedSymbol, parsedName, parsedExchange);

    return MarketInstrument(
      id: (findValue(['id', 'instrumentId', 'uuid']) ?? '').toString(),
      symbol: parsedSymbol,
      name: displayName,
      type: (json['type'] ?? json['instrumentType'] ?? json['assetClass'] ?? findValue(['type', 'assetClass']))?.toString() ?? '',
      exchange: parsedExchange,
      sector: findValue(['sector', 'sectorName', 'category'])?.toString(),
      currency: findValue(['currency', 'currencyCode', 'quoteCurrency'])?.toString(),
      price: toDouble(findValue(['price', 'currentPrice', 'lastPrice', 'last', 'close', 'current', 'rate', 'priceUsd', 'last_price', 'price_current', 'price_usd', 'regularMarketPrice'])),
      previousClose: toDouble(findValue(['previousClose', 'prevClose', 'regularMarketPreviousClose', 'close', 'lastClose', 'prev_close', 'previous_close'])),
      change: toDouble(findValue(['change', 'dayChange', 'priceChange', 'absoluteChange', 'diff', 'price_change'])),
      changePercent: toDouble(findValue(['changePercent', 'percentChange', 'dayChangePercent', 'change_percent', 'percent_change', 'priceChangePercent', 'price_change_percent'])),
      dayHigh: toDouble(findValue(['dayHigh', 'high', 'day_high', 'regularMarketDayHigh', 'h'])),
      dayLow: toDouble(findValue(['dayLow', 'low', 'day_low', 'regularMarketDayLow', 'l'])),
      volume: toNum(findValue(['volume', 'vol', '24hVolume', 'regularMarketVolume', 'v', 'totalVolume'])),
      marketCap: toNum(findValue(['marketCap', 'mktCap', 'market_cap', 'market_cap_usd', 'cap'])),
      logoUrl: (json['logoUrl'] ?? json['logo_url'] ?? json['iconUrl'] ?? json['image'])?.toString(),
      sparkline7d: _parseSparkline(findValue(['sparkline7d', 'sparkline', 'chartData', 'history', 'sparkline_7d'])),
      displayOrder: json['displayOrder'] as int?,
      addedAt: json['addedAt'] as String?,
      lastUpdatedAt: json['lastUpdatedAt']?.toString() ?? json['timestamp']?.toString(),
      cryptoMetrics: json['cryptoMetrics'] is Map 
          ? CryptoMetricsInfo.fromJson(Map<String, dynamic>.from(json['cryptoMetrics'] as Map))
          : (json['crypto_metrics'] is Map ? CryptoMetricsInfo.fromJson(Map<String, dynamic>.from(json['crypto_metrics'] as Map)) : null),
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
      'lastUpdatedAt': lastUpdatedAt,
      'cryptoMetrics': cryptoMetrics,
    };
  }

  MarketInstrument copyWith({
    String? id,
    String? symbol,
    String? name,
    String? type,
    String? exchange,
    String? sector,
    String? currency,
    double? price,
    double? previousClose,
    double? change,
    double? changePercent,
    double? dayHigh,
    double? dayLow,
    num? volume,
    num? marketCap,
    String? logoUrl,
    List<double>? sparkline7d,
    int? displayOrder,
    String? addedAt,
    String? lastUpdatedAt,
    CryptoMetricsInfo? cryptoMetrics,
  }) {
    return MarketInstrument(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      currency: currency ?? this.currency,
      price: price ?? this.price,
      previousClose: previousClose ?? this.previousClose,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      volume: volume ?? this.volume,
      marketCap: marketCap ?? this.marketCap,
      logoUrl: logoUrl ?? this.logoUrl,
      sparkline7d: sparkline7d ?? this.sparkline7d,
      displayOrder: displayOrder ?? this.displayOrder,
      addedAt: addedAt ?? this.addedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      cryptoMetrics: cryptoMetrics ?? this.cryptoMetrics,
    );
  }
}

class MarketOverviewResponse {
  final List<MarketInstrument> instruments;
  final MarketOverviewMeta meta;
  final String? lastUpdatedAt;
  final String? marketStatus;

  MarketOverviewResponse({
    required this.instruments,
    required this.meta,
    this.lastUpdatedAt,
    this.marketStatus,
  });

  factory MarketOverviewResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic>? list;
    final innerData = json['data'];
    if (innerData is Map) {
      list = innerData['instruments'] as List<dynamic>?;
    } else if (innerData is List) {
      list = innerData;
    } else {
      list = json['instruments'] as List<dynamic>?;
    }

    final instrumentsList = (list ?? []).whereType<Map>().map((item) {
      return MarketInstrument.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    final meta = MarketOverviewMeta.fromJson(metaJson);

    final String? lastUpdatedAt = innerData is Map ? innerData['lastUpdatedAt']?.toString() : null;
    final String? marketStatus = innerData is Map ? innerData['marketStatus']?.toString() : null;

    return MarketOverviewResponse(
      instruments: instrumentsList,
      meta: meta,
      lastUpdatedAt: lastUpdatedAt,
      marketStatus: marketStatus,
    );
  }
}

class MarketOverviewMeta {
  final int page;
  final int limit;
  final bool hasNext;
  final bool hasPrev;
  final int? totalPages;
  final int? totalItems;

  MarketOverviewMeta({
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
    this.totalPages,
    this.totalItems,
  });

  factory MarketOverviewMeta.fromJson(Map<String, dynamic> json) {
    return MarketOverviewMeta(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      hasNext: (json['hasNext'] as bool?) ?? (json['hasNextPage'] as bool?) ?? false,
      hasPrev: (json['hasPrev'] as bool?) ?? (json['hasPreviousPage'] as bool?) ?? false,
      totalPages: json['totalPages'] as int? ?? json['total_pages'] as int?,
      totalItems: json['totalItems'] as int? ?? json['total_items'] as int?,
    );
  }
}
