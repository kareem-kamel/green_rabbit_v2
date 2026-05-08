import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';

  static const String baseUrl =
      "https://virtuous-cooperation-production-6420.up.railway.app/api";

  // Base URL

  // API Token (Temporary)
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJmcmVlIiwibGFuZyI6ImVuIiwidHYiOjEsImlhdCI6MTc3NjIxMjE4MiwiZXhwIjoxNzc2MjE1NzgyfQ.2TYV_VMZ9yZeMfT5KHKHtkhUZRqp4lQFU9hHsK7mUWo';

  // Endpoints
  static const String newsEndpoint = '/news';
  static const String relatedNewsEndpoint = '/news/related';
  static const String aiSummarizeEndpoint = '/ai/summarize';
  static const String aiUsageEndpoint = '/ai/usage';
  static const String aiChatConversationsEndpoint = '/ai/chat/conversations';
  static const String alertsEndpoint = '/alerts';

  // Auth Endpoints
  static const String register = "/auth/register";
  static const String verifyEmail = "/auth/verify-email";
  static const String login = "/auth/login";
  static const String forgotPassword = "/auth/forget-password";
  static const String resetPassword = "/auth/reset-password";
  static const String changePassword = "/auth/change-password";

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
