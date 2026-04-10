class NewsArticle {
  final String id;
  final String title;
  final String snippet;
  final String imageUrl;
  final String sourceName;
  final String timeAgo;
  final int commentCount;

  NewsArticle({
    required this.id,
    required this.title,
    required this.snippet,
    required this.imageUrl,
    required this.sourceName,
    required this.timeAgo,
    required this.commentCount,
  });

  // This function converts the JSON from Apidog into a Flutter Object
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      snippet: json['snippet'] ?? '',
      imageUrl: json['images']['large'] ?? '', // Using the large image
      sourceName: json['source']['name'] ?? 'Unknown',
      timeAgo: json['time_ago'] ?? '',
      commentCount: json['comment_count'] ?? 0,
    );
  }
}