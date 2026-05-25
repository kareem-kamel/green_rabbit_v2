import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

class NewsCacheService {
  final SharedPreferences _prefs;
  static const String _favoritesCacheKey = 'cached_favorite_news';

  NewsCacheService(this._prefs);

  Future<void> cacheFavorites(List<NewsArticle> articles) async {
    try {
      final String encodedData = jsonEncode(
        articles.map((article) => article.toJson()).toList(),
      );
      await _prefs.setString(_favoritesCacheKey, encodedData);
    } catch (e) {
      print('DEBUG: Error caching favorites: $e');
    }
  }

  List<NewsArticle> getCachedFavorites() {
    try {
      final String? encodedData = _prefs.getString(_favoritesCacheKey);
      if (encodedData == null || encodedData.isEmpty) return [];

      final List<dynamic> decodedList = jsonDecode(encodedData);
      return decodedList
          .map((item) => NewsArticle.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('DEBUG: Error reading cached favorites: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_favoritesCacheKey);
  }
}
