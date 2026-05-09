import '../models/calendar_event.dart';
import '../sources/calendar_remote_data_source.dart';

abstract class CalendarRepository {
  Future<Map<String, dynamic>> getCalendarEvents({
    required String category,
    String? tab,
    bool? watchlist,
    String? symbol,
    String? country,
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
}
