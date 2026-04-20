import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';

abstract class MarketRemoteDataSource {
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search});
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval});
  Future<List<MarketNewsArticle>> getInstrumentNews(String id);
  Future<List<MarketInstrument>> getTrendingInstruments();
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments);
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final ApiClient _apiClient;

  MarketRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search}) async {
    final url = AppConstants.marketOverview(type);
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,
    };
    
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');
    debugPrint('Query Params: $queryParams');

    final response = await _apiClient.dio.get(
      url,
      queryParameters: queryParams,
    );
    
    debugPrint('--- [MARKET API RESPONSE] ---');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${jsonEncode(response.data)}');
    debugPrint('-----------------------------\n');

    final responseData = response.data;
    if (responseData == null) return [];

    // Robust parsing: Handle { data: { instruments: [...] } }, { instruments: [...] }, or { data: [...] }
    List<dynamic>? list;
    if (responseData is Map) {
      final innerData = responseData['data'];
      if (innerData is Map) {
        list = innerData['instruments'] as List<dynamic>?;
      } else if (innerData is List) {
        list = innerData;
      } else {
        list = responseData['instruments'] as List<dynamic>?;
      }
    } else if (responseData is List) {
      list = responseData;
    }

    if (list == null || list.isEmpty) {
      debugPrint('⚠️ Warning: Market overview for $type returned no instruments');
      return [];
    }
    
    return list.where((item) => item is Map).map((item) {
      final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item as Map);
      return MarketInstrument.fromJson(itemMap);
    }).toList();
  }

  @override
  Future<MarketInstrumentDetail> getInstrumentDetails(String id) async {
    final url = AppConstants.instrumentDetails(id);
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');

    final response = await _apiClient.dio.get(url);
    
    debugPrint('--- [MARKET API RESPONSE] ---');
    debugPrint('Status: ${response.statusCode}');

    final responseData = response.data;
    if (responseData == null) throw Exception('Instrument details not found for ID: $id');
    
    // Unbox data: handle { data: { instrument: { ... } } }, { data: { ...fields... } }, and root-level fields
    dynamic rawData;
    if (responseData is Map) {
      rawData = responseData['data'] ?? responseData['instrument'] ?? responseData;
      if (rawData is Map && rawData.containsKey('instrument')) {
        rawData = rawData['instrument'];
      }
    } else {
      rawData = responseData;
    }

    if (rawData == null || rawData is! Map) {
      throw Exception('Could not extract valid instrument details from response for ID: $id');
    }

    return MarketInstrumentDetail.fromJson(Map<String, dynamic>.from(rawData as Map));
  }

  @override
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval}) async {
    String? requestInterval = interval;
    if (requestInterval == null || requestInterval == 'null') {
      switch (period) {
        case '1D': requestInterval = '15m'; break;
        case '1W': requestInterval = '1h'; break;
        default: requestInterval = '1d';
      }
    }

    final url = AppConstants.instrumentChart(id);
    final queryParams = {
      if (period != null) 'period': period,
      'interval': requestInterval,
    };

    try {
      final response = await _apiClient.dio.get(url, queryParameters: queryParams);
      final responseData = response.data;
      
      debugPrint('--- [CHART API RESPONSE] ---');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('URL: $url?period=$period&interval=$requestInterval');

      // Unbox the chart data
      dynamic chartContainer;
      if (responseData is Map) {
        chartContainer = responseData['data'] ?? responseData;
      } else {
        chartContainer = responseData;
      }

      if (chartContainer == null || chartContainer is! Map) {
        debugPrint('⚠️ Warning: Chart container is null or not a map');
        return {'candles': []};
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(chartContainer as Map);

      if (data.containsKey('candles')) {
        final List<dynamic> originalCandles = data['candles'];
        debugPrint('✅ Found ${originalCandles.length} candles in response');

        final List<Map<String, dynamic>> normalizedCandles = originalCandles.map((c) {
          if (c is! Map) return <String, dynamic>{};
          final Map candle = c;
          
          return {
            'timestamp': candle['timestamp'] ?? candle['t'],
            'open': (candle['open'] ?? candle['o'] ?? 0.0) as num,
            'high': (candle['high'] ?? candle['h'] ?? 0.0) as num,
            'low': (candle['low'] ?? candle['l'] ?? 0.0) as num,
            'close': (candle['close'] ?? candle['c'] ?? 0.0) as num,
            'volume': (candle['volume'] ?? candle['v'] ?? 0) as num,
          };
        }).toList();
        
        return {...data, 'candles': normalizedCandles};
      }

      debugPrint('⚠️ Warning: No "candles" key in result map');
      return data;
    } catch (e) {
      debugPrint('❌ Error fetching chart for $id: $e');
      return {'candles': []};
    }
  }

  @override
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval}) async {
    final url = AppConstants.instrumentStats(id);
    final queryParams = {
      if (interval != null) 'interval': interval,
    };

    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');
    debugPrint('Query Params: $queryParams');

    final response = await _apiClient.dio.get(
      url,
      queryParameters: queryParams,
    );

    final responseData = response.data;
    if (responseData == null) throw Exception('Stats not found for ID: $id');
    
    final data = responseData is Map ? responseData['data'] : null;
    if (data == null || data is! Map) {
      throw Exception('Stats data object not found for ID: $id');
    }
    
    return MarketInstrumentStats.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<MarketNewsArticle>> getInstrumentNews(String id) async {
    final url = AppConstants.instrumentNews(id);
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');

    final response = await _apiClient.dio.get(url);

    debugPrint('--- [MARKET API RESPONSE] ---');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${jsonEncode(response.data)}');
    debugPrint('-----------------------------\n');

    final data = response.data['data'];
    if (data == null || data['articles'] == null) {
      return [];
    }
    final List<dynamic> list = data['articles'];
    return list.map((json) => MarketNewsArticle.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments() async {
    final url = AppConstants.marketTrending;
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');

      final response = await _apiClient.dio.get(url);

    debugPrint('--- [MARKET TRENDING RESPONSE] ---');
    debugPrint('Status: ${response.statusCode}');

    final responseData = response.data;
    if (responseData == null) return [];

    // Robust parsing: Handle variety of response shapes
    List<dynamic>? list;
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map) {
        list = data['instruments'] as List<dynamic>? ?? data['trending'] as List<dynamic>?;
      } else if (data is List) {
        list = data;
      } else {
        list = responseData['instruments'] as List<dynamic>? ?? responseData['trending'] as List<dynamic>?;
      }
    } else if (responseData is List) {
      list = responseData;
    }

    if (list == null || list.isEmpty) {
      debugPrint('⚠️ Warning: Trending instruments returned no data');
      return [];
    }
    
    return list.where((item) => item is Map).map((item) {
      return MarketInstrument.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  @override
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments) async* {
    final url = AppConstants.marketStream;
    final queryParams = {
      'instruments': instruments.join(','),
    };

    debugPrint('\n--- [MARKET SSE CONNECTING] ---');
    debugPrint('URL: $url');
    debugPrint('Instruments: ${instruments.join(',')}');

    try {
      final response = await _apiClient.dio.get<ResponseBody>(
        url,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      debugPrint('--- [MARKET SSE CONNECTED] ---');

      String? currentEventType;

      // Robust UTF-8 and Line-based stream parsing
      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty) {
          continue;
        }

        if (line.startsWith('event: ')) {
          currentEventType = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          final dataString = line.substring(6).trim();
          debugPrint('--- [MARKET SSE EVENT: $currentEventType] ---');
          debugPrint('Data: $dataString');

          try {
            final Map<String, dynamic> data = jsonDecode(dataString);
            yield data;
          } catch (e) {
            debugPrint('Error decoding SSE data: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Market Stream Error: $e');
    }
  }
}
