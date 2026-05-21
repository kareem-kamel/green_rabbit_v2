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

  Future<List<NewsArticle>> fetchRelatedNews(String id) async {
    try {
      final url = AppConstants.newsRelatedEndpoint(id);
      print('DEBUG: Calling fetchRelatedNews endpoint: $url');
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true && decodedData['data'] != null) {
          final List articlesJson = decodedData['data']['related_articles'] ?? [];
          return articlesJson.map((json) => NewsArticle.fromJson(Map<String, dynamic>.from(json))).toList();
        }
      }
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

  /// Backend POST /news/{id}/favorite requires `type`: stock | crypto | forex.
  String _resolveFavoriteInstrumentType(NewsArticle article) {
    const allowed = {'stock', 'crypto', 'forex'};

    String normalize(String raw) {
      final t = raw.trim().toLowerCase();
      if (t == 'stocks') return 'stock';
      if (allowed.contains(t)) return t;
      if (t.startsWith('stock:') || t.contains('stock')) return 'stock';
      if (t.startsWith('crypto:') || t.contains('crypto')) return 'crypto';
      if (t.startsWith('forex:') || t.contains('forex')) return 'forex';
      return '';
    }

    final fromArticle = normalize(article.type);
    if (fromArticle.isNotEmpty) return fromArticle;

    for (final ticker in article.tickers) {
      final symbol = ticker.trim().toUpperCase();
      if (symbol.contains('/')) return 'forex';
      const cryptoSymbols = {
        'BTC', 'ETH', 'BNB', 'SOL', 'XRP', 'ADA', 'DOGE', 'DOT', 'LTC',
      };
      final base = symbol.split('-').first.split('/').first;
      if (cryptoSymbols.contains(base)) {
        return 'crypto';
      }
    }

    final haystack = [
      article.sourceName,
      ...article.categories,
      ...article.tags,
    ].join(' ').toLowerCase();

    if (haystack.contains('forex') || haystack.contains('currency')) {
      return 'forex';
    }
    if (haystack.contains('crypto') ||
        haystack.contains('bitcoin') ||
        haystack.contains('coin')) {
      return 'crypto';
    }

    return 'stock';
  }

  Future<bool> toggleFavorite(NewsArticle article, bool isAdd) async {
    try {
      final url = AppConstants.newsFavoriteEndpoint(article.id);
      final instrumentType = _resolveFavoriteInstrumentType(article);
      print(
        'DEBUG: toggleFavorite - ID: ${article.id}, isAdd: $isAdd, '
        'article.type: "${article.type}", resolved: $instrumentType',
      );

      // Send only what the backend validates — not the full article payload.
      final Map<String, dynamic> body = {'type': instrumentType};

      final response = isAdd
          ? await _apiClient.dio.post(url, data: body)
          : await _apiClient.dio.delete(url);

      print('DEBUG: toggleFavorite status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        final errorData = e.response?.data;
        print(
          'DEBUG: Favorite failed. Status: ${e.response?.statusCode}, '
          'Error: $errorData',
        );

        if (isAdd && e.response?.statusCode == 400) {
          for (final fallbackType in ['stock', 'crypto', 'forex']) {
            try {
              print('DEBUG: toggleFavorite retry with type=$fallbackType');
              final response2 = await _apiClient.dio.post(
                AppConstants.newsFavoriteEndpoint(article.id),
                data: {'type': fallbackType},
              );
              if (response2.statusCode == 200 || response2.statusCode == 201) {
                return true;
              }
            } catch (_) {}
          }
        }
      }
      return false;
    }
  }

  Future<List<NewsArticle>> fetchFavoriteArticles({int page = 1, int limit = 20}) async {
    try {
      final url = AppConstants.newsFavoritesListEndpoint;
      final response = await _apiClient.dio.get(url, queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true && decodedData['data'] != null) {
          final List favoritesJson = decodedData['data']['favorites'] ?? [];
          return favoritesJson.map((json) => NewsArticle.fromJson(Map<String, dynamic>.from(json['article']))).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
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
