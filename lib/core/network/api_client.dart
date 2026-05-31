import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'mock_interceptor.dart'; // TODO: DELETE THIS AND THE INTERCEPTOR BELOW TO REVERT TO LIVE API
import 'package:flutter/material.dart';
import '../../main.dart';
import '../di/injection_container.dart' as di;
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;
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
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      _dio.options.headers['Connection'] = 'keep-alive';
    }

    // Mock Interceptor for local development
    if (AppConstants.useMockApi) {
      _dio.interceptors.add(MockInterceptor());
    }

    // Request-response Interceptor for Auth and Errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final isAuthRequest =
                options.path.contains('auth/login') ||
                options.path.contains('auth/register') ||
                options.path.contains('auth/verify-email');

            // Priority: Check storage first for a dynamic login token
            String? token = await _storage.read(
              key: AppConstants.keyAccessToken,
            );

            // If storage is empty, fall back to the hardcoded AppConstants.apiToken
            if (token == null || token.isEmpty) {
              token = AppConstants.apiToken;
            }

            if (token != null && token.isNotEmpty && !isAuthRequest) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            _logger.e('Error reading token: $e');
          }
          _logger.d('Proceeding with actual request to: ${options.uri}');
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          _logger.e(
            'API Error [${e.response?.statusCode}] for ${e.requestOptions.uri}: ${e.message}',
          );
          _logger.e('API Error Response: ${e.response?.data}');

          // Handle 429 Too Many Requests (Rate Limit)
          if (e.response?.statusCode == 429) {
            final responseData = e.response?.data;
            String? retryAfterStr;
            
            if (responseData is Map) {
              retryAfterStr = responseData['error']?['details']?['retryAfter']?.toString();
            }
            
            retryAfterStr ??= e.response?.headers.value('retry-after');
            
            final retryAfterSeconds = int.tryParse(retryAfterStr ?? '') ?? 5;
            
            // Notify listeners about the rate limit immediately
            if (onRateLimit != null) {
              onRateLimit!(retryAfterSeconds);
            }
            
            _logger.w('Rate limited. Retrying after $retryAfterSeconds seconds...');
            await Future.delayed(Duration(seconds: retryAfterSeconds));
            
            try {
              final response = await _dio.request(
                e.requestOptions.path,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
              );
              return handler.resolve(response);
            } catch (retryError) {
              return handler.next(retryError is DioException ? retryError : e);
            }
          }

          final isUnauthorized = e.response?.statusCode == 401;
          bool isUserNotFound = false;
          if (e.response?.data != null && e.response?.data is Map) {
            final data = e.response?.data as Map;
            if (data['error'] != null && data['error'] is Map) {
              isUserNotFound = data['error']['code'] == 'USER_NOT_FOUND';
            }
          }

          if (isUnauthorized || isUserNotFound) {
            _logger.w('Unauthorized or User Not Found: Auto-logging out');
            try {
              di.sl<AuthCubit>().clearLocalSession();
              globalNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(isFromSignup: false),
                ),
                (route) => false,
              );
            } catch (err) {
              _logger.e('Error during auto-logout: $err');
            }
          }

          return handler.next(e);
        },
      ),
    );

    // Logging Interceptor (added after Auth for request visibility, but runs before for error/response)
    // _dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   logPrint: (obj) => _logger.d(obj),
    // ));
  }

  Dio get dio => _dio;

  Future<String?> resolveAuthToken() async {
    var token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token == null || token.isEmpty) {
      token = AppConstants.apiToken;
    }
    return token;
  }

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
