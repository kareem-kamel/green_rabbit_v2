import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/calendar_event.dart';

abstract class CalendarRemoteDataSource {
  Future<Map<String, dynamic>> getCalendarEvents({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
  });
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final ApiClient apiClient;

  CalendarRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getCalendarEvents({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (tab != null) queryParams['tab'] = tab;
    if (watchlist != null) queryParams['watchlist'] = watchlist;
    if (symbol != null) queryParams['symbol'] = symbol;
    if (country != null) queryParams['country'] = country;

    final response = await apiClient.dio.get(
      AppConstants.calendars(category),
      queryParameters: queryParams,
    );

    return response.data;
  }
}
