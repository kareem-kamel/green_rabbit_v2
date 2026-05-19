import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository(this._apiClient);

  String get _endpoint => AppConstants.newsEndpoint;

  // THIS NAME MUST MATCH THE CUBIT CALL
  Future<List<NewsArticle>> fetchNewsFeed() async {
    try {
      final response = await _apiClient.dio.get(_endpoint);

      if (response.statusCode == 200) {
        final decodedData = response.data;
        
        // Match the structure from your example data
        if (decodedData['success'] == true && decodedData.containsKey('data')) {
           final newsData = decodedData['data']['news'];
           if (newsData != null && newsData.containsKey('articles')) {
             final List articlesJson = newsData['articles'];
             return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
           }
        }
        return [];
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  Future<List<NewsArticle>> fetchRelatedNews(String id) async {
    try {
      // Using RESTful pattern: {endpoint}/{id}/related
      final url = '$_endpoint/$id/related';
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200) {
        final decodedData = response.data;
        
        if (decodedData['success'] == true && decodedData.containsKey('data')) {
          final data = decodedData['data'];
          // Look for 'related_articles' specifically for this endpoint
          final List articlesJson = data['related_articles'] ?? [];
          return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  Future<NewsArticle?> fetchArticleDetail(String id) async {
    try {
      final url = '$_endpoint/$id';
      final response = await _apiClient.dio.get(url);
      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData['success'] == true && decodedData['data'] != null) {
          final articleData = decodedData['data']['article'];
          if (articleData != null) {
            return NewsArticle.fromJson(articleData);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching article detail: $e');
      return null;
    }
  }

  Future<bool> toggleFavorite(String id, bool isAdd) async {
    try {
      final response = isAdd 
          ? await _apiClient.dio.post('/news/favorites', data: {'articleId': id})
          : await _apiClient.dio.delete('/news/favorites/$id');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error toggling favorite: $e');
      // If the above endpoints fail, fall back to the old endpoint format just in case
      try {
        final fallbackUrl = '$_endpoint/$id/favorite';
        final response = isAdd 
            ? await _apiClient.dio.post(fallbackUrl)
            : await _apiClient.dio.delete(fallbackUrl);
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (fallbackErr) {
        print('Fallback toggle favorite also failed: $fallbackErr');
        return false;
      }
    }
  }

  Future<List<NewsArticle>> fetchFavoriteArticles() async {
    try {
      final url = '/news/favorites';
      final response = await _apiClient.dio.get(url);
      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData['success'] == true && decodedData['data'] != null) {
          final List favoritesJson = decodedData['data']['favorites'] ?? [];
          return favoritesJson.map((json) => NewsArticle.fromJson(json['article'])).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<List<CommentModel>> fetchComments(String targetId, String type) async {
    try {
      final url = '/comments';
      print('DEBUG: fetchComments requested with entityId=$targetId, entityType=$type');
      final response = await _apiClient.dio.get(url, queryParameters: {
        'entityType': type,
        'entityId': targetId,
      });

      if (response.statusCode == 200) {
        final decodedData = response.data;
        List<dynamic>? commentsList;
        
        if (decodedData['success'] == true && decodedData['data'] != null) {
          final data = decodedData['data'];
          if (data is List) {
            commentsList = data;
          } else if (data is Map) {
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

  Future<bool> postComment(String targetId, String type, String text) async {
    try {
      final url = '/comments';
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
