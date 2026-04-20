import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository(this._apiClient);

  Future<List<NewsArticle>> fetchNewsFeed() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.marketNews);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = response.data;
        
        // Structure based on standard market API: { success: true, data: { news: { articles: [...] } } }
        if (decodedData.containsKey('data')) {
           final newsData = decodedData['data']['news'] ?? decodedData['data'];
           final List articlesJson = newsData['articles'] ?? [];
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
}