import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/news_model.dart';

class NewsRepository {
  final _storage = const FlutterSecureStorage();

  // Get values directly in the method to ensure they are fresh
  String get _token => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJmcmVlIiwibGFuZyI6ImVuIiwidHYiOjEsImlhdCI6MTc3NjIxMDYzMSwiZXhwIjoxNzc2MjE0MjMxfQ.2Ad77By0DH_1FEvBcJZBBE8O';
  String get _baseUrl => dotenv.get('BASE_URL');
  String get _endpoint => dotenv.get('NEWS_ENDPOINT');
  String get _relatedEndpoint => dotenv.get('RELATED_NEWS_ENDPOINT');

  // THIS NAME MUST MATCH THE CUBIT CALL
  Future<List<NewsArticle>> fetchNewsFeed() async {
    try {
      final url = '$_baseUrl$_endpoint';
      print('Fetching news from: $url'); // Debug log

      final headers = {
        'X-Pinggy-No-Screen': 'true',
        'Authorization': 'Bearer $_token',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        print('Response body: ${response.body}'); // Debug log
        
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
      final url = '$_baseUrl$_endpoint/$id/related';
      print('Fetching related news from: $url');

      final headers = {
        'X-Pinggy-No-Screen': 'true',
        'Authorization': 'Bearer $_token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        print('Related news response: ${response.body}'); // Debug log
        
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
      final url = '$_baseUrl$_endpoint/$id';
      final headers = {
        'X-Pinggy-No-Screen': 'true',
        'Authorization': 'Bearer $_token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
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
      final url = '$_baseUrl/news/$id/favorite';
      final headers = {
        'X-Pinggy-No-Screen': 'true',
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

      final response = isAdd 
          ? await http.post(Uri.parse(url), headers: headers)
          : await http.delete(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<List<NewsArticle>> fetchFavoriteArticles() async {
    try {
      final url = '$_baseUrl/news/favorites';
      final headers = {
        'X-Pinggy-No-Screen': 'true',
        'Authorization': 'Bearer $_token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
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