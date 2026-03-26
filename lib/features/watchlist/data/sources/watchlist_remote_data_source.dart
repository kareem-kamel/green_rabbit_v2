import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../market/data/models/market_instrument.dart';

abstract class WatchlistRemoteDataSource {
  Future<List<MarketInstrument>> getWatchlists();
  Future<void> addInstrumentToWatchlist(String watchlistId, String instrumentId);
  Future<void> removeInstrumentFromWatchlist(String watchlistId, String instrumentId);
}

class WatchlistRemoteDataSourceImpl implements WatchlistRemoteDataSource {
  final ApiClient _apiClient;

  WatchlistRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<MarketInstrument>> getWatchlists() async {
    try {
      final response = await _apiClient.dio.get('/watchlists');
      if (response.statusCode == 200) {
        // Based on docs: Retrieves all watchlists for the user.
        // We extract instruments from the first (default) watchlist provided in the list
        final List<dynamic> watchlists = response.data['data']['watchlists'] ?? [];
        if (watchlists.isEmpty) return [];
        
        final List<dynamic> instruments = watchlists.first['instruments'] ?? [];
        return instruments.map((json) => MarketInstrument.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to fetch watchlists',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addInstrumentToWatchlist(String watchlistId, String instrumentId) async {
    await _apiClient.dio.post(
      '/watchlists/$watchlistId/instruments',
      data: {'instrumentId': instrumentId},
    );
  }

  @override
  Future<void> removeInstrumentFromWatchlist(String watchlistId, String instrumentId) async {
    await _apiClient.dio.delete('/watchlists/$watchlistId/instruments/$instrumentId');
  }
}
