import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';
  
  // Base URL
  static const String apiBaseUrl = 'https://virtuous-cooperation-production-6420.up.railway.app';
  
  // API Token (Temporary)
  static const String apiToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJmcmVlIiwibGFuZyI6ImVuIiwidHYiOjEsImlhdCI6MTc3NjIxMjE4MiwiZXhwIjoxNzc2MjE1NzgyfQ.2TYV_VMZ9yZeMfT5KHKHtkhUZRqp4lQFU9hHsK7mUWo';

  // Endpoints
  static const String newsEndpoint = '/api/news';
  static const String relatedNewsEndpoint = '/api/news/related';
  static const String aiSummarizeEndpoint = '/api/ai/summarize';
  static const String aiUsageEndpoint = '/api/ai/usage';
  static const String aiChatConversationsEndpoint = '/api/ai/chat/conversations';
  static const String alertsEndpoint = '/api/alerts';
  
  // Auth Endpoints
  static const String register = "/api/auth/register";
  static const String verifyEmail = "/api/auth/verify-email";
  static const String login = "/api/auth/login";

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
