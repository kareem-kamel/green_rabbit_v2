import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';
  
  static const String baseUrl = 'https://virtuous-cooperation-production-6420.up.railway.app/api/';
  
  static String get apiBaseUrl => baseUrl;
  
  static bool get useMockApi => false;
  static String? get apiToken => dotenv.get('API_TOKEN', fallback: '');
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';
  
  // API Endpoints
  // Auth
  static const String register = "auth/register";
  static const String verifyEmail = "auth/verify-email";
  static const String login = "auth/login";
  static const String logout = "auth/logout";

  // Market
  static String marketOverview(String type) => "market/overview/$type";
  static const String marketTrending = "market/trending";
  static const String marketState = "market/state";
  static String instrumentDetails(String id) => "market/instruments/$id";
  static const String marketStream = "market/stream";
  // Sub-endpoints for instruments
  static String instrumentChart(String id) => "market/instruments/$id/chart";
  static String instrumentStats(String id) => "market/instruments/$id/stats";
  static String instrumentNews(String id) => "market/instruments/$id/news";
  static const String marketNews = "market/news";

  // Profile / User
  static const String userMe = "users/me";
  static const String userAvatar = "users/me/avatar";
  static const String userPreferences = "users/me/preferences";
  static const String userOnboarding = "users/me/onboarding";
  static const String userFcmToken = "users/me/fcm-token";

  // Watchlist
  static const String watchlists = "watchlists";
  static String watchlistDetail(String id) => "watchlists/$id";
  static String watchlistInstruments(String id) => "watchlists/$id/instruments";
  static String watchlistRemoveInstrument(String wlId, String instId) => "watchlists/$wlId/instruments/$instId";
  static String watchlistReorder(String id) => "watchlists/$id/reorder";

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
