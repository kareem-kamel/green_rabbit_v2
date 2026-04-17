class MarketInstrumentDetail {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final String? exchange;
  final String? sector;
  final String? industry;
  final String? currency;
  final String? description;
  final String? website;
  final String? logoUrl;
  final String? country;
  final PriceInfo price;
  final VolumeInfo volume;
  final FundamentalsInfo? fundamentals;
  final String? marketStatus;
  final TradingHoursInfo? tradingHours;
  final List<RelatedInstrument>? relatedInstruments;
  final List<InstrumentContract>? contracts;
  final List<InstrumentComment>? comments;

  MarketInstrumentDetail({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
    this.sector,
    this.industry,
    this.currency,
    this.description,
    this.website,
    this.logoUrl,
    this.country,
    required this.price,
    required this.volume,
    this.fundamentals,
    this.marketStatus,
    this.tradingHours,
    this.relatedInstruments,
    this.contracts,
    this.comments,
  });
  factory MarketInstrumentDetail.fromJson(Map<String, dynamic> json) {
    final priceJson = json['price'] as Map<String, dynamic>?;
    final statsJson = json['stats'] as Map<String, dynamic>?;
    final summaryJson = statsJson?['summary'] as Map<String, dynamic>?;

    return MarketInstrumentDetail(
      id: json['id'].toString(),
      symbol: json['symbol'].toString(),
      name: json['name'].toString(),
      type: json['type'].toString(),
      exchange: json['exchange']?.toString() ?? summaryJson?['exchange']?.toString(),
      sector: json['sector']?.toString(),
      industry: json['industry']?.toString(),
      currency: json['currency']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      country: json['country']?.toString(),
      price: PriceInfo.fromNestedJson(priceJson, summaryJson),
      volume: VolumeInfo.fromNestedJson(json['volume'] as Map<String, dynamic>?, summaryJson),
      fundamentals: FundamentalsInfo.fromNestedJson(json['fundamentals'] as Map<String, dynamic>?, summaryJson),
      marketStatus: json['marketStatus']?.toString(),
      tradingHours: json['tradingHours'] != null ? TradingHoursInfo.fromJson(json['tradingHours'] as Map<String, dynamic>) : null,
      relatedInstruments: (json['relatedInstruments'] as List?)
          ?.map((e) => RelatedInstrument.fromJson(e as Map<String, dynamic>))
          .toList(),
      contracts: (json['contracts'] as List?)
          ?.map((e) => InstrumentContract.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List?)
          ?.map((e) => InstrumentComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PriceInfo {
  final double? current;
  final double? previousClose;
  final double? open;
  final double? dayHigh;
  final double? dayLow;
  final double? week52High;
  final double? week52Low;
  final double? change;
  final double? changePercent;
  final String? lastUpdatedAt;

  PriceInfo({
    this.current,
    this.previousClose,
    this.open,
    this.dayHigh,
    this.dayLow,
    this.week52High,
    this.week52Low,
    this.change,
    this.changePercent,
    this.lastUpdatedAt,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      current: (json['current'] as num?)?.toDouble(),
      previousClose: (json['previousClose'] as num?)?.toDouble() ?? (json['prevClose'] as num?)?.toDouble(),
      open: (json['open'] as num?)?.toDouble(),
      dayHigh: (json['dayHigh'] as num?)?.toDouble() ?? (json['high'] as num?)?.toDouble(),
      dayLow: (json['dayLow'] as num?)?.toDouble() ?? (json['low'] as num?)?.toDouble(),
      week52High: (json['week52High'] as num?)?.toDouble() ?? (json['52WeekHigh'] as num?)?.toDouble(),
      week52Low: (json['week52Low'] as num?)?.toDouble() ?? (json['52WeekLow'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      lastUpdatedAt: json['lastUpdatedAt']?.toString(),
    );
  }

  factory PriceInfo.fromNestedJson(Map<String, dynamic>? priceJson, Map<String, dynamic>? summaryJson) {
    final merged = {
      if (priceJson != null) ...priceJson,
      if (summaryJson != null) ...summaryJson,
    };
    return PriceInfo.fromJson(merged);
  }
}

class VolumeInfo {
  final num? current;
  final num? average10d;
  final num? average3m;

  VolumeInfo({this.current, this.average10d, this.average3m});

  factory VolumeInfo.fromJson(Map<String, dynamic> json) {
    return VolumeInfo(
      current: json['current'] as num? ?? json['volume'] as num?,
      average10d: json['average10d'] as num? ?? json['avgVolume'] as num?,
      average3m: json['average3m'] as num?,
    );
  }

  factory VolumeInfo.fromNestedJson(Map<String, dynamic>? volJson, Map<String, dynamic>? summaryJson) {
    final merged = {
      if (volJson != null) ...volJson,
      if (summaryJson != null) ...summaryJson,
    };
    return VolumeInfo.fromJson(merged);
  }
}

class FundamentalsInfo {
  final num? marketCap;
  final num? enterpriseValue;
  final double? peRatio;
  final double? forwardPeRatio;
  final double? pegRatio;
  final double? priceToBook;
  final double? priceToSales;
  final double? eps;
  final double? dividendYield;
  final double? dividendPerShare;
  final double? beta;
  final num? sharesOutstanding;
  final num? floatShares;
  final num? revenue;
  final double? revenueGrowth;
  final double? grossMargin;
  final double? operatingMargin;
  final double? profitMargin;
  final String? earningsDate;
  final String? exDividendDate;

  FundamentalsInfo({
    this.marketCap,
    this.enterpriseValue,
    this.peRatio,
    this.forwardPeRatio,
    this.pegRatio,
    this.priceToBook,
    this.priceToSales,
    this.eps,
    this.dividendYield,
    this.dividendPerShare,
    this.beta,
    this.sharesOutstanding,
    this.floatShares,
    this.revenue,
    this.revenueGrowth,
    this.grossMargin,
    this.operatingMargin,
    this.profitMargin,
    this.earningsDate,
    this.exDividendDate,
  });

  factory FundamentalsInfo.fromJson(Map<String, dynamic> json) {
    return FundamentalsInfo(
      marketCap: json['marketCap'] as num?,
      enterpriseValue: json['enterpriseValue'] as num?,
      peRatio: (json['peRatio'] as num?)?.toDouble(),
      forwardPeRatio: (json['forwardPeRatio'] as num?)?.toDouble(),
      pegRatio: (json['pegRatio'] as num?)?.toDouble(),
      priceToBook: (json['priceToBook'] as num?)?.toDouble(),
      priceToSales: (json['priceToSales'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      dividendPerShare: (json['dividendPerShare'] as num?)?.toDouble(),
      beta: (json['beta'] as num?)?.toDouble(),
      sharesOutstanding: json['sharesOutstanding'] as num?,
      floatShares: json['floatShares'] as num?,
      revenue: json['revenue'] as num?,
      revenueGrowth: (json['revenueGrowth'] as num?)?.toDouble(),
      grossMargin: (json['grossMargin'] as num?)?.toDouble(),
      operatingMargin: (json['operatingMargin'] as num?)?.toDouble(),
      profitMargin: (json['profitMargin'] as num?)?.toDouble(),
      earningsDate: json['earningsDate']?.toString(),
      exDividendDate: json['exDividendDate']?.toString(),
    );
  }

  factory FundamentalsInfo.fromNestedJson(Map<String, dynamic>? fundJson, Map<String, dynamic>? summaryJson) {
    if (fundJson == null && summaryJson == null) return FundamentalsInfo();
    final merged = {
      if (fundJson != null) ...fundJson,
      if (summaryJson != null) ...summaryJson,
    };
    return FundamentalsInfo.fromJson(merged);
  }
}

class TradingHoursInfo {
  final String? timezone;
  final String? regularOpen;
  final String? regularClose;
  final String? preMarketOpen;
  final String? afterHoursClose;

  TradingHoursInfo({
    this.timezone,
    this.regularOpen,
    this.regularClose,
    this.preMarketOpen,
    this.afterHoursClose,
  });

  factory TradingHoursInfo.fromJson(Map<String, dynamic> json) {
    return TradingHoursInfo(
      timezone: json['timezone']?.toString(),
      regularOpen: json['regularOpen']?.toString(),
      regularClose: json['regularClose']?.toString(),
      preMarketOpen: json['preMarketOpen']?.toString(),
      afterHoursClose: json['afterHoursClose']?.toString(),
    );
  }
}

class RelatedInstrument {
  final String id;
  final String symbol;
  final String name;
  final double? changePercent;

  RelatedInstrument({
    required this.id,
    required this.symbol,
    required this.name,
    this.changePercent,
  });

  factory RelatedInstrument.fromJson(Map<String, dynamic> json) {
    return RelatedInstrument(
      id: json['id'].toString(),
      symbol: json['symbol'].toString(),
      name: json['name'].toString(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );
  }
}

class MarketInstrumentStats {
  final PerformanceInfo performance;
  final VolatilityInfo volatility;
  final TechnicalsInfo technicals;
  final AnalystRatings? analystRatings;
  final DividendsInfo? dividends;
  final List<EarningsResult>? earningsHistory;

  MarketInstrumentStats({
    required this.performance,
    required this.volatility,
    required this.technicals,
    this.analystRatings,
    this.dividends,
    this.earningsHistory,
  });

  factory MarketInstrumentStats.fromJson(Map<String, dynamic> json) {
    return MarketInstrumentStats(
      performance: PerformanceInfo.fromJson((json['performance'] ?? {}) as Map<String, dynamic>),
      volatility: VolatilityInfo.fromJson((json['volatility'] ?? {}) as Map<String, dynamic>),
      technicals: TechnicalsInfo.fromJson((json['technical'] ?? json['technicals'] ?? {}) as Map<String, dynamic>),
      analystRatings: json['analystRatings'] != null ? AnalystRatings.fromJson(json['analystRatings'] as Map<String, dynamic>) : null,
      dividends: json['dividends'] != null ? DividendsInfo.fromJson(json['dividends'] as Map<String, dynamic>) : null,
      earningsHistory: (json['earningsHistory'] as List?)
          ?.map((e) => EarningsResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PerformanceInfo {
  final double? return1d;
  final double? return1w;
  final double? return1m;
  final double? return3m;
  final double? return6m;
  final double? return1y;
  final double? returnYtd;
  final double? returnMax;

  PerformanceInfo({
    this.return1d,
    this.return1w,
    this.return1m,
    this.return3m,
    this.return6m,
    this.return1y,
    this.returnYtd,
    this.returnMax,
  });

  factory PerformanceInfo.fromJson(Map<String, dynamic> json) {
    return PerformanceInfo(
      return1d: (json['return1d'] as num?)?.toDouble(),
      return1w: (json['return1w'] as num?)?.toDouble(),
      return1m: (json['return1m'] as num?)?.toDouble(),
      return3m: (json['return3m'] as num?)?.toDouble(),
      return6m: (json['return6m'] as num?)?.toDouble(),
      return1y: (json['return1y'] as num?)?.toDouble(),
      returnYtd: (json['returnYtd'] as num?)?.toDouble(),
      returnMax: (json['returnMax'] as num?)?.toDouble(),
    );
  }
}

class VolatilityInfo {
  final double? beta;
  final double? standardDeviation30d;
  final double? averageTrueRange14d;
  final double? maxDrawdown1y;

  VolatilityInfo({
    this.beta,
    this.standardDeviation30d,
    this.averageTrueRange14d,
    this.maxDrawdown1y,
  });

  factory VolatilityInfo.fromJson(Map<String, dynamic> json) {
    return VolatilityInfo(
      beta: (json['beta'] as num?)?.toDouble(),
      standardDeviation30d: (json['standardDeviation30d'] as num?)?.toDouble(),
      averageTrueRange14d: (json['averageTrueRange14d'] as num?)?.toDouble(),
      maxDrawdown1y: (json['maxDrawdown1y'] as num?)?.toDouble(),
    );
  }
}

class TechnicalsInfo {
  final String? overallSignal;
  final Map<String, dynamic>? pivotPoints;
  final List<dynamic>? movingAverages;
  final List<dynamic>? indicators;

  TechnicalsInfo({
    this.overallSignal,
    this.pivotPoints,
    this.movingAverages,
    this.indicators,
  });

  factory TechnicalsInfo.fromJson(Map<String, dynamic> json) {
    return TechnicalsInfo(
      overallSignal: json['marketBias']?['overallSignal']?.toString(),
      pivotPoints: json['pivotPoints'] as Map<String, dynamic>?,
      movingAverages: json['movingAverages']?['data'] as List?,
      indicators: json['indicators'] as List?,
    );
  }
}

class AnalystRatings {
  final String? consensus;
  final double? targetMean;
  final int? numberOfAnalysts;
  final Map<String, dynamic>? distribution;

  AnalystRatings({
    this.consensus,
    this.targetMean,
    this.numberOfAnalysts,
    this.distribution,
  });

  factory AnalystRatings.fromJson(Map<String, dynamic> json) {
    return AnalystRatings(
      consensus: json['consensus']?.toString(),
      targetMean: (json['targetMean'] as num?)?.toDouble(),
      numberOfAnalysts: json['numberOfAnalysts'] as int?,
      distribution: json['distribution'] as Map<String, dynamic>?,
    );
  }
}

class DividendsInfo {
  final double? yield;
  final double? annualDividend;
  final String? exDividendDate;

  DividendsInfo({this.yield, this.annualDividend, this.exDividendDate});

  factory DividendsInfo.fromJson(Map<String, dynamic> json) {
    return DividendsInfo(
      yield: (json['yield'] as num?)?.toDouble(),
      annualDividend: (json['annualDividend'] as num?)?.toDouble(),
      exDividendDate: json['exDividendDate']?.toString(),
    );
  }
}

class EarningsResult {
  final String? quarter;
  final String? date;
  final double? epsEstimate;
  final double? epsActual;

  EarningsResult({this.quarter, this.date, this.epsEstimate, this.epsActual});

  factory EarningsResult.fromJson(Map<String, dynamic> json) {
    return EarningsResult(
      quarter: json['quarter']?.toString(),
      date: json['date']?.toString(),
      epsEstimate: (json['epsEstimate'] as num?)?.toDouble(),
      epsActual: (json['epsActual'] as num?)?.toDouble(),
    );
  }
}

class InstrumentContract {
  final String month;
  final double? price;
  final double? change;
  final int? volume;

  InstrumentContract({required this.month, this.price, this.change, this.volume});

  factory InstrumentContract.fromJson(Map<String, dynamic> json) {
    return InstrumentContract(
      month: json['month']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      volume: json['volume'] as int?,
    );
  }
}

class InstrumentComment {
  final String user;
  final String? avatar;
  final String time;
  final String text;

  InstrumentComment({required this.user, this.avatar, required this.time, required this.text});

  factory InstrumentComment.fromJson(Map<String, dynamic> json) {
    return InstrumentComment(
      user: json['user']?.toString() ?? 'Anonymous',
      avatar: json['avatar']?.toString(),
      time: json['time']?.toString() ?? 'Just now',
      text: json['text']?.toString() ?? '',
    );
  }
}

class TechnicalIndicator {
  final String name;
  final String value;
  final String signal;
  final String color;
  final bool isLocked;

  TechnicalIndicator({
    required this.name, 
    required this.value, 
    required this.signal, 
    required this.color,
    this.isLocked = false,
  });

  String get label => name;

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      signal: json['signal']?.toString() ?? '',
      color: json['color']?.toString() ?? 'neutral',
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}
