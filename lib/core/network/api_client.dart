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
    _dio.options.headers['X-Pinggy-No-Screen'] = 'true';

    // Mock Interceptor for local development
    // TODO: REMOVE THIS LINE TO REVERT TO LIVE API
    // _dio.interceptors.add(MockInterceptor());

    // Logging Interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));

    // Request-response Interceptor for Tokens and Errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Priority: Check storage first for a dynamic login token
            String? token = await _storage.read(key: AppConstants.keyAccessToken);
            
            // If storage is empty, fall back to the hardcoded AppConstants.apiToken
            if (token == null || token.isEmpty) {
              token = AppConstants.apiToken;
            }

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            _logger.e('Error reading token: $e');
          }
          
          _logger.d('Proceeding with actual request to: ${options.uri}');
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          _logger.e('API Error [${e.response?.statusCode}] for ${e.requestOptions.uri}: ${e.message}');
          if (e.response?.statusCode == 401) {
            _logger.w('Unauthorized: 401 Error');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
