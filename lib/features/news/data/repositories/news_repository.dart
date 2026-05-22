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

    try {
      print('DEBUG: fetchRelatedNews GET $url query=$queryParameters');
      final response = await _apiClient.dio.get(
        url,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      print('DEBUG: fetchRelatedNews status=${response.statusCode}');
      if (response.statusCode != 200) return [];

      final decodedData = response.data;
      if (decodedData is! Map<String, dynamic> || decodedData['success'] != true) {
        return [];
      }

      final data = decodedData['data'];
      if (data is Map<String, dynamic>) {
        final list = data['related_articles'] ?? data['related_news'] ?? data['articles'] ?? data['relatedArticles'];
        return _parseRelatedArticlesList(list);
      }
      if (data is List) {
        return _parseRelatedArticlesList(data);
      }
    } catch (e) {
      print('DEBUG: _fetchRelatedOnce error: $e');
    }
    return [];
  }

  Future<List<NewsArticle>> fetchRelatedNews(String id, {String? type}) async {
    try {
      // 1. Try with the provided type first
      if (type != null && type.isNotEmpty) {
        final articles = await _fetchRelatedOnce(id, type: type);
        if (articles.isNotEmpty) return articles;
      }

      // 2. Try without type parameter
      final genericArticles = await _fetchRelatedOnce(id);
      if (genericArticles.isNotEmpty) return genericArticles;

      // 3. Fallback: try other types
      for (final t in ['stock', 'crypto', 'forex']) {
        if (t == type) continue;
        final articles = await _fetchRelatedOnce(id, type: t);
        if (articles.isNotEmpty) return articles;
      }

      return [];
    } catch (e) {
      print('DEBUG: fetchRelatedNews error: $e');
      return [];
    }
  }

  Future<NewsArticle?> _fetchArticleDetailOnce(String id, {String? type}) async {
    try {
      final url = AppConstants.newsDetailEndpoint(id);
      final queryParameters = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type;
      }

      print('DEBUG: Calling fetchArticleDetail endpoint: $url query=$queryParameters');
      final response = await _apiClient.dio.get(
        url,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      print('DEBUG: fetchArticleDetail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true && decodedData['data'] != null) {
          return NewsArticle.fromJson(Map<String, dynamic>.from(decodedData['data']));
        }
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('DEBUG: fetchArticleDetail error status: ${e.response?.statusCode}');
      }
      print('DEBUG: _fetchArticleDetailOnce error: $e');
      return null;
    }
  }

  Future<NewsArticle?> fetchArticleDetail(String id, {String? type}) async {
    try {
      // 1. Try with the provided type first
      if (type != null && type.isNotEmpty) {
        final article = await _fetchArticleDetailOnce(id, type: type);
        if (article != null) return article;
      }

      // 2. Try without type parameter
      final genericArticle = await _fetchArticleDetailOnce(id);
      if (genericArticle != null) return genericArticle;

      // 3. Fallback: try other types
      for (final t in ['stock', 'crypto', 'forex']) {
        if (t == type) continue;
        final article = await _fetchArticleDetailOnce(id, type: t);
        if (article != null) return article;
      }

      return null;
    } catch (e) {
      print('DEBUG: fetchArticleDetail error: $e');
      return null;
    }
  }

  String _getSanitizedType(NewsArticle article) {
    // The backend expects specific types: "stock" | "crypto" | "forex"
    String sanitizedType = article.type.toLowerCase();
    if (sanitizedType != 'stock' && sanitizedType != 'crypto' && sanitizedType != 'forex') {
      // Default to crypto if it's from a crypto source or has crypto tickers, otherwise stock
      if (article.sourceName.toLowerCase().contains('coin') ||
          article.categories.any((c) =>
              c.toLowerCase().contains('crypto') ||
              c.toLowerCase().contains('bitcoin'))) {
        sanitizedType = 'crypto';
      } else {
        sanitizedType = 'stock';
      }
    }
    return sanitizedType;
  }

  Future<bool> toggleFavorite(NewsArticle article, bool isAdd) async {
    try {
      final url = AppConstants.newsFavoriteEndpoint(article.id);
      final sanitizedType = _getSanitizedType(article);

      print('DEBUG: toggleFavorite - ID: ${article.id}, isAdd: $isAdd, type: $sanitizedType');

      final Map<String, dynamic> body = {
        ...article.toJson(),
        'type': sanitizedType,
        'articleId': article.id,
      };

      // Try sending 'type' in both query params and body to satisfy strict validation
      final queryParams = {'type': sanitizedType};

      final response = isAdd 
          ? await _apiClient.dio.post(url, data: body, queryParameters: queryParams)
          : await _apiClient.dio.delete(url, queryParameters: queryParams);

      print('DEBUG: toggleFavorite status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        final errorData = e.response?.data;
        print('DEBUG: Favorite failed. Status: ${e.response?.statusCode}, Error: $errorData');
        
        // Final fallback: try empty body with query param if validation still fails
        if (isAdd && e.response?.statusCode == 400) {
          try {
            print('DEBUG: toggleFavorite retry - Sending empty body');
            final type = article.type.toLowerCase();
            final qp = (type == 'stock' || type == 'crypto' || type == 'forex') ? {'type': type} : {'type': 'stock'};
            final response2 = await _apiClient.dio.post(AppConstants.newsFavoriteEndpoint(article.id), data: {}, queryParameters: qp);
            return response2.statusCode == 200 || response2.statusCode == 201;
          } catch (e2) {
            print('DEBUG: Empty body retry failed: $e2');
          }
        }
      }
      return false;
    }
  }

  Future<List<NewsArticle>> fetchFavoriteArticles({int page = 1, int limit = 20}) async {
    try {
      final List<NewsArticle> allFavorites = [];
      final Set<String> seenIds = {};

      for (final type in ['stock', 'crypto', 'forex']) {
        try {
          final response = await _apiClient.dio.get(
            AppConstants.newsFavoritesListEndpoint,
            queryParameters: {'page': page, 'limit': limit, 'type': type},
          );

          if (response.statusCode == 200) {
            final data = response.data;
            if (data['success'] == true && data['data'] != null) {
              final List favs = data['data']['favorites'] ?? data['data']['articles'] ?? [];
              for (final f in favs) {
                final artJson = f['article'] ?? f;
                final art = NewsArticle.fromJson(Map<String, dynamic>.from(artJson)).copyWith(isBookmarked: true);
                if (!seenIds.contains(art.id)) {
                  seenIds.add(art.id);
                  allFavorites.add(art);
                }
              }
            }
          }
        } catch (e) {
          print('DEBUG: fetchFavorites error for $type: $e');
        }
      }
      return allFavorites;
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<List<CommentModel>> fetchComments(NewsArticle article, String type) async {
    try {
      final url = '/comments';
      final String targetId = article.id;
      // Force "news_article" as per your CURL example
      final String entityType = "news_article";

      print('DEBUG: fetchComments - START');
      print('DEBUG: URL: $url');
      print('DEBUG: entityType: $entityType');
      print('DEBUG: entityId: $targetId');

      final response = await _apiClient.dio.get(
        url,
        queryParameters: {
          'entityType': entityType,
          'entityId': targetId,
        },
        data: {
          'entityType': entityType,
          'entityId': targetId,
        },
        options: Options(
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      print('DEBUG: fetchComments - Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true) {
          final List list = decodedData['data'] is List ? decodedData['data'] : (decodedData['data']?['comments'] ?? []);
          return list.map((c) => CommentModel.fromJson(Map<String, dynamic>.from(c))).toList();
        }
      } else if (response.statusCode == 404) {
        print('DEBUG: fetchComments - 404 Entity Not Found (No comments yet for $entityType $targetId)');
        return [];
      }
      return [];
    } catch (e) {
      print('DEBUG: fetchComments error: $e');
      return [];
    }
  }

  Future<bool> postComment(NewsArticle article, String type, String text) async {
    try {
      final url = '/comments';
      final String targetId = article.id;
      // Force "news_article" as per your CURL example
      final String entityType = "news_article";

      print('DEBUG: postComment - START');
      print('DEBUG: Payload: {entityType: $entityType, entityId: $targetId, content: $text}');

      final response = await _apiClient.dio.post(url, data: {
        'entityType': entityType,
        'entityId': targetId,
        'content': text,
      });

      print('DEBUG: postComment - Response Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('DEBUG: postComment error: $e');
      if (e is DioException) {
        print('DEBUG: Dio Error Status: ${e.response?.statusCode}');
        print('DEBUG: Dio Error Data: ${e.response?.data}');
      }
      return false;
    }
  }
}
