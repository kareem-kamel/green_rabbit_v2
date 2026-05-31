import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

abstract class CalendarRemoteDataSource {
  Future<Map<String, dynamic>> getCalendarEvents({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
  });

  Future<Map<String, dynamic>> searchCalendarEvents({
    required String category,
    required String query,
    int? page,
    int? limit,
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

  @override
  Future<Map<String, dynamic>> searchCalendarEvents({
    required String category,
    required String query,
    int? page,
    int? limit,
  }) async {
    final Map<String, dynamic> searchParams = {
      'q': query,
      'type': category,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };

    final response = await apiClient.dio.get(
      AppConstants.search,
      queryParameters: searchParams,
    );
    return response.data;
  }
}
