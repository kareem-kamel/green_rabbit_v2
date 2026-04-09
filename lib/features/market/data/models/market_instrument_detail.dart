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
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      country: json['country'] as String?,
      price: PriceInfo.fromJson(json['price'] as Map<String, dynamic>),
      volume: VolumeInfo.fromJson(json['volume'] as Map<String, dynamic>),
      fundamentals: json['fundamentals'] != null 
          ? FundamentalsInfo.fromJson(json['fundamentals'] as Map<String, dynamic>) 
          : null,
      marketStatus: json['marketStatus'] as String?,
      tradingHours: json['tradingHours'] as Map<String, dynamic>?,
      relatedInstruments: (json['relatedInstruments'] as List<dynamic>?)
          ?.map((e) => RelatedInstrument.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicals: (json['technicals'] as List<dynamic>?)
          ?.map((e) => TechnicalIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      contracts: (json['contracts'] as List<dynamic>?)
          ?.map((e) => ContractInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>?)
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
      label: json['label'] as String,
      signal: json['signal'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}

class ContractInfo {
  final String month;
  final double price;
  final double change;
  final int volume;

  ContractInfo({required this.month, required this.price, required this.change, required this.volume});

  factory ContractInfo.fromJson(Map<String, dynamic> json) {
    return ContractInfo(
      month: json['month'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      volume: json['volume'] as int,
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
      user: json['user'] as String,
      time: json['time'] as String,
      text: json['text'] as String,
      avatar: json['avatar'] as String?,
    );
  }
}

class PriceInfo {
  final double current;
  final double? previousClose;
  final double? open;
  final double? dayHigh;
  final double? dayLow;
  final double? week52High;
  final double? week52Low;
  final double change;
  final double changePercent;
  final String? lastUpdatedAt;

  PriceInfo({
    required this.current,
    this.previousClose,
    this.open,
    this.dayHigh,
    this.dayLow,
    this.week52High,
    this.week52Low,
    required this.change,
    required this.changePercent,
    this.lastUpdatedAt,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      current: (json['current'] as num).toDouble(),
      previousClose: (json['previousClose'] as num?)?.toDouble(),
      open: (json['open'] as num?)?.toDouble(),
      dayHigh: (json['dayHigh'] as num?)?.toDouble(),
      dayLow: (json['dayLow'] as num?)?.toDouble(),
      week52High: (json['week52High'] as num?)?.toDouble(),
      week52Low: (json['week52Low'] as num?)?.toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      lastUpdatedAt: json['lastUpdatedAt'] as String?,
    );
  }
}

class VolumeInfo {
  final int current;
  final int? average10d;
  final int? average3m;

  VolumeInfo({required this.current, this.average10d, this.average3m});

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
  final double changePercent;

  RelatedInstrument({
    required this.id,
    required this.symbol,
    required this.name,
    required this.changePercent,
  });

  factory RelatedInstrument.fromJson(Map<String, dynamic> json) {
    return RelatedInstrument(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      changePercent: (json['changePercent'] as num).toDouble(),
    );
  }
}
