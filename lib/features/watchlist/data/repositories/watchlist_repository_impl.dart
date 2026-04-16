import '../models/watchlist_model.dart';
import '../sources/watchlist_remote_data_source.dart';

abstract class WatchlistRepository {
  Future<List<WatchlistModel>> getWatchlists();
  Future<WatchlistModel> createWatchlist(String name);
  Future<WatchlistModel> renameWatchlist(String id, String name);
  Future<void> deleteWatchlist(String id);
  Future<void> addToWatchlist(String watchlistId, String instrumentId);
  Future<void> removeFromWatchlist(String watchlistId, String instrumentId);
  Future<void> reorderInstruments(String watchlistId, List<String> instrumentIds);
}

class WatchlistRepositoryImpl implements WatchlistRepository {
  final WatchlistRemoteDataSource _remoteDataSource;

  WatchlistRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<WatchlistModel>> getWatchlists() async {
    return _remoteDataSource.getWatchlists();
  }

  @override
  Future<WatchlistModel> createWatchlist(String name) async {
    return _remoteDataSource.createWatchlist(name);
  }

  @override
  Future<WatchlistModel> renameWatchlist(String id, String name) async {
    return _remoteDataSource.updateWatchlist(id, name);
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    return _remoteDataSource.deleteWatchlist(id);
  }

  @override
  Future<void> addToWatchlist(String watchlistId, String instrumentId) async {
    return _remoteDataSource.addInstrumentToWatchlist(watchlistId, instrumentId);
  }

  @override
  Future<void> removeFromWatchlist(String watchlistId, String instrumentId) async {
    return _remoteDataSource.removeInstrumentFromWatchlist(watchlistId, instrumentId);
  }

  @override
  Future<void> reorderInstruments(String watchlistId, List<String> instrumentIds) async {
    return _remoteDataSource.reorderInstruments(watchlistId, instrumentIds);
  }
}
