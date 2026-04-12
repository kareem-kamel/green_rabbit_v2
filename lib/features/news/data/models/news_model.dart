class NewsArticle {
  final String id;
  final String title;
  final String snippet;
  final String thumbImage;
  final String smallImage;
  final String largeImage;
  final String sourceName;
  final String sourceLogo;
  final String publishedAt;
  final String timeAgo;
  final int commentCount;
  final bool isBookmarked;
  final List<RelatedSymbol> relatedSymbols;
  final List<RelatedAnalysis> relatedAnalysis;

  NewsArticle({
    required this.id,
    required this.title,
    required this.snippet,
    required this.thumbImage,
    required this.smallImage,
    required this.largeImage,
    required this.sourceName,
    required this.sourceLogo,
    required this.publishedAt,
    required this.timeAgo,
    required this.commentCount,
    required this.isBookmarked,
    required this.relatedSymbols,
    required this.relatedAnalysis,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      thumbImage: (json['images']?['thumb'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      smallImage: (json['images']?['small'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      largeImage: (json['images']?['large'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      sourceName: (json['source'] is Map ? json['source']['name'] : json['source'])?.toString() ?? 'Unknown',
      sourceLogo: (json['source'] is Map ? json['source']['logo_url'] : '')?.toString().replaceAll('`', '').trim() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      commentCount: json['comment_count'] ?? 0,
      isBookmarked: json['is_bookmarked'] ?? json['is_favorited'] ?? false,
      relatedSymbols: (json['related_symbols'] as List? ?? [])
          .map((s) => RelatedSymbol.fromJson(s))
          .toList(),
      relatedAnalysis: (json['related_analysis'] as List? ?? [])
          .map((a) => RelatedAnalysis.fromJson(a))
          .toList(),
    );
  }
}

class RelatedAnalysis {
  final String firm;
  final String text;

  RelatedAnalysis({required this.firm, required this.text});

  factory RelatedAnalysis.fromJson(Map<String, dynamic> json) {
    return RelatedAnalysis(
      firm: json['firm']?.toString() ?? 'Unknown Firm',
      text: json['text']?.toString() ?? '',
    );
  }
}

class RelatedSymbol {
  final String symbol;
  final double changePercent;

  RelatedSymbol({
    required this.symbol,
    required this.changePercent,
  });

  factory RelatedSymbol.fromJson(Map<String, dynamic> json) {
    return RelatedSymbol(
      symbol: json['symbol']?.toString() ?? '',
      changePercent: (json['change_percent'] ?? 0.0).toDouble(),
    );
  }
}
