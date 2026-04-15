import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/news/data/models/news_model.dart';

class NewsRepository {
  String get _url => dotenv.get('BASE_URL') + dotenv.get('NEWS_ENDPOINT');
  String get _token => dotenv.get('API_TOKEN');

  // THIS NAME MUST MATCH THE CUBIT CALL
  Future<List<NewsArticle>> fetchNewsFeed() async {
    try {
      final response = await http.get(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-Pinggy-No-Screen': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        
        // This part depends on your APIdog JSON structure
        if (decodedData.containsKey('data')) {
           final List articlesJson = decodedData['data']['news']['articles'];
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