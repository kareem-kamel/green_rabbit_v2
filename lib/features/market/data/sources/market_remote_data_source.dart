import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import 'package:green_rabbit/features/news/data/models/news_model.dart';
import '../models/market_instrument.dart';
import '../models/market_instrument_detail.dart';

abstract class MarketRemoteDataSource {
  Future<List<MarketInstrument>> getMarketOverview(String type, {String? search});
  Future<MarketInstrumentDetail> getInstrumentDetails(String id);
  Future<Map<String, dynamic>> getInstrumentChart(String id, {String? period, String? interval});
  Future<MarketInstrumentStats> getInstrumentStats(String id, {String? interval});
  Future<List<MarketNewsArticle>> getInstrumentNews(String id, {String? type});
  Future<List<MarketInstrument>> getTrendingInstruments({String? type});
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments);
  Future<List<CommentModel>> fetchComments(String instrumentId);
  Future<bool> postComment(String instrumentId, String text);
  Future<bool> likeComment(String commentId);
  Future<bool> unlikeComment(String commentId);
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
    
    return list.whereType<Map>().map((item) {
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

    return MarketInstrumentDetail.fromJson(Map<String, dynamic>.from(rawData));
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

      final Map<String, dynamic> data = Map<String, dynamic>.from(chartContainer);

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
    
    return MarketInstrumentStats.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<MarketNewsArticle>> getInstrumentNews(String id, {String? type}) async {
    // 1. Determine the category: stock, crypto, or forex
    String category = 'stock';
    
    if (id.contains(':')) {
      final prefix = id.split(':').first.toLowerCase();
      if (prefix == 'crypto') {
        category = 'crypto';
      } else if (prefix == 'forex') {
        category = 'forex';
      } else if (prefix == 'stock' || prefix == 'stocks') {
        category = 'stock';
      }
    } else if (type != null) {
      final t = type.toLowerCase();
      if (t == 'crypto') {
        category = 'crypto';
      } else if (t == 'forex') {
        category = 'forex';
      }
    }

    // 2. Build the namespaced instrument ID using singular prefixes for the URL path parameter (e.g., stock:AAPL)
    String namespacedId = id;
    if (id.contains(':')) {
      final parts = id.split(':');
      final prefix = parts.first.toLowerCase();
      final rest = parts.sublist(1).join(':');
      if (prefix == 'stocks' || prefix == 'stock') {
        namespacedId = 'stock:$rest';
      } else {
        namespacedId = '$prefix:$rest';
      }
    } else {
      namespacedId = '$category:$id';
    }

    // 3. Map to the query parameter value expected by the server ('stocks', 'crypto', 'forex')
    final String queryType = category == 'stock' ? 'stocks' : category;

    final url = AppConstants.instrumentNews(namespacedId);
    final queryParams = {
      'type': queryType,
    };
    
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');
    debugPrint('Query Params: $queryParams');

    try {
      final response = await _apiClient.dio.get(
        url,
        queryParameters: queryParams,
      );

      debugPrint('--- [MARKET API RESPONSE] ---');
      debugPrint('Status: ${response.statusCode}');
      // debugPrint('Body: ${jsonEncode(response.data)}'); // Avoid large JSON dumps if possible
      debugPrint('-----------------------------\n');

      final responseData = response.data;
      if (responseData is! Map) {
        debugPrint('⚠️ [DEBUG] Raw response is not a Map');
        return [];
      }

      final data = responseData['data'];
      if (data == null) {
        debugPrint('⚠️ [DEBUG] "data" is null in response');
        return [];
      }

      final articlesJson = data['articles'];
      if (articlesJson == null || articlesJson is! List) {
        debugPrint('⚠️ [DEBUG] "articles" is missing or not a List');
        return [];
      }

      final List<dynamic> list = articlesJson;
      debugPrint('ℹ️ [DEBUG] Total articles parsed: ${list.length}');
      return list.map((json) => MarketNewsArticle.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    } catch (e) {
      if (e is DioException) {
        debugPrint('❌ [DEBUG] News endpoint failed with status: ${e.response?.statusCode}');
        debugPrint('❌ [DEBUG] Response data: ${e.response?.data}');
      } else {
        debugPrint('❌ [DEBUG] Error fetching news: $e');
      }
      return [];
    }
  }

  @override
  Future<List<MarketInstrument>> getTrendingInstruments({String? type}) async {
    final url = AppConstants.marketTrending;
    final queryParams = {
      if (type != null) 'type': type,
    };
    
    debugPrint('\n--- [MARKET API REQUEST] ---');
    debugPrint('URL: $url');
    if (queryParams.isNotEmpty) debugPrint('Query Params: $queryParams');

    final response = await _apiClient.dio.get(
      url,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

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

    // Each trending item is: { rank, instrument: {...}, trendingReason, trendingScore }
    // Extract the nested instrument object before parsing.
    return list.whereType<Map>().map((item) {
      final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item as Map);
      final inner = itemMap['instrument'];
      final instrumentMap = inner is Map
          ? Map<String, dynamic>.from(inner)
          : itemMap;
      return MarketInstrument.fromJson(instrumentMap);
    }).toList();
  }

  @override
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments) async* {
    final token = await _apiClient.resolveAuthToken();
    
    int retryDelaySec = 1;
    const int maxRetryDelaySec = 60;
    
    while (true) {
      DateTime lastHeartbeatReceived = DateTime.now();
      http.Client? client;
      Timer? monitorTimer;
      
      try {
        client = http.Client();
        
        final queryParams = {
          'instruments': instruments.join(','),
          'fields': 'price,change,changePercent,volume,dayHigh,dayLow,timestamp',
        };
        
        final baseUri = Uri.parse(AppConstants.apiBaseUrl);
        final fullPath = baseUri.path.endsWith('/') && AppConstants.marketStream.startsWith('/')
            ? '${baseUri.path.substring(0, baseUri.path.length - 1)}${AppConstants.marketStream}'
            : (baseUri.path.endsWith('/') || AppConstants.marketStream.startsWith('/')
                ? '${baseUri.path}${AppConstants.marketStream}'
                : '${baseUri.path}/${AppConstants.marketStream}');

        final streamUri = Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: fullPath,
          queryParameters: queryParams,
        );

        debugPrint('--- [MARKET SSE HTTP SEND] URL: $streamUri');
        
        final request = http.Request('GET', streamUri);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        
        final response = await client.send(request);
        
        if (response.statusCode != 200) {
          throw Exception('SSE stream connection failed with status code ${response.statusCode}');
        }
        
        // Reset backoff delay on successful connection
        retryDelaySec = 1;
        
        // Monitor heartbeat
        monitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          final diff = DateTime.now().difference(lastHeartbeatReceived);
          if (diff > const Duration(seconds: 60)) {
            debugPrint('⚠️ [SSE] No heartbeat received for ${diff.inSeconds}s (threshold 60s). Reconnecting...');
            timer.cancel();
            client?.close();
          }
        });
        
        final lines = response.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());
            
        String? currentEventType;
        
        await for (final line in lines) {
          if (line.isEmpty) continue;
          
          if (line.startsWith('event: ')) {
            currentEventType = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            final dataString = line.substring(6).trim();
            debugPrint('--- [MARKET SSE LINE EVENT: $currentEventType] ---');
            
            if (currentEventType == 'heartbeat') {
              lastHeartbeatReceived = DateTime.now();
            }
            
            try {
              final Map<String, dynamic> data = jsonDecode(dataString);
              yield data;
            } catch (e) {
              debugPrint('Error decoding SSE data: $e');
            }
          }
        }
        
      } catch (e) {
        debugPrint('❌ Market Stream Error/Disconnect: $e');
      } finally {
        monitorTimer?.cancel();
        client?.close();
      }
      
      // Exponential backoff
      debugPrint('ℹ️ [SSE] Reconnecting in $retryDelaySec seconds...');
      await Future.delayed(Duration(seconds: retryDelaySec));
      retryDelaySec = (retryDelaySec * 2).clamp(1, maxRetryDelaySec);
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(String instrumentId) async {
    try {
      final url = '/comments';
      final String entityType = "instrument";

      debugPrint('DEBUG: fetchComments for instrument - START');

      final response = await _apiClient.dio.get(
        url,
        queryParameters: {
          'entityType': entityType,
          'entityId': instrumentId,
        },
        options: Options(
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      if (response.statusCode == 200) {
        final decodedData = response.data;
        if (decodedData is Map<String, dynamic> && decodedData['success'] == true) {
          final List list = decodedData['data'] is List ? decodedData['data'] : (decodedData['data']?['comments'] ?? []);
          return list.map((c) => CommentModel.fromJson(Map<String, dynamic>.from(c))).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('DEBUG: fetchComments error for instrument: $e');
      return [];
    }
  }

  @override
  Future<bool> postComment(String instrumentId, String text) async {
    try {
      final url = '/comments';
      final String entityType = "instrument";

      final response = await _apiClient.dio.post(url, data: {
        'entityType': entityType,
        'entityId': instrumentId,
        'content': text,
      });

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('DEBUG: postComment error for instrument: $e');
      return false;
    }
  }

  @override
  Future<bool> likeComment(String commentId) async {
    try {
      final response = await _apiClient.dio.post('/comments/$commentId/like');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message']?.toString().contains('already_liked') == true) {
          return true;
        }
      }
      return false;
    }
  }

  @override
  Future<bool> unlikeComment(String commentId) async {
    try {
      final response = await _apiClient.dio.delete('/comments/$commentId/like');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
