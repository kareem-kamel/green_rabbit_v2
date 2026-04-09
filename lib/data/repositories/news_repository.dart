import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/news/data/models/news_model.dart';

class NewsRepository {
  // Use a placeholder if you don't have the link yet, so it doesn't crash
  final String _url = "https://jsonplaceholder.typicode.com/posts"; 

  // THIS NAME MUST MATCH THE CUBIT CALL
  Future<List<NewsArticle>> fetchNewsFeed() async {
    try {
      final response = await http.get(Uri.parse(_url));

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