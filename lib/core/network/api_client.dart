import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:green_rabbit/core/widgets/no_internet_dialog.dart';
import '../di/injection_container.dart' as di;
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  /// Tracks whether a token refresh is currently in progress.
  /// This is the key flag that prevents race conditions — if multiple
  /// 401s fire at once, only the first one triggers a refresh.
  bool _isRefreshing = false;

  VoidCallback? onUnauthorized;
  Function(int seconds)? onRateLimit;

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage storage,
    required Logger logger,
  }) : _dio = dio,
       _storage = storage,
       _logger = logger {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = '*/*';
    _dio.options.headers['X-Pinggy-No-Screen'] = 'true';

    if (!kIsWeb) {
      _dio.options.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      _dio.options.headers['Connection'] = 'keep-alive';
    }

    // ─── QueuedInterceptorsWrapper ────────────────────────────────────────────
    // Using QueuedInterceptorsWrapper instead of InterceptorsWrapper ensures
    // that interceptor callbacks are executed one at a time (serially).
    // This is critical: if 5 requests all get a 401 simultaneously, they line
    // up here. The first one refreshes the token; the rest wait and then
    // retry with the new token automatically.
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        // ── onRequest ────────────────────────────────────────────────────────
        onRequest: (options, handler) async {
          try {
            // Do NOT attach tokens to auth-related endpoints — these either
            // don't need them or will break if an expired token is sent.
            final isAuthPath =
                options.path.contains('auth/login') ||
                options.path.contains('auth/register') ||
                options.path.contains('auth/verify-email') ||
                options.path.contains(AppConstants.refresh);

            if (!isAuthPath) {
              // Prefer the stored token (post-login). Fall back to the
              // hardcoded AppConstants.apiToken for unauthenticated flows.
              String? token = await _storage.read(
                key: AppConstants.keyAccessToken,
              );

              if (token == null || token.isEmpty) {
                token = AppConstants.apiToken;
              }

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (e) {
            _logger.e('onRequest — error reading token: $e');
          }

          _logger.d('→ ${options.method} ${options.uri}');
          return handler.next(options);
        },

        // ── onResponse ───────────────────────────────────────────────────────
        onResponse: (response, handler) {
          _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },

        // ── onError ──────────────────────────────────────────────────────────
        onError: (DioException e, handler) async {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.error is SocketException ||
              (e.message?.contains('SocketException') ?? false) ||
              (e.error?.toString().contains('SocketException') ?? false)) {
            _logger.w('Network connection issue detected. Mapping to NoInternetFailure.');
            NoInternetDialog.show(globalNavigatorKey.currentContext!);
            final noInternetException = DioException(
              requestOptions: e.requestOptions,
              error: const NoInternetFailure(),
              type: DioExceptionType.connectionError,
              message: "No internet connection. Please try again.",
            );
            return handler.next(noInternetException);
          }

          _logger.e(
            'API Error [${e.response?.statusCode}] for ${e.requestOptions.uri}: ${e.message}',
          );

          final statusCode = e.response?.statusCode;
          final requestPath = e.requestOptions.path;
          final isRefreshRequest = requestPath.contains(AppConstants.refresh);

          if (statusCode == 401 && !isRefreshRequest) {
            // 👇 1. التشيك الذكي: هل التوكن اللي في الستوريدج اتغير عن التوكن اللي فشل؟
            final latestToken = await _storage.read(
              key: AppConstants.keyAccessToken,
            );
            final requestToken = e.requestOptions.headers['Authorization']
                ?.toString()
                .replaceFirst('Bearer ', '');

            if (latestToken != null && latestToken != requestToken) {
              _logger.i(
                'Token was already refreshed by a previous request. Retrying directly...',
              );
              // حط التوكن الجديد اللي ريكويست (أ) جابه، ونفذ الريكويست فوراً بدون ريفريش جديد
              e.requestOptions.headers['Authorization'] = 'Bearer $latestToken';
              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            }

            // ── Race-condition guard ─────────────────────────────────────────
            if (_isRefreshing) {
              _logger.w('Refresh already in progress — forcing logout...');
              await _forceLogout();
              return handler.reject(e);
            }

            _isRefreshing = true;

            try {
              // ── Isolated Dio for the refresh call ──────────────────────────
              // We spin up a brand-new Dio instance with no interceptors so
              // the refresh POST cannot recursively trigger this same error
              // handler. Headers are clean and independent of the main client.
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: AppConstants.apiBaseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': '*/*',
                  },
                ),
              );

              // Read the refresh token from secure storage.
              final refreshToken = await _storage.read(
                key: AppConstants.keyRefreshToken,
              );

              if (refreshToken == null || refreshToken.isEmpty) {
                _logger.w('No refresh token found — forcing logout.');
                await _forceLogout();
                return handler.reject(e);
              }

              _logger.i('Attempting token refresh…');

              final refreshResponse = await refreshDio.post(
                AppConstants.refresh,
                data: {'refreshToken': refreshToken},
              );

              // ── Flexible payload extraction ────────────────────────────────
              // The backend may return tokens at the root level or nested
              // inside a `data` object. We handle both shapes safely.
              //
              // Shape A — root level:
              //   { "accessToken": "...", "refreshToken": "..." }
              //
              // Shape B — nested:
              //   { "data": { "accessToken": "...", "refreshToken": "..." } }
              final responseBody = refreshResponse.data;
              final payload =
                  (responseBody is Map && responseBody['data'] is Map)
                  ? responseBody['data'] as Map<String, dynamic>
                  : responseBody as Map<String, dynamic>;

              final newAccessToken = payload['accessToken'] as String?;
              final newRefreshToken = payload['refreshToken'] as String?;

              if (newAccessToken == null || newAccessToken.isEmpty) {
                _logger.e('Refresh succeeded but accessToken was empty.');
                await _forceLogout();
                return handler.reject(e);
              }

              // ── Persist the fresh tokens ───────────────────────────────────
              await _storage.write(
                key: AppConstants.keyAccessToken,
                value: newAccessToken,
              );

              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await _storage.write(
                  key: AppConstants.keyRefreshToken,
                  value: newRefreshToken,
                );
              }

              _logger.i(
                'Token refresh successful — retrying original request.',
              );

              // ── Retry the original request with the new token ──────────────
              // Clone the original RequestOptions and inject the new header so
              // the retry goes out exactly like the original request but
              // authenticated with the fresh token.
              final retryOptions = e.requestOptions.copyWith(
                headers: {
                  ...e.requestOptions.headers,
                  'Authorization': 'Bearer $newAccessToken',
                },
              );

              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (refreshError) {
              // ── Refresh failed entirely ────────────────────────────────────
              // This covers: expired refresh token, network failure, 401 on
              // the refresh endpoint, or USER_NOT_FOUND from the backend.
              _logger.e('Token refresh failed: $refreshError');
              await _forceLogout();
              return handler.reject(e);
            } finally {
              // Always reset the flag so future 401s can trigger a refresh
              // once the user logs back in.
              _isRefreshing = false;
            }
          }

          // ── Non-401 errors: pass through unchanged ─────────────────────────
          return handler.next(e);
        },
      ),
    );
  }

  // ── Force Logout ────────────────────────────────────────────────────────────
  /// Wipes all stored tokens, clears the local auth session via AuthCubit,
  /// and navigates the user back to LoginScreen, removing all back-stack routes.
  Future<void> _forceLogout() async {
    _logger.w('Force logout triggered — clearing session and redirecting.');

    try {
      // Wipe tokens from secure storage first so any in-flight requests
      // that complete after this point cannot use stale credentials.
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);

      // Clear the in-app auth state (Cubit/BLoC layer).
      di.sl<AuthCubit>().clearLocalSession();
    } catch (err) {
      _logger.e('Error during session cleanup: $err');
    }

    // Navigate to Login, clearing the entire navigation stack.
    globalNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(isFromSignup: false)),
      (route) => false,
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Dio get dio => _dio;

  /// Resolves the best available auth token: stored token first, then fallback.
  Future<String?> resolveAuthToken() async {
    var token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token == null || token.isEmpty) {
      token = AppConstants.apiToken;
    }
    return token;
  }

  /// Posts to [path] and returns a streaming response — used for AI/SSE flows.
  Future<Response<dynamic>> postStreamResponse(
    String path, {
    required Map<String, dynamic> data,
    CancelToken? cancelToken,
    Map<String, String> headers = const {},
  }) {
    return _dio.post(
      path,
      data: data,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 5),
        headers: headers,
      ),
    );
  }
}
