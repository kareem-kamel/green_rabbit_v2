import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';
  
  static String get apiBaseUrl {
    String url = dotenv.get('API_BASE_URL', fallback: 'https://virtuous-cooperation-production-6420.up.railway.app/api');
    // Ensure the URL ends with /api/
    if (!url.contains('/api')) {
      url = url.endsWith('/') ? '${url}api' : '$url/api';
    }
    return url.endsWith('/') ? url : '$url/';
  }
  
  static bool get useMockApi => false; // Explicitly disabled for live testing
  static String? get apiToken => dotenv.get('API_TOKEN', fallback: '');
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';
  
  // Routes
  static const String register = "auth/register";
  static const String verifyEmail = "auth/verify-email";
  static const String login = "auth/login";

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
