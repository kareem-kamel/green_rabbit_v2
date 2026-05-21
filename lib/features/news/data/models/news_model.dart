class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String type;
  final String content;
  final String contentHtml;
  final String imageUrl;
  final String imageCaption;
  final String sourceName;
  final String sourceId;
  final String sourceLogo;
  final String authorName;
  final String authorAvatar;
  final List<String> categories;
  final List<String> tags;
  final String publishedAt;
  final String updatedAt;
  final String timeAgo;
  final int commentCount;
  final bool isBookmarked;
  final String url;
  final String sentiment;
  final double relevanceScore;
  final List<String> tickers;
  final int readTimeMinutes;
  final List<NewsArticle> relatedNews;
  final List<NewsArticle> analysisOpinions;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.type = '',
    this.content = '',
    this.contentHtml = '',
    required this.imageUrl,
    this.imageCaption = '',
    required this.sourceName,
    this.sourceId = '',
    this.sourceLogo = '',
    this.authorName = '',
    this.authorAvatar = '',
    this.categories = const [],
    this.tags = const [],
    required this.publishedAt,
    this.updatedAt = '',
    this.timeAgo = '',
    this.commentCount = 0,
    required this.isBookmarked,
    required this.url,
    this.sentiment = '',
    this.relevanceScore = 0.0,
    this.tickers = const [],
    this.readTimeMinutes = 0,
    this.relatedNews = const [],
    this.analysisOpinions = const [],
  });

  // Keep these for backward compatibility if needed in UI
  String get snippet => summary;
  String get thumbImage => imageUrl;
  String get smallImage => imageUrl;
  String get largeImage => imageUrl;
  String get category => categories.isNotEmpty ? categories.first : '';
  List<RelatedSymbol> get relatedSymbols => tickers.map((t) => RelatedSymbol(symbol: t, changePercent: 0.0)).toList();

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    // Handle nested article in detail response
    final articleData = json.containsKey('article') ? json['article'] : json;
    
    String articleType = articleData['type']?.toString() ?? '';
    final relatedSymbols = articleData['related_symbols'] as List?;
    if (relatedSymbols != null && relatedSymbols.isNotEmpty) {
      final first = relatedSymbols.first;
      if (first is Map && first['type'] != null) {
        articleType = first['type'].toString();
      }
    }

    return NewsArticle(
      id: articleData['id']?.toString() ?? '',
      title: articleData['title']?.toString() ?? '',
      summary: (articleData['summary'] ?? articleData['snippet'])?.toString() ?? '',
      type: articleType,
      content: articleData['content']?.toString() ?? '',
      contentHtml: articleData['content_html']?.toString() ?? '',
      imageUrl: (articleData['imageUrl'] ?? articleData['image_url'] ?? 
                 articleData['images']?['large'] ?? articleData['images']?['small'] ?? 
                 articleData['images']?['thumb'] ?? '')?.toString().replaceAll('`', '').trim() ?? '',
      imageCaption: articleData['image_caption']?.toString() ?? '',
      sourceName: (articleData['source'] is Map ? articleData['source']['name'] : articleData['source'])?.toString() ?? 'Unknown',
      sourceId: (articleData['source'] is Map ? articleData['source']['id'] : '')?.toString() ?? '',
      sourceLogo: (articleData['source'] is Map ? articleData['source']['logo_url'] : '')?.toString().replaceAll('`', '').trim() ?? '',
      authorName: (articleData['author_name'] ?? (articleData['author'] is Map ? articleData['author']['name'] : articleData['author']))?.toString() ?? '',
      authorAvatar: (articleData['author'] is Map ? articleData['author']['avatar_url'] : '')?.toString() ?? '',
      categories: (articleData['categories'] as List? ?? (articleData['category'] != null ? [articleData['category']] : [])).map((e) => e.toString()).toList(),
      tags: (articleData['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      publishedAt: articleData['publishedAt'] ?? articleData['published_at']?.toString() ?? '',
      updatedAt: articleData['updated_at']?.toString() ?? '',
      timeAgo: articleData['time_ago']?.toString() ?? '',
      commentCount: articleData['comment_count'] ?? 0,
      isBookmarked: articleData['is_bookmarked'] ?? articleData['is_favorited'] ?? false,
      url: (articleData['url'] ?? articleData['external_url'] ?? articleData['link'])?.toString() ?? '',
      sentiment: articleData['sentiment']?.toString() ?? '',
      relevanceScore: (articleData['relevanceScore'] ?? articleData['relevance_score'] ?? 0.0).toDouble(),
      tickers: (articleData['tickers'] as List? ?? articleData['related_symbols'] as List? ?? []).map((e) => e.toString()).toList(),
      readTimeMinutes: articleData['readTimeMinutes'] ?? articleData['read_time_minutes'] ?? articleData['reading_time_minutes'] ?? 0,
      relatedNews: (json['related_news'] as List? ?? json['related_articles'] as List? ?? [])
          .map((n) => NewsArticle.fromJson(Map<String, dynamic>.from(n)))
          .toList(),
      analysisOpinions: (json['analysis_opinions'] as List? ?? [])
          .map((a) => NewsArticle.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
    );
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? type,
    String? content,
    String? contentHtml,
    String? imageUrl,
    String? imageCaption,
    String? sourceName,
    String? sourceId,
    String? sourceLogo,
    String? authorName,
    String? authorAvatar,
    List<String>? categories,
    List<String>? tags,
    String? publishedAt,
    String? updatedAt,
    String? timeAgo,
    int? commentCount,
    bool? isBookmarked,
    String? url,
    String? sentiment,
    double? relevanceScore,
    List<String>? tickers,
    int? readTimeMinutes,
    List<NewsArticle>? relatedNews,
    List<NewsArticle>? analysisOpinions,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      content: content ?? this.content,
      contentHtml: contentHtml ?? this.contentHtml,
      imageUrl: imageUrl ?? this.imageUrl,
      imageCaption: imageCaption ?? this.imageCaption,
      sourceName: sourceName ?? this.sourceName,
      sourceId: sourceId ?? this.sourceId,
      sourceLogo: sourceLogo ?? this.sourceLogo,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeAgo: timeAgo ?? this.timeAgo,
      commentCount: commentCount ?? this.commentCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      url: url ?? this.url,
      sentiment: sentiment ?? this.sentiment,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      tickers: tickers ?? this.tickers,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      relatedNews: relatedNews ?? this.relatedNews,
      analysisOpinions: analysisOpinions ?? this.analysisOpinions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'type': type,
      'content': content,
      'content_html': contentHtml,
      'imageUrl': imageUrl,
      'image_caption': imageCaption,
      'source': {
        'name': sourceName,
        'id': sourceId,
        'logo_url': sourceLogo,
      },
      'author': {
        'name': authorName,
        'avatar_url': authorAvatar,
      },
      'categories': categories,
      'tags': tags,
      'publishedAt': publishedAt,
      'updated_at': updatedAt,
      'time_ago': timeAgo,
      'comment_count': commentCount,
      'is_bookmarked': isBookmarked,
      'url': url,
      'sentiment': sentiment,
      'relevanceScore': relevanceScore,
      'tickers': tickers,
      'readTimeMinutes': readTimeMinutes,
    };
  }
}

class NewsResponse {
  final List<NewsArticle> articles;
  final NewsMeta? meta;

  NewsResponse({required this.articles, this.meta});

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final articlesList = (data['articles'] as List? ?? [])
        .map((a) => NewsArticle.fromJson(Map<String, dynamic>.from(a)))
        .toList();
    final meta = json['meta'] != null ? NewsMeta.fromJson(Map<String, dynamic>.from(json['meta'])) : null;
    return NewsResponse(articles: articlesList, meta: meta);
  }
}

class NewsMeta {
  final int page;
  final int limit;
  final bool hasNext;
  final bool hasPrevious;
  final int totalPages;

  NewsMeta({
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.hasPrevious,
    required this.totalPages,
  });

  factory NewsMeta.fromJson(Map<String, dynamic> json) {
    return NewsMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class RelatedAnalysis {
  final String id;
  final String title;
  final String snippet;
  final String authorName;
  final String authorAvatar;
  final String sourceName;
  final String sourceLogo;
  final String publishedAt;
  final String timeAgo;
  final List<RelatedSymbol> relatedSymbols;

  RelatedAnalysis({
    required this.id,
    required this.title,
    required this.snippet,
    required this.authorName,
    required this.authorAvatar,
    required this.sourceName,
    required this.sourceLogo,
    required this.publishedAt,
    required this.timeAgo,
    required this.relatedSymbols,
  });

  factory RelatedAnalysis.fromJson(Map<String, dynamic> json) {
    return RelatedAnalysis(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      authorName: (json['author'] is Map ? json['author']['name'] : null)?.toString() ?? '',
      authorAvatar: (json['author'] is Map ? json['author']['avatar_url'] : null)?.toString() ?? '',
      sourceName: (json['source'] is Map ? json['source']['name'] : json['source'])?.toString() ?? 'Unknown',
      sourceLogo: (json['source'] is Map ? json['source']['logo_url'] : '')?.toString().replaceAll('`', '').trim() ?? '',
      publishedAt: json['publishedAt'] ?? json['published_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      relatedSymbols: (json['related_symbols'] as List? ?? json['tickers'] as List? ?? [])
          .map((s) => RelatedSymbol.fromJson(s))
          .toList(),
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

  factory RelatedSymbol.fromJson(dynamic json) {
    if (json is String) {
      return RelatedSymbol(symbol: json, changePercent: 0.0);
    }
    return RelatedSymbol(
      symbol: json['symbol']?.toString() ?? '',
      changePercent: (json['change_percent'] ?? 0.0).toDouble(),
    );
  }
}

class CommentModel {
  final String name;
  final String text;
  final String time;

  CommentModel({required this.name, required this.text, required this.time});
}

