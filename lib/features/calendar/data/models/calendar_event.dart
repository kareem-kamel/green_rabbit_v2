import '../../../market/data/models/market_instrument.dart';

enum CalendarCategory { earnings, dividends, splits, ipo, economic, holidays }

class CalendarEvent {
  final String symbol;
  final String? name;
  final String? exchange;
  final String? currency;
  final String? time; // amc, bmo for earnings
  final double? epsEstimate;
  final double? epsActual;
  final double? difference;
  final double? surprisePercent;
  final double? amount; // for dividends
  final String? description; // for splits
  final double? ratio; // for splits
  final num? fromFactor; // for splits
  final num? toFactor; // for splits
  final double? priceRangeLow; // for ipo
  final double? priceRangeHigh; // for ipo
  final double? offerPrice; // for ipo
  final double? revenueEstimate; // for earnings
  final double? revenueActual; // for earnings
  final double? dividendYield; // for dividends
  final String? paymentDate; // for dividends
  final String? dividendType; // for dividends
  final double? lastPrice; // for ipo
  final String? ipoValue; // for ipo
  final int? shares; // for ipo
  final MarketInstrument? instrument;
  final String? country;

  // Economic specific fields (from image)
  final String? actual;
  final String? forecast;
  final String? previous;
  final int? impact; // 1, 2, 3 stars
  final int? importance; // returned by API for all categories

  CalendarEvent({
    required this.symbol,
    this.name,
    this.exchange,
    this.currency,
    this.time,
    this.epsEstimate,
    this.epsActual,
    this.difference,
    this.surprisePercent,
    this.amount,
    this.description,
    this.ratio,
    this.fromFactor,
    this.toFactor,
    this.priceRangeLow,
    this.priceRangeHigh,
    this.offerPrice,
    this.dividendYield,
    this.paymentDate,
    this.dividendType,
    this.lastPrice,
    this.ipoValue,
    this.shares,
    this.revenueEstimate,
    this.revenueActual,
    this.instrument,
    this.country,
    this.actual,
    this.forecast,
    this.previous,
    this.impact,
    this.importance,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      symbol: json['symbol'] ?? '',
      name: json['name'],
      exchange: json['exchange'],
      currency: json['currency'],
      time: json['time'],
      epsEstimate: _toDouble(json['epsEstimate']),
      epsActual: _toDouble(json['epsActual']),
      difference: _toDouble(json['difference']),
      surprisePercent: _toDouble(json['surprisePercent']),
      amount: _toDouble(json['amount']),
      description: json['description'],
      ratio: _toDouble(json['ratio']),
      fromFactor: _toNum(json['fromFactor']),
      toFactor: _toNum(json['toFactor']),
      priceRangeLow: _toDouble(json['priceRangeLow']),
      priceRangeHigh: _toDouble(json['priceRangeHigh']),
      offerPrice: _toDouble(json['offerPrice']),
      shares: _toInt(json['shares']),
      dividendYield: _toDouble(json['dividendYield']),
      paymentDate: json['paymentDate']?.toString(),
      dividendType: json['dividendType']?.toString(),
      lastPrice: _toDouble(json['lastPrice']),
      ipoValue: json['ipoValue']?.toString(),
      revenueEstimate: _toDouble(json['revenueEstimate']),
      revenueActual: _toDouble(json['revenueActual']),
      instrument: json['instrument'] != null ? MarketInstrument.fromJson(json['instrument']) : null,
      country: json['country']?.toString(),
      actual: json['actual']?.toString(),
      forecast: json['forecast']?.toString(),
      previous: json['previous']?.toString(),
      impact: _toInt(json['impact']),
      importance: _toInt(json['importance']),
    );
  }
}

class CalendarDay {
  final String date;
  final String dayName;
  final int eventCount;
  final List<CalendarEvent> events;

  CalendarDay({
    required this.date,
    required this.dayName,
    required this.eventCount,
    required this.events,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      eventCount: json['eventCount'] ?? 0,
      events: (json['events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
