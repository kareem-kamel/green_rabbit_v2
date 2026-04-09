import '../sources/watchlist_remote_data_source.dart';
import '../../../market/data/models/market_instrument.dart';

abstract class WatchlistRepository {
  Future<List<MarketInstrument>> getWatchlists();
  Future<void> addToWatchlist(String instrumentId);
  Future<void> removeFromWatchlist(String instrumentId);
}

class WatchlistRepositoryImpl implements WatchlistRepository {
  final WatchlistRemoteDataSource _remoteDataSource;
  // Using a hardcoded ID '1' for the default watchlist in this phase
  static const String _defaultWatchlistId = '1';

  WatchlistRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MarketInstrument>> getWatchlists() async {
    return _remoteDataSource.getWatchlists();
  }

  @override
  Future<void> addToWatchlist(String instrumentId) async {
    return _remoteDataSource.addInstrumentToWatchlist(_defaultWatchlistId, instrumentId);
  }

  @override
  Future<void> removeFromWatchlist(String instrumentId) async {
    return _remoteDataSource.removeInstrumentFromWatchlist(_defaultWatchlistId, instrumentId);
  }
}
