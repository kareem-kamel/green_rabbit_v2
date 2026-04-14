class AppConstants {
  AppConstants._();

  static const String appName = 'Green Rabbit';
  static const String baseUrl = "https://virtuous-cooperation-production-6420.up.railway.app/api";
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserStatus = 'user_status';
  static const String keyThemeMode = 'theme_mode';
  static const String register = "/auth/register";
  static const String verifyEmail = "/auth/verify-email";
  static const String login = "/auth/login";

  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
