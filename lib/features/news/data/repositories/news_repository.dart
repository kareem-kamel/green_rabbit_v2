import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository(this._apiClient);

  String get _endpoint => AppConstants.newsEndpoint;

  // THIS NAME MUST MATCH THE CUBIT CALL
  Future<List<NewsArticle>> fetchNewsFeed({int page = 1, int limit = 20}) async {
    try {
      print('DEBUG: Calling fetchNewsFeed endpoint: $_endpoint');
      final response = await _apiClient.dio.get(_endpoint, queryParameters: {
        'page': page,
        'limit': limit,
      });
      print('DEBUG: fetchNewsFeed response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true) {
          final newsResponse = NewsResponse.fromJson(decodedData);
          print('DEBUG: fetchNewsFeed successfully loaded ${newsResponse.articles.length} articles');
          return newsResponse.articles;
        }
        return [];
      } else {
        print('DEBUG: fetchNewsFeed server returned error code: ${response.statusCode}');
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print('DEBUG: fetchNewsFeed error: $e');
      throw Exception("Connection Error: $e");
    }
  }

  List<NewsArticle> _parseRelatedArticlesList(dynamic raw) {
    if (raw is! List) return [];
    final articles = <NewsArticle>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        articles.add(NewsArticle.fromJson(Map<String, dynamic>.from(item)));
      } catch (e) {
        print('DEBUG: skip related article parse: $e');
      }
    }
    return articles;
  }

  Future<List<NewsArticle>> _fetchRelatedOnce(String id, {String? type}) async {
    final url = AppConstants.newsRelatedEndpoint(id);
    final queryParameters = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }

    print('DEBUG: fetchRelatedNews GET $url query=$queryParameters');
    final response = await _apiClient.dio.get(
      url,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    print('DEBUG: fetchRelatedNews status=${response.statusCode}');
    if (response.statusCode != 200) {
      print('DEBUG: fetchRelatedNews body=${response.data}');
      return [];
    }

    final decodedData = response.data;
    if (decodedData is! Map<String, dynamic> || decodedData['success'] != true) {
      return [];
    }

    final data = decodedData['data'];
    if (data is Map<String, dynamic>) {
      return _parseRelatedArticlesList(
        data['related_articles'] ?? data['relatedArticles'] ?? data['articles'],
      );
    }
    if (data is List) {
      return _parseRelatedArticlesList(data);
    }
    return [];
  }

  Future<List<NewsArticle>> fetchRelatedNews(
    String id, {
    String? type,
  }) async {
    try {
      for (final instrumentType in _newsTypesToTry(type: type)) {
        final articles = await _fetchRelatedOnce(id, type: instrumentType);
        if (articles.isNotEmpty) {
          print(
            'DEBUG: fetchRelatedNews id=$id type=$instrumentType '
            'count=${articles.length}',
          );
          return articles;
        }
      }

      print('DEBUG: fetchRelatedNews id=$id returned 0 articles');
      return [];
    } catch (e) {
      print('DEBUG: fetchRelatedNews error: $e');
      return [];
    }
  }

  Future<NewsArticle?> fetchArticleDetail(String id) async {
    try {
      final url = AppConstants.newsDetailEndpoint(id);
      print('DEBUG: Calling fetchArticleDetail endpoint: $url');
      final response = await _apiClient.dio.get(url);
      print('DEBUG: fetchArticleDetail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true && decodedData['data'] != null) {
          // The NewsArticle.fromJson handles the nested "article" key
          return NewsArticle.fromJson(Map<String, dynamic>.from(decodedData['data']));
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: fetchArticleDetail error: $e');
      return null;
    }
  }

  static String _normalizeNewsType(String raw) {
    var t = raw.trim().toLowerCase();
    if (t == 'stocks') t = 'stock';
    return t;
  }

  void _addNewsType(List<String> ordered, String? raw, Set<String> allowed) {
    if (raw == null || raw.isEmpty) return;
    final t = _normalizeNewsType(raw);
    if (allowed.contains(t) && !ordered.contains(t)) ordered.add(t);
  }

  /// Best guess when the API omits or mislabels `type` on an article.
  String _inferNewsTypeFromArticle(NewsArticle article) {
    for (final raw in article.tickers) {
      final symbol = raw.trim().toUpperCase();
      if (symbol.contains('/')) return 'forex';
      const crypto = {'BTC', 'ETH', 'BNB', 'SOL', 'XRP', 'ADA', 'DOGE'};
      final base = symbol.split('-').first.split('/').first;
      if (crypto.contains(base)) return 'crypto';
    }

    final text =
        '${article.sourceName} ${article.categories.join(' ')}'.toLowerCase();
    if (text.contains('forex') || text.contains('currency')) return 'forex';
    if (text.contains('crypto') ||
        text.contains('bitcoin') ||
        text.contains('coin')) {
      return 'crypto';
    }
    return 'stock';
  }

  /// Order: explicit/article type first, then inferred, then all providers.
  List<String> _newsTypesToTry({NewsArticle? article, String? type}) {
    final allowed = AppConstants.newsInstrumentTypes.toSet();
    final ordered = <String>[];

    _addNewsType(ordered, type, allowed);
    if (article != null) {
      _addNewsType(ordered, article.type, allowed);
      _addNewsType(ordered, _inferNewsTypeFromArticle(article), allowed);
    }
    for (final t in AppConstants.newsInstrumentTypes) {
      _addNewsType(ordered, t, allowed);
    }
    return ordered;
  }

  bool _shouldRetryFavoriteWithAnotherType(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data?.toString().toLowerCase() ?? '';
    if (status == 400 && body.contains('type')) return true;
    if (status == 503 || body.contains('upstream')) return true;
    return false;
  }

  /// POST/DELETE /news/{id}/favorite — id in path; type as query param (no body).
  Future<bool> toggleFavorite(NewsArticle article, bool isAdd) async {
    final url = AppConstants.newsFavoriteEndpoint(article.id);

    for (final instrumentType in _newsTypesToTry(article: article)) {
      try {
        print(
          'DEBUG: toggleFavorite - ID: ${article.id}, isAdd: $isAdd, '
          'query.type: $instrumentType',
        );
        final queryParameters = {'type': instrumentType};
        final response = isAdd
            ? await _apiClient.dio.post(url, queryParameters: queryParameters)
            : await _apiClient.dio.delete(url, queryParameters: queryParameters);

        print('DEBUG: toggleFavorite status: ${response.statusCode}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['success'] == true) {
            return true;
          }
        }
      } on DioException catch (e) {
        print(
          'DEBUG: Favorite failed (type=$instrumentType). '
          'Status: ${e.response?.statusCode}, Error: ${e.response?.data}',
        );
        if (!_shouldRetryFavoriteWithAnotherType(e)) return false;
      }
    }
    return false;
  }

  NewsArticle? _parseFavoriteEntry(dynamic item) {
    if (item is! Map) return null;
    final fav = Map<String, dynamic>.from(item);

    Map<String, dynamic> articleJson;
    if (fav['article'] is Map) {
      articleJson = Map<String, dynamic>.from(fav['article']);
    } else {
      articleJson = Map<String, dynamic>.from(fav);
      articleJson.remove('favorited_at');
      articleJson.remove('favoritedAt');
      articleJson.remove('created_at');
      articleJson.remove('user_id');
      if (articleJson['article_id'] != null) {
        articleJson['id'] = articleJson['article_id'];
      }
    }

    if (articleJson['id'] == null && articleJson['title'] == null) {
      return null;
    }

    return NewsArticle.fromJson(articleJson).copyWith(isBookmarked: true);
  }

  Future<List<NewsArticle>> _fetchFavoritesForType({
    required String type,
    int page = 1,
    int limit = 20,
  }) async {
    final url = AppConstants.newsFavoritesListEndpoint;
    final response = await _apiClient.dio.get(
      url,
      queryParameters: {'page': page, 'limit': limit, 'type': type},
    );

    if (response.statusCode != 200) return [];

    final decodedData = response.data;
    if (decodedData is! Map<String, dynamic> || decodedData['success'] != true) {
      return [];
    }

    final data = decodedData['data'];
    List<dynamic> favoritesJson = [];
    if (data is Map<String, dynamic>) {
      favoritesJson = data['favorites'] as List? ?? data['articles'] as List? ?? [];
    } else if (data is List) {
      favoritesJson = data;
    }

    final articles = <NewsArticle>[];
    for (final item in favoritesJson) {
      final article = _parseFavoriteEntry(item);
      if (article != null) articles.add(article);
    }
    print('DEBUG: favorites type=$type count=${articles.length}');
    return articles;
  }

  /// GET /news/favorites — backend filters by ?type= (same as favorite POST).
  Future<List<NewsArticle>> fetchFavoriteArticles({int page = 1, int limit = 20}) async {
    try {
      final seenIds = <String>{};
      final merged = <NewsArticle>[];

      for (final type in AppConstants.newsInstrumentTypes) {
        try {
          final batch = await _fetchFavoritesForType(
            type: type,
            page: page,
            limit: limit,
          );
          for (final article in batch) {
            if (seenIds.add(article.id)) merged.add(article);
          }
        } catch (e) {
          print('DEBUG: fetchFavoriteArticles type=$type error: $e');
        }
      }

      print('DEBUG: fetchFavoriteArticles total=${merged.length}');
      return merged;
    } catch (e, stack) {
      print('Error fetching favorites: $e\n$stack');
      return [];
    }
  }

  Future<List<CommentModel>> fetchComments(NewsArticle article, String type) async {
    try {
      final url = '/comments';
      final targetId = article.url.isNotEmpty ? article.url : article.id;
      print('DEBUG: fetchComments requested with entityId=$targetId, entityType=$type');
      final response = await _apiClient.dio.get(url, queryParameters: {
        'entityType': type,
        'entityId': targetId,
      });

      if (response.statusCode == 200) {
        final decodedData = response.data;
        List<dynamic>? commentsList;
        
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true && decodedData['data'] != null) {
          final data = decodedData['data'];
          if (data is List) {
            commentsList = data;
          } else if (data is Map<String, dynamic>) {
            commentsList = data['comments'] as List?;
          }
        }
        
        if (commentsList == null) return [];
        
        return commentsList.map((json) {
          final userObj = json['user'];
          final String name = userObj is Map 
              ? (userObj['fullName'] ?? userObj['name'] ?? 'User') 
              : 'User';
          final String text = json['content'] ?? json['text'] ?? '';
          final String time = json['createdAt'] ?? json['time'] ?? 'Just now';
          
          String displayTime = time;
          try {
            if (time.contains('T') || time.contains('-')) {
              final date = DateTime.parse(time);
              final difference = DateTime.now().difference(date);
              if (difference.inMinutes < 60) {
                displayTime = '${difference.inMinutes} mins ago';
              } else if (difference.inHours < 24) {
                displayTime = '${difference.inHours} hours ago';
              } else {
                displayTime = '${difference.inDays} days ago';
              }
            }
          } catch (_) {}
          
          return CommentModel(
            name: name,
            text: text,
            time: displayTime,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching comments response: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('Error fetching comments: $e');
      }
      return [];
    }
  }

  Future<bool> postComment(NewsArticle article, String type, String text) async {
    try {
      final url = '/comments';
      final targetId = article.url.isNotEmpty ? article.url : article.id;
      print('DEBUG: postComment requested with entityId=$targetId, entityType=$type, content=$text');
      final response = await _apiClient.dio.post(url, data: {
        'entityId': targetId,
        'entityType': type,
        'content': text,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        print('Error posting comment response: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('Error posting comment: $e');
      }
      return false;
    }
  }
}
