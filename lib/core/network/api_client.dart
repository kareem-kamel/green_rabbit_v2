// ignore_for_file: unused_import
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'mock_interceptor.dart'; // TODO: DELETE THIS AND THE INTERCEPTOR BELOW TO REVERT TO LIVE API

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage storage,
    required Logger logger,
  })  : _dio = dio,
        _storage = storage,
        _logger = logger {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    _dio.options.headers['Accept'] = '*/*';
    _dio.options.headers['Connection'] = 'keep-alive';

    // Mock Interceptor for local development
    if (AppConstants.useMockApi) {
      _dio.interceptors.add(MockInterceptor());
    }

    // Request-response Interceptor for Auth and Errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.keyAccessToken);
          final isAuthRequest = options.path.contains('auth/login') ||
              options.path.contains('auth/register') ||
              options.path.contains('auth/verify-email');

          if (token != null && !isAuthRequest) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('Proceeding with actual request to: ${options.uri}');
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          _logger.e(
              'API Error [${e.response?.statusCode}] for ${e.requestOptions.uri}: ${e.message}');
          if (e.response?.statusCode == 401) {
            _logger.w('Unauthorized: 401 Error');
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
}
