import 'package:dio/dio.dart';
import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';
import '../sources/market_remote_data_source.dart';
import 'package:green_rabbit/features/news/data/models/news_model.dart';

abstract class MarketRepository {
  Future<MarketOverviewResponse> getMarketOverview(String type, {String? search, int? page, int? limit});
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval});
  Future<List<MarketNewsArticle>> getInstrumentNews(String id, {String? type});
  Future<List<MarketInstrument>> getTrendingInstruments({String? type});
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments, {CancelToken? cancelToken});
  Future<List<CommentModel>> fetchComments(String instrumentId);
  Future<bool> postComment(String instrumentId, String text);
  Future<bool> likeComment(String commentId);
  Future<bool> unlikeComment(String commentId);
  Future<List<MarketInstrument>> searchInstruments(String query, {int? page, int? limit});
  Future<List<String>> getSearchHistory({int? limit});
  Future<bool> clearSearchHistory();
  Future<void> saveSearchHistory(String query);
  Stream<int> get rateLimitStream;
}

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource _remoteDataSource;

  MarketRepositoryImpl(this._remoteDataSource);

  @override
  Future<MarketOverviewResponse> getMarketOverview(String type, {String? search, int? page, int? limit}) async {
    return _remoteDataSource.getMarketOverview(type, search: search, page: page, limit: limit);
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
  Future<List<MarketNewsArticle>> getInstrumentNews(String id, {String? type}) async {
    return _remoteDataSource.getInstrumentNews(id, type: type);
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments({String? type}) async {
    return _remoteDataSource.getTrendingInstruments(type: type);
  }

  @override
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments, {CancelToken? cancelToken}) {
    return _remoteDataSource.getMarketStream(instruments, cancelToken: cancelToken);
  }

  @override
  Future<List<CommentModel>> fetchComments(String instrumentId) async {
    return _remoteDataSource.fetchComments(instrumentId);
  }

  @override
  Future<bool> postComment(String instrumentId, String text) async {
    return _remoteDataSource.postComment(instrumentId, text);
  }

  @override
  Future<bool> likeComment(String commentId) async {
    return _remoteDataSource.likeComment(commentId);
  }

  @override
  Future<bool> unlikeComment(String commentId) async {
    return _remoteDataSource.unlikeComment(commentId);
  }

  @override
  Future<List<MarketInstrument>> searchInstruments(String query, {int? page, int? limit}) async {
    return _remoteDataSource.searchInstruments(query, page: page, limit: limit);
  }

  @override
  Future<List<String>> getSearchHistory({int? limit}) async {
    return _remoteDataSource.getSearchHistory(limit: limit);
  }

  @override
  Future<bool> clearSearchHistory() async {
    return _remoteDataSource.clearSearchHistory();
  }

  @override
  Future<void> saveSearchHistory(String query) async {
    return _remoteDataSource.saveSearchHistory(query);
  }

  @override
  Stream<int> get rateLimitStream => _remoteDataSource.rateLimitStream;
}
