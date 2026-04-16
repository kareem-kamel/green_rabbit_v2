import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/watchlist_model.dart';

abstract class WatchlistRemoteDataSource {
  Future<List<WatchlistModel>> getWatchlists();
  Future<WatchlistModel> createWatchlist(String name);
  Future<WatchlistModel> updateWatchlist(String id, String name);
  Future<void> deleteWatchlist(String id);
  Future<void> addInstrumentToWatchlist(String watchlistId, String instrumentId);
  Future<void> removeInstrumentFromWatchlist(String watchlistId, String instrumentId);
  Future<void> reorderInstruments(String watchlistId, List<String> instrumentIds);
}

class WatchlistRemoteDataSourceImpl implements WatchlistRemoteDataSource {
  final ApiClient _apiClient;

  WatchlistRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<WatchlistModel>> getWatchlists() async {
    final response = await _apiClient.dio.get('watchlists');
    final List<dynamic> watchlists = response.data['data']['watchlists'] ?? [];
    return watchlists.map((json) => WatchlistModel.fromJson(json)).toList();
  }

  @override
  Future<WatchlistModel> createWatchlist(String name) async {
    final response = await _apiClient.dio.post(
      'watchlists',
      data: {'name': name},
    );
    return WatchlistModel.fromJson(response.data['data']['watchlist']);
  }

  @override
  Future<WatchlistModel> updateWatchlist(String id, String name) async {
    final response = await _apiClient.dio.put(
      'watchlists/$id',
      data: {'name': name},
    );
    return WatchlistModel.fromJson(response.data['data']['watchlist']);
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    await _apiClient.dio.delete('watchlists/$id');
  }

  @override
  Future<void> addInstrumentToWatchlist(String watchlistId, String instrumentId) async {
    await _apiClient.dio.post(
      'watchlists/$watchlistId/instruments',
      data: {'instrumentId': instrumentId},
    );
  }

  @override
  Future<void> removeInstrumentFromWatchlist(String watchlistId, String instrumentId) async {
    await _apiClient.dio.delete('watchlists/$watchlistId/instruments/$instrumentId');
  }

  @override
  Future<void> reorderInstruments(String watchlistId, List<String> instrumentIds) async {
    await _apiClient.dio.put(
      'watchlists/$watchlistId/reorder',
      data: {'instrumentIds': instrumentIds},
    );
  }
}
