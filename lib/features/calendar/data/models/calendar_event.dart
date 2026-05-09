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
  final int? fromFactor; // for splits
  final int? toFactor; // for splits
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

  // Economic specific fields (from image)
  final String? actual;
  final String? forecast;
  final String? previous;
  final int? impact; // 1, 2, 3 stars

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
    this.actual,
    this.forecast,
    this.previous,
    this.impact,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      symbol: json['symbol'] ?? '',
      name: json['name'],
      exchange: json['exchange'],
      currency: json['currency'],
      time: json['time'],
      epsEstimate: (json['epsEstimate'] as num?)?.toDouble(),
      epsActual: (json['epsActual'] as num?)?.toDouble(),
      difference: (json['difference'] as num?)?.toDouble(),
      surprisePercent: (json['surprisePercent'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      description: json['description'],
      ratio: (json['ratio'] as num?)?.toDouble(),
      fromFactor: json['fromFactor'] as int?,
      toFactor: json['toFactor'] as int?,
      priceRangeLow: (json['priceRangeLow'] as num?)?.toDouble(),
      priceRangeHigh: (json['priceRangeHigh'] as num?)?.toDouble(),
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      shares: json['shares'] as int?,
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      paymentDate: json['paymentDate']?.toString(),
      dividendType: json['dividendType']?.toString(),
      lastPrice: (json['lastPrice'] as num?)?.toDouble(),
      ipoValue: json['ipoValue']?.toString(),
      revenueEstimate: (json['revenueEstimate'] as num?)?.toDouble(),
      revenueActual: (json['revenueActual'] as num?)?.toDouble(),
      instrument: json['instrument'] != null ? MarketInstrument.fromJson(json['instrument']) : null,
      actual: json['actual']?.toString(),
      forecast: json['forecast']?.toString(),
      previous: json['previous']?.toString(),
      impact: json['impact'] as int?,
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
