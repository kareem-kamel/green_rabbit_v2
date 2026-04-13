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

    // Mock Interceptor for local development
    if (AppConstants.useMockApi) {
      _dio.interceptors.add(MockInterceptor());
    }

    // Logging Interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));

    // Request-response Interceptor for Errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
