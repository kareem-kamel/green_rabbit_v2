import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';
  static String get apiBaseUrl => dotenv.get('BASE_URL');
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';
  static const String register = "/api/auth/register";
  static const String verifyEmail = "/api/auth/verify-email";
  static const String login = "/api/auth/login";

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
