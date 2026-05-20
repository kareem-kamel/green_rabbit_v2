class NewsArticle {
  final String id;
  final String title;
  final String snippet;
  final String content;
  final String contentHtml;
  final String thumbImage;
  final String smallImage;
  final String largeImage;
  final String imageCaption;
  final String sourceName;
  final String sourceLogo;
  final String authorName;
  final String authorAvatar;
  final String category;
  final List<String> tags;
  final String publishedAt;
  final String updatedAt;
  final String timeAgo;
  final int commentCount;
  final bool isBookmarked;
  final String url;
  final List<RelatedSymbol> relatedSymbols;
  final List<RelatedAnalysis> relatedAnalysis;
  final List<NewsArticle> relatedNews;

  NewsArticle({
    required this.id,
    required this.title,
    required this.snippet,
    this.content = '',
    this.contentHtml = '',
    required this.thumbImage,
    required this.smallImage,
    required this.largeImage,
    this.imageCaption = '',
    required this.sourceName,
    required this.sourceLogo,
    this.authorName = '',
    this.authorAvatar = '',
    this.category = '',
    this.tags = const [],
    required this.publishedAt,
    this.updatedAt = '',
    required this.timeAgo,
    required this.commentCount,
    required this.isBookmarked,
    required this.url,
    required this.relatedSymbols,
    required this.relatedAnalysis,
    this.relatedNews = const [],
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      contentHtml: json['content_html']?.toString() ?? '',
      thumbImage: (json['images']?['thumb'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      smallImage: (json['images']?['small'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      largeImage: (json['images']?['large'] ?? json['image_url'])?.toString().replaceAll('`', '').trim() ?? '',
      imageCaption: json['image_caption']?.toString() ?? '',
      sourceName: (json['source'] is Map ? json['source']['name'] : json['source'])?.toString() ?? 'Unknown',
      sourceLogo: (json['source'] is Map ? json['source']['logo_url'] : '')?.toString().replaceAll('`', '').trim() ?? '',
      authorName: (json['author_name'] ?? (json['author'] is Map ? json['author']['name'] : null))?.toString() ?? '',
      authorAvatar: (json['author'] is Map ? json['author']['avatar_url'] : '')?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      publishedAt: json['published_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      commentCount: json['comment_count'] ?? 0,
      isBookmarked: json['is_bookmarked'] ?? json['is_favorited'] ?? false,
      url: json['external_url']?.toString() ?? json['url']?.toString() ?? json['link']?.toString() ?? '',
      relatedSymbols: (json['related_symbols'] as List? ?? [])
          .map((s) => RelatedSymbol.fromJson(s))
          .toList(),
      relatedAnalysis: (json['related_analyses'] as List? ?? json['related_analysis'] as List? ?? [])
          .map((a) => RelatedAnalysis.fromJson(a))
          .toList(),
      relatedNews: (json['related_news'] as List? ?? [])
          .map((n) => NewsArticle.fromJson(n))
          .toList(),
    );
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? snippet,
    String? content,
    String? contentHtml,
    String? thumbImage,
    String? smallImage,
    String? largeImage,
    String? imageCaption,
    String? sourceName,
    String? sourceLogo,
    String? authorName,
    String? authorAvatar,
    String? category,
    List<String>? tags,
    String? publishedAt,
    String? updatedAt,
    String? timeAgo,
    int? commentCount,
    bool? isBookmarked,
    String? url,
    List<RelatedSymbol>? relatedSymbols,
    List<RelatedAnalysis>? relatedAnalysis,
    List<NewsArticle>? relatedNews,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      content: content ?? this.content,
      contentHtml: contentHtml ?? this.contentHtml,
      thumbImage: thumbImage ?? this.thumbImage,
      smallImage: smallImage ?? this.smallImage,
      largeImage: largeImage ?? this.largeImage,
      imageCaption: imageCaption ?? this.imageCaption,
      sourceName: sourceName ?? this.sourceName,
      sourceLogo: sourceLogo ?? this.sourceLogo,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeAgo: timeAgo ?? this.timeAgo,
      commentCount: commentCount ?? this.commentCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      url: url ?? this.url,
      relatedSymbols: relatedSymbols ?? this.relatedSymbols,
      relatedAnalysis: relatedAnalysis ?? this.relatedAnalysis,
      relatedNews: relatedNews ?? this.relatedNews,
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
      sourceLogo: (json['source'] is Map ? json['source']['logo_url'] : null)?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      relatedSymbols: (json['related_symbols'] as List? ?? [])
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

