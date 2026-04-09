import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';
import '../sources/market_remote_data_source.dart';

abstract class MarketRepository {
  Future<List<MarketInstrument>> getMarketOverview(String type);
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<Map<String, dynamic>> getInstrumentStats(String id);
  Future<List<dynamic>> getInstrumentNews(String id);
  Future<List<MarketInstrument>> getTrendingInstruments();
}

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource _remoteDataSource;

  MarketRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MarketInstrument>> getMarketOverview(String type) async {
    return _remoteDataSource.getMarketOverview(type);
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
  Future<Map<String, dynamic>> getInstrumentStats(String id) async {
    return _remoteDataSource.getInstrumentStats(id);
  }

  @override
  Future<List<dynamic>> getInstrumentNews(String id) async {
    return _remoteDataSource.getInstrumentNews(id);
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments() async {
    return _remoteDataSource.getTrendingInstruments();
  }
}
