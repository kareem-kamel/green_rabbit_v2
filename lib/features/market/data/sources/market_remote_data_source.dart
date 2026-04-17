import '../../../../core/network/api_client.dart';
import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';

abstract class MarketRemoteDataSource {
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search});
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<MarketInstrumentStats> getInstrumentStats(String id);
  Future<List<dynamic>> getInstrumentNews(String id);
  Future<List<MarketInstrument>> getTrendingInstruments();
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final ApiClient _apiClient;

  MarketRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search}) async {
    final response = await _apiClient.dio.get(
      'market/overview/$type',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final List<dynamic> list = response.data['data']['instruments'] ?? [];
    return list.map((json) => MarketInstrument.fromJson(json)).toList();
  }

  @override
  Future<MarketInstrumentDetail> getInstrumentDetails(String id) async {
    final response = await _apiClient.dio.get('market/instruments/$id');
    final data = response.data['data'];
    // Handle both { data: { instrument: { ... } } } and { data: { ...fields... } }
    final instrumentJson = data['instrument'] ?? data;
    return MarketInstrumentDetail.fromJson(instrumentJson);
  }

  @override
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval}) async {
    final response = await _apiClient.dio.get(
      'market/instruments/$id/chart',
      queryParameters: {
        if (period != null) 'period': period,
        if (interval != null) 'interval': interval,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<MarketInstrumentStats> getInstrumentStats(String id) async {
    final response = await _apiClient.dio.get('market/instruments/$id/stats');
    return MarketInstrumentStats.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<dynamic>> getInstrumentNews(String id) async {
    final response = await _apiClient.dio.get('market/instruments/$id/news');
    return response.data['data']['articles'] as List<dynamic>;
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments() async {
    final response = await _apiClient.dio.get('market/trending');
    final List<dynamic> list = response.data['data']['trending'] ?? [];
    return list.map((json) => MarketInstrument.fromJson(json['instrument'])).toList();
  }
}
