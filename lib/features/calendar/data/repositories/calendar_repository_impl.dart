import '../sources/calendar_remote_data_source.dart';

abstract class CalendarRepository {
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

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;

  CalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getCalendarEvents({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
  }) async {
    return await remoteDataSource.getCalendarEvents(
      category: category,
      tab: tab,
      watchlist: watchlist,
      symbol: symbol,
      country: country,
    );
  }

  @override
  Future<Map<String, dynamic>> searchCalendarEvents({
    required String category,
    required String query,
    int? page,
    int? limit,
  }) async {
    return await remoteDataSource.searchCalendarEvents(
      category: category,
      query: query,
      page: page,
      limit: limit,
    );
  }
}
