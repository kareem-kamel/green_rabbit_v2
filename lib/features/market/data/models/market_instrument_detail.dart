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
  final Map<String, dynamic>? tradingHours;
  final List<RelatedInstrument>? relatedInstruments;
  final List<TechnicalIndicator>? technicals;
  final List<ContractInfo>? contracts;
  final List<CommentInfo>? comments;

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
    this.technicals,
    this.contracts,
    this.comments,
  });

  factory MarketInstrumentDetail.fromJson(Map<String, dynamic> json) {
    return MarketInstrumentDetail(
      id: (json['id'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      type: (json['type'] ?? 'stock').toString(),
      exchange: json['exchange']?.toString(),
      sector: json['sector']?.toString(),
      industry: json['industry']?.toString(),
      currency: json['currency']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      country: json['country']?.toString(),
      price: json['price'] != null 
          ? PriceInfo.fromJson(json['price'] as Map<String, dynamic>) 
          : PriceInfo(),
      volume: json['volume'] != null 
          ? VolumeInfo.fromJson(json['volume'] as Map<String, dynamic>) 
          : VolumeInfo(),
      fundamentals: json['fundamentals'] != null 
          ? FundamentalsInfo.fromJson(json['fundamentals'] as Map<String, dynamic>) 
          : null,
      marketStatus: json['marketStatus']?.toString(),
      tradingHours: json['tradingHours'] as Map<String, dynamic>?,
      relatedInstruments: (json['relatedInstruments'] as List?)
          ?.map((e) => RelatedInstrument.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicals: (json['technicals'] as List?)
          ?.map((e) => TechnicalIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      contracts: (json['contracts'] as List?)
          ?.map((e) => ContractInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List?)
          ?.map((e) => CommentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TechnicalIndicator {
  final String label;
  final String signal;
  final String? description;
  final String color;
  final bool isLocked;

  TechnicalIndicator({
    required this.label,
    required this.signal,
    this.description,
    required this.color,
    this.isLocked = false,
  });

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      label: (json['label'] ?? '').toString(),
      signal: (json['signal'] ?? '').toString(),
      description: json['description']?.toString(),
      color: (json['color'] ?? 'grey').toString(),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}

class ContractInfo {
  final String month;
  final double? price;
  final double? change;
  final int? volume;

  ContractInfo({required this.month, this.price, this.change, this.volume});

  factory ContractInfo.fromJson(Map<String, dynamic> json) {
    return ContractInfo(
      month: (json['month'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      volume: json['volume'] as int?,
    );
  }
}

class CommentInfo {
  final String user;
  final String time;
  final String text;
  final String? avatar;

  CommentInfo({required this.user, required this.time, required this.text, this.avatar});

  factory CommentInfo.fromJson(Map<String, dynamic> json) {
    return CommentInfo(
      user: (json['user'] ?? 'Anonymous').toString(),
      time: (json['time'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
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
      previousClose: (json['previousClose'] as num?)?.toDouble(),
      open: (json['open'] as num?)?.toDouble(),
      dayHigh: (json['dayHigh'] as num?)?.toDouble(),
      dayLow: (json['dayLow'] as num?)?.toDouble(),
      week52High: (json['week52High'] as num?)?.toDouble(),
      week52Low: (json['week52Low'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      lastUpdatedAt: json['lastUpdatedAt'] as String?,
    );
  }
}

class VolumeInfo {
  final int? current;
  final int? average10d;
  final int? average3m;

  VolumeInfo({this.current, this.average10d, this.average3m});

  factory VolumeInfo.fromJson(Map<String, dynamic> json) {
    return VolumeInfo(
      current: json['current'] as int? ?? 0,
      average10d: json['average10d'] as int?,
      average3m: json['average3m'] as int?,
    );
  }
}

class FundamentalsInfo {
  final double? marketCap;
  final double? enterpriseValue;
  final double? peRatio;
  final double? forwardPeRatio;
  final double? pegRatio;
  final double? priceToBook;
  final double? priceToSales;
  final double? eps;
  final double? dividendYield;
  final double? dividendPerShare;
  final double? beta;
  final int? sharesOutstanding;
  final int? floatShares;
  final double? revenue;
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
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      enterpriseValue: (json['enterpriseValue'] as num?)?.toDouble(),
      peRatio: (json['peRatio'] as num?)?.toDouble(),
      forwardPeRatio: (json['forwardPeRatio'] as num?)?.toDouble(),
      pegRatio: (json['pegRatio'] as num?)?.toDouble(),
      priceToBook: (json['priceToBook'] as num?)?.toDouble(),
      priceToSales: (json['priceToSales'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      dividendPerShare: (json['dividendPerShare'] as num?)?.toDouble(),
      beta: (json['beta'] as num?)?.toDouble(),
      sharesOutstanding: json['sharesOutstanding'] as int?,
      floatShares: json['floatShares'] as int?,
      revenue: (json['revenue'] as num?)?.toDouble(),
      revenueGrowth: (json['revenueGrowth'] as num?)?.toDouble(),
      grossMargin: (json['grossMargin'] as num?)?.toDouble(),
      operatingMargin: (json['operatingMargin'] as num?)?.toDouble(),
      profitMargin: (json['profitMargin'] as num?)?.toDouble(),
      earningsDate: json['earningsDate'] as String?,
      exDividendDate: json['exDividendDate'] as String?,
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
      id: (json['id'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );
  }
}
