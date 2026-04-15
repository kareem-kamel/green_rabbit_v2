import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository(this._apiClient);

  String get _endpoint => dotenv.get('NEWS_ENDPOINT');

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
          return NewsArticle.fromJson(decodedData['data']);
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
      final url = '$_endpoint/$id/favorite';

      final response = isAdd 
          ? await _apiClient.dio.post(url)
          : await _apiClient.dio.delete(url);

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<List<NewsArticle>> fetchFavoriteArticles() async {
    try {
      final url = '$_endpoint/favorites';
      final response = await _apiClient.dio.get(url);
      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData['success'] == true && decodedData['data'] != null) {
          final List articlesJson = decodedData['data']['articles'] ?? [];
          return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }
}
