import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';
import '../sources/market_remote_data_source.dart';

abstract class MarketRepository {
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search});
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval});
  Future<List<MarketNewsArticle>> getInstrumentNews(String id);
  Future<List<MarketInstrument>> getTrendingInstruments();
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments);
}

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource _remoteDataSource;

  MarketRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search}) async {
    return _remoteDataSource.getMarketOverview(type, search: search);
  }

  @override
  Future<MarketInstrumentDetail> getInstrumentDetails(String id) async {
    return _remoteDataSource.getInstrumentDetails(id);
  }

  @override
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval}) async {
    return _remoteDataSource.getInstrumentChart(id, period: period, interval: interval);
  }

  @override
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval}) async {
    return _remoteDataSource.getInstrumentStats(id, interval: interval);
  }

  @override
  Future<List<MarketNewsArticle>> getInstrumentNews(String id) async {
    return _remoteDataSource.getInstrumentNews(id);
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments() async {
    return _remoteDataSource.getTrendingInstruments();
  }

  @override
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments) {
    return _remoteDataSource.getMarketStream(instruments);
  }
}
