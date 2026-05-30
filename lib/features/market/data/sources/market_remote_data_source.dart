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
import '../../../../core/di/injection_container.dart' as di;
import '../../../subscriptions/data/repository/subscription_repository.dart';
import '../../../subscriptions/data/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class MarketRemoteDataSource {
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
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final ApiClient _apiClient;

  static final Set<String> _streamBlacklistedSymbols = {};

  MarketRemoteDataSourceImpl(this._apiClient);

  @override
  Future<MarketOverviewResponse> getMarketOverview(String type, {String? search, int? page, int? limit}) async {
    final url = AppConstants.marketOverview(type);
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
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
    if (responseData == null) {
      return MarketOverviewResponse(
        instruments: [],
        meta: MarketOverviewMeta(page: page ?? 1, limit: limit ?? 20, hasNext: false, hasPrev: false),
      );
    }

    return MarketOverviewResponse.fromJson(Map<String, dynamic>.from(responseData));
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

    // 2. Build the namespaced instrument ID for the URL path.
    // The backend for the News endpoint strictly expects the "category:symbol" format.
    String namespacedId = id;
    if (!id.contains(':')) {
      // Use singular 'stock' for the path as expected by the backend
      final pathPrefix = category == 'stocks' ? 'stock' : category;
      namespacedId = '$pathPrefix:$id';
    } else {
      // Ensure 'stocks:' is converted to 'stock:' if present
      if (namespacedId.startsWith('stocks:')) {
        namespacedId = namespacedId.replaceFirst('stocks:', 'stock:');
      }
    }

    // Trim hyphen for crypto category (e.g. crypto:BTC-USD -> crypto:BTC)
    if (category == 'crypto') {
      if (namespacedId.contains(':')) {
        final parts = namespacedId.split(':');
        final prefix = parts[0];
        final symbol = parts[1];
        if (symbol.contains('-')) {
          namespacedId = '$prefix:${symbol.split('-').first}';
        }
      } else {
        if (namespacedId.contains('-')) {
          namespacedId = namespacedId.split('-').first;
        }
      }
    }

    // 3. Map to the query parameter value expected by the server ('stocks', 'crypto', 'forex')
    final String queryType = category == 'stock' ? 'stocks' : category;

    // 4. Prepare the final URL. 
    // We encode the ID because crypto symbols often contain slashes (e.g., BTC/USD).
    final String encodedId = Uri.encodeComponent(namespacedId);
    final url = AppConstants.instrumentNews(encodedId);

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
      final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
      final inner = itemMap['instrument'];
      final instrumentMap = inner is Map
          ? Map<String, dynamic>.from(inner)
          : itemMap;
      return MarketInstrument.fromJson(instrumentMap);
    }).toList();
  }

  @override
  Stream<Map<String, dynamic>> getMarketStream(List<String> instruments, {CancelToken? cancelToken}) async* {
    debugPrint('➡️ [SSE Remote] getMarketStream called for instruments: $instruments');
    final token = await _apiClient.resolveAuthToken();
    debugPrint('➡️ [SSE Remote] resolved token: ${token != null && token.isNotEmpty ? "Length ${token.length}" : "NULL/EMPTY"}');

    int retryDelaySec = 1;
    const int maxRetryDelaySec = 60;

    while (true) {
      if (cancelToken?.isCancelled ?? false) break;

      final subRepo = di.sl<SubscriptionRepository>();
      final currentSub = subRepo.currentSubscription;

      int maxInstruments = 100; // Free tier limit
      if (currentSub != null && currentSub.status == 'active') {
        final planId = currentSub.planId.toLowerCase();
        final planName = currentSub.planName.toLowerCase();
        final isPro = currentSub.isFullPro ||
            planId.contains('pro') ||
            planId.contains('premium') ||
            planName.contains('pro') ||
            planName.contains('premium') ||
            currentSub.features.contains('all_pro_features') ||
            currentSub.features.contains('all_pro_features_full');

        final isClassic = currentSub.isClassic ||
            planId.contains('classic') ||
            planName.contains('classic');

        if (isPro) {
          maxInstruments = 150;
        } else if (isClassic) {
          maxInstruments = 120;
        }
      }

      DateTime lastHeartbeatReceived = DateTime.now();
      http.Client? client;
      Timer? monitorTimer;

      try {
        client = http.Client();

        cancelToken?.whenCancel.then((_) {
          client?.close();
          monitorTimer?.cancel();
        });

        if (cancelToken?.isCancelled ?? false) {
          client.close();
          break;
        }

        // ─── DEBUG: Log raw input instruments ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] getMarketStream() START                               ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║  Raw input instruments (${instruments.length}):');
        for (int i = 0; i < instruments.length; i++) {
          debugPrint('║    [$i] "${instruments[i]}"');
        }
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        final namespacedInstruments = instruments.map((id) {
          String cleanId = id;
          if (cleanId.toUpperCase() == 'AADBE') {
            cleanId = 'ADBE';
          } else if (cleanId.toUpperCase().endsWith(':AADBE')) {
            cleanId = cleanId.substring(0, cleanId.length - 5) + 'ADBE';
          }

          // Strip any existing prefix just in case, per user request to not send types
          if (cleanId.contains(':')) {
            cleanId = cleanId.split(':').last;
          }

          return cleanId;
        }).toList();

        // ─── DEBUG: Log namespaced instruments after transformation ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] After namespace transformation                        ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║  Namespaced instruments (${namespacedInstruments.length}):');
        for (int i = 0; i < namespacedInstruments.length; i++) {
          debugPrint('║    [$i] "${namespacedInstruments[i]}"');
        }
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        final validInstruments = namespacedInstruments.where((inst) {
          final rawSymbol = inst.contains(':') ? inst.split(':')[1].toUpperCase() : inst.toUpperCase();
          return !_streamBlacklistedSymbols.contains(rawSymbol);
        }).toList();

        // ─── DEBUG: Log blacklist filtering ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] After blacklist filtering                             ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║  Blacklisted symbols (${_streamBlacklistedSymbols.length}): ${_streamBlacklistedSymbols.join(', ')}');
        debugPrint('║  Valid instruments (${validInstruments.length}/${namespacedInstruments.length}):');
        for (int i = 0; i < validInstruments.length; i++) {
          debugPrint('║    [$i] "${validInstruments[i]}"');
        }
        if (validInstruments.length < namespacedInstruments.length) {
          final removed = namespacedInstruments.where((inst) => !validInstruments.contains(inst)).toList();
          debugPrint('║  Removed by blacklist (${removed.length}):');
          for (final r in removed) {
            debugPrint('║    - "$r"');
          }
        }
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        final limitedInstruments = validInstruments.take(maxInstruments).toList();
        if (limitedInstruments.isEmpty) {
          debugPrint('❌ [SSE] No valid instruments after filtering/blacklist. Yielding empty map and waiting 10s...');
          yield const <String, dynamic>{};
          await Future.delayed(const Duration(seconds: 10));
          continue;
        }

        // ─── DEBUG: Log final subscription request ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] Subscription Request Summary                          ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║  Tier: ${currentSub?.planName ?? 'free'}');
        debugPrint('║  Max instruments allowed: $maxInstruments');
        debugPrint('║  Requesting: ${limitedInstruments.length}/${namespacedInstruments.length}');
        debugPrint('║  Final instrument list:');
        for (int i = 0; i < limitedInstruments.length; i++) {
          debugPrint('║    [$i] "${limitedInstruments[i]}"');
        }
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        final queryParams = {
          'instruments': limitedInstruments.join(','),
          'fields': 'price,change,changePercent,volume,dayHigh,dayLow,timestamp',
        };

        // ─── DEBUG: Log query parameters ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] Query Parameters                                        ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        queryParams.forEach((key, value) {
          debugPrint('║  $key = "$value"');
        });
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        debugPrint('📡 [SSE] Sending request using Dio...');

        Response<ResponseBody>? response;
        try {
          response = await _apiClient.dio.get<ResponseBody>(
            AppConstants.marketStream,
            queryParameters: queryParams,
            cancelToken: cancelToken,
            options: Options(
              responseType: ResponseType.stream,
              headers: {
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
              },
              validateStatus: (status) => status != null && status >= 200 && status < 500, // Handle 404 manually
            ),
          );
        } catch (e) {
          if (e is DioException) {
            response = e.response as Response<ResponseBody>?;
            debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
            debugPrint('║  [SSE] DioException Caught                                     ║');
            debugPrint('╠══════════════════════════════════════════════════════════════╣');
            debugPrint('║  Message: ${e.message}');
            debugPrint('║  Status Code: ${e.response?.statusCode}');
            debugPrint('║  Error Data: ${e.response?.data}');
            try {
              if (e.response?.data is ResponseBody) {
                final bodyStream = (e.response?.data as ResponseBody).stream;
                final bytesList = await bodyStream.fold<List<int>>(
                  <int>[],
                  (previous, element) => previous..addAll(element),
                );
                final bodyString = utf8.decode(bytesList);
                debugPrint('║  Response Body String: $bodyString');
              } else {
                debugPrint('║  Response Body String: ${e.response?.data?.toString()}');
              }
            } catch (bodyError) {
              debugPrint('║  Could not read body string: $bodyError');
            }
            debugPrint('╚══════════════════════════════════════════════════════════════╝\n');
          } else {
            throw e;
          }
        }

        if (response == null) {
          throw Exception('SSE stream connection failed with no response');
        }

        // ─── DEBUG: Log response status immediately ───
        debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
        debugPrint('║  [SSE] Response Received                                       ║');
        debugPrint('╠══════════════════════════════════════════════════════════════╣');
        debugPrint('║  Status Code: ${response.statusCode}');
        debugPrint('║  Reason Phrase: ${response.statusMessage}');
        debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

        if (response.statusCode == 200) {
          debugPrint('🟢 [SSE] Successfully established stream connection for: $limitedInstruments');
        }

        if (response.statusCode != 200) {
          if (response.statusCode == 404) {
            debugPrint('⚠️ [SSE] Connection failed with 404. Diagnosing invalid instruments...');

            monitorTimer?.cancel();

            // Validate each instrument via REST in parallel
            final validationFutures = limitedInstruments.map((inst) async {
              final rawSymbol = inst.contains(':') ? inst.split(':')[1] : inst;
              try {
                final restUrl = AppConstants.instrumentDetails(rawSymbol);
                debugPrint('🔍 [SSE] Validating via REST: $inst → GET $restUrl');

                final restResp = await _apiClient.dio.get(
                  restUrl,
                  options: Options(
                    validateStatus: (status) => status == 200 || status == 404 || status == 400,
                  ),
                ).timeout(const Duration(seconds: 5));

                if (restResp.statusCode == 404 || restResp.statusCode == 400) {
                  final sym = rawSymbol.toUpperCase();
                  _streamBlacklistedSymbols.add(sym);
                  debugPrint('❌ [SSE] Blacklisted invalid instrument: $inst (HTTP ${restResp.statusCode})');
                } else {
                  debugPrint('✅ [SSE] Instrument valid: $inst (HTTP ${restResp.statusCode})');
                }
              } catch (e) {
                debugPrint('⚠️ [SSE] Could not validate $inst via REST: $e');
              }
            });
            await Future.wait(validationFutures);

            // Check if everything was blacklisted
            final remaining = namespacedInstruments.where((inst) {
              final raw = inst.contains(':') ? inst.split(':')[1].toUpperCase() : inst.toUpperCase();
              return !_streamBlacklistedSymbols.contains(raw);
            }).toList();

            debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
            debugPrint('║  [SSE] Post-Diagnosis Summary                                  ║');
            debugPrint('╠══════════════════════════════════════════════════════════════╣');
            debugPrint('║  Remaining valid instruments: ${remaining.length}');
            for (int i = 0; i < remaining.length; i++) {
              debugPrint('║    [$i] "${remaining[i]}"');
            }
            debugPrint('╚══════════════════════════════════════════════════════════════╝\n');

            if (remaining.isEmpty) {
              debugPrint('❌ [SSE] All requested instruments are invalid/blacklisted. Waiting 10s...');
              yield const <String, dynamic>{};
              await Future.delayed(const Duration(seconds: 10));
              retryDelaySec = 1;
              continue;
            }

            retryDelaySec = 1;
            continue;
          }
          
          if (response.statusCode == 400) {
            String errorBody = 'Unknown 400 Error';
            try {
              if (response.data is ResponseBody) {
                final bodyStream = (response.data as ResponseBody).stream;
                final bytesList = await bodyStream.fold<List<int>>(
                  <int>[],
                  (previous, element) => previous..addAll(element),
                );
                errorBody = utf8.decode(bytesList);
              } else {
                errorBody = response.data?.toString() ?? 'null';
              }
            } catch (e) {
              errorBody = 'Could not read error body: $e';
            }
            debugPrint('❌ [SSE] Server returned 400 Bad Request: $errorBody');
          }

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
            cancelToken?.cancel();
          }
        });

        final stream = response.data?.stream;
        if (stream == null) {
          throw Exception('SSE stream is null');
        }

        final lines = stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        String? currentEventType;

        await for (final line in lines) {
          if (cancelToken?.isCancelled ?? false) break;
          // debugPrint('📥 [SSE Raw Line] "$line"');
          if (line.isEmpty) continue;

          if (line.startsWith('event: ')) {
            currentEventType = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            final dataString = line.substring(6).trim();
            // debugPrint('📨 [SSE] Event: $currentEventType | Data: $dataString');

            if (currentEventType == 'heartbeat') {
              lastHeartbeatReceived = DateTime.now();
            }

            try {
              final Map<String, dynamic> data = jsonDecode(dataString);
              if (data['type'] == 'price_update') {
                debugPrint('🔍 [SSE Raw Data] $data');
                final instId = data['instrumentId']?.toString();
                if (instId != null) {
                  if ((instId == 'stock:ADBE' || instId == 'ADBE') &&
                      (instruments.contains('AADBE') || instruments.contains('stock:AADBE'))) {
                    data['instrumentId'] = instId.replaceFirst('ADBE', 'AADBE');
                  }
                }
                debugPrint('📈 [SSE] Decoded price update: ${data['symbol'] ?? data['instrumentId']} -> \$${data['price']} (Change: ${data['changePercent']}%)');
              }
              yield data;
            } catch (e) {
              debugPrint('❌ [SSE] Error decoding event data: $e');
              debugPrint('   Raw data: $dataString');
            }
          }
        }

      } catch (e) {
        if (cancelToken?.isCancelled ?? false) {
          debugPrint('🛑 [SSE] Stream explicitly cancelled (likely due to scrolling or navigation).');
        } else {
          debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
          debugPrint('║  [SSE] ERROR                                                   ║');
          debugPrint('╠══════════════════════════════════════════════════════════════╣');
          debugPrint('║  Error: $e');
          debugPrint('╚══════════════════════════════════════════════════════════════╝\n');
        }
      } finally {
        monitorTimer?.cancel();
      }

      if (cancelToken?.isCancelled ?? false) break;

      debugPrint('⏳ [SSE] Reconnecting in $retryDelaySec seconds...');
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

  static const String _keySearchHistory = 'local_search_history';

  static final List<Map<String, dynamic>> _allMockInstruments = [
    {
      'id': 'AAPL',
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'type': 'stock',
      'exchange': 'NASDAQ',
      'price': 178.72,
      'previousClose': 175.1,
      'change': 3.62,
      'changePercent': 2.07,
      'dayHigh': 179.43,
      'dayLow': 175.82,
      'volume': 58432100,
      'marketCap': 2780000000000,
      'logoUrl': 'https://picsum.photos/seed/aapl/200',
    },
    {
      'id': 'NVDA',
      'symbol': 'NVDA',
      'name': 'NVIDIA Corporation',
      'type': 'stock',
      'exchange': 'NASDAQ',
      'price': 875.3,
      'previousClose': 860.0,
      'change': 15.3,
      'changePercent': 1.78,
      'dayHigh': 882.15,
      'dayLow': 858.4,
      'volume': 45230800,
      'marketCap': 2160000000000,
      'logoUrl': 'https://picsum.photos/seed/nvda/200',
    },
    {
      'id': 'MSFT',
      'symbol': 'MSFT',
      'name': 'Microsoft Corporation',
      'type': 'stock',
      'exchange': 'NASDAQ',
      'price': 415.6,
      'previousClose': 412.35,
      'change': 3.25,
      'changePercent': 0.79,
      'dayHigh': 417.2,
      'dayLow': 411.8,
      'volume': 22145600,
      'marketCap': 3090000000000,
      'logoUrl': 'https://picsum.photos/seed/msft/200',
    },
    {
      'id': 'GOOGL',
      'symbol': 'GOOGL',
      'name': 'Alphabet Inc.',
      'type': 'stock',
      'exchange': 'NASDAQ',
      'price': 150.0,
      'previousClose': 148.5,
      'change': 1.5,
      'changePercent': 1.01,
      'dayHigh': 151.2,
      'dayLow': 147.8,
      'volume': 18900000,
      'marketCap': 1850000000000,
      'logoUrl': 'https://picsum.photos/seed/googl/200',
    },
    {
      'id': 'AMZN',
      'symbol': 'AMZN',
      'name': 'Amazon.com, Inc.',
      'type': 'stock',
      'exchange': 'NASDAQ',
      'price': 175.5,
      'previousClose': 174.0,
      'change': 1.5,
      'changePercent': 0.86,
      'dayHigh': 177.0,
      'dayLow': 173.5,
      'volume': 35400000,
      'marketCap': 1820000000000,
      'logoUrl': 'https://picsum.photos/seed/amzn/200',
    },
    {
      'id': 'BTC-USD',
      'symbol': 'BTC/USD',
      'name': 'Bitcoin',
      'type': 'crypto',
      'price': 67842.5,
      'previousClose': 66210.0,
      'change': 1632.5,
      'changePercent': 2.47,
      'logoUrl': 'https://picsum.photos/seed/btc/200',
    },
    {
      'id': 'ETH-USD',
      'symbol': 'ETH/USD',
      'name': 'Ethereum',
      'type': 'crypto',
      'price': 3842.75,
      'previousClose': 3780.0,
      'change': 62.75,
      'changePercent': 1.66,
      'logoUrl': 'https://picsum.photos/seed/eth/200',
    },
  ];

  Future<void> _saveLocalSearchQuery(String query) async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final history = prefs.getStringList(_keySearchHistory) ?? [];
      history.remove(query);
      history.insert(0, query);
      if (history.length > 20) {
        history.removeLast();
      }
      await prefs.setStringList(_keySearchHistory, history);
    } catch (e) {
      debugPrint('Error saving local search query: $e');
    }
  }

  List<String> _getLocalSearchHistory({int? limit}) {
    try {
      final prefs = di.sl<SharedPreferences>();
      final history = prefs.getStringList(_keySearchHistory) ?? [];
      if (limit != null && history.length > limit) {
        return history.take(limit).toList();
      }
      return history;
    } catch (e) {
      debugPrint('Error reading local search history: $e');
      return [];
    }
  }

  Future<void> _clearLocalSearchHistory() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.remove(_keySearchHistory);
    } catch (e) {
      debugPrint('Error clearing local search history: $e');
    }
  }

  @override
  Future<List<MarketInstrument>> searchInstruments(String query, {int? page, int? limit}) async {
    final url = AppConstants.search;
    final queryParams = {
      'q': query,
      'type': 'instruments',
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };

    try {
      final response = await _apiClient.dio.get(url, queryParameters: queryParams);
      final responseData = response.data;
      if (responseData == null) return [];

      final dataObj = responseData['data'] ?? {};
      final list = dataObj['instruments'] as List<dynamic>? ?? [];

      return list.whereType<Map>().map((item) {
        return MarketInstrument.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (e) {
      debugPrint('Error searching instruments from API: $e. Falling back to local/mock search.');

      final lowerQuery = query.toLowerCase();
      final filteredMock = _allMockInstruments.where((item) {
        final symbol = (item['symbol'] as String).toLowerCase();
        final name = (item['name'] as String).toLowerCase();
        return symbol.contains(lowerQuery) || name.contains(lowerQuery);
      }).map((item) => MarketInstrument.fromJson(item)).toList();

      return filteredMock;
    }
  }

  @override
  Future<List<String>> getSearchHistory({int? limit}) async {
    final url = AppConstants.searchHistory;
    final queryParams = {
      if (limit != null) 'limit': limit,
    };

    try {
      final response = await _apiClient.dio.get(url, queryParameters: queryParams);
      final responseData = response.data;
      if (responseData == null) return _getLocalSearchHistory(limit: limit);

      final dataObj = responseData['data'] ?? {};
      final list = dataObj['history'] as List<dynamic>? ?? [];
      final serverHistory = list
          .whereType<Map>()
          .map((item) => (item['query'] ?? '').toString())
          .where((q) => q.isNotEmpty)
          .toList();

      if (serverHistory.isEmpty) {
        return _getLocalSearchHistory(limit: limit);
      }
      return serverHistory;
    } catch (e) {
      debugPrint('Error getting search history from API: $e. Falling back to local history.');
      return _getLocalSearchHistory(limit: limit);
    }
  }

  @override
  Future<bool> clearSearchHistory() async {
    final url = AppConstants.searchHistory;
    try {
      await _clearLocalSearchHistory();
      final response = await _apiClient.dio.delete(url);
      final responseData = response.data;
      return responseData?['success'] == true;
    } catch (e) {
      debugPrint('Error clearing search history on API: $e. Local history cleared.');
      return true;
    }
  }

  @override
  Future<void> saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    try {
      await _saveLocalSearchQuery(query.trim());
    } catch (e) {
      debugPrint('Error saving search query to local history: $e');
    }
  }
}
