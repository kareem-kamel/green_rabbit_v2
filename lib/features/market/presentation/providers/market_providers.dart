import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/market_instrument.dart';
import '../../data/models/market_instrument_detail.dart';
import '../../data/repositories/market_repository_impl.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) => sl<MarketRepository>());

final marketOverviewLoadingMoreProvider = StateProvider.family<bool, String>((ref, type) => false);

class MarketOverviewNotifier extends StateNotifier<AsyncValue<List<MarketInstrument>>> {
  final MarketRepository _repository;
  final String _type;
  final Ref _ref;
  final String _searchQuery;

  int _currentPage = 1;
  bool _hasNext = true;
  List<MarketInstrument> _instruments = [];
  ProviderSubscription? _livePricesSubscription;

  MarketOverviewNotifier(this._repository, this._type, this._ref, this._searchQuery)
      : super(const AsyncValue.loading()) {
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _livePricesSubscription?.close();
    super.dispose();
  }

  Future<void> _fetchFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.getMarketOverview(
        _type,
        search: _searchQuery,
        page: 1,
        limit: 20,
      );
      _currentPage = 1;
      _hasNext = response.meta.hasNext;
      _instruments = response.instruments;
      state = AsyncValue.data(_instruments);
      _updateLivePricesSubscription();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadNextPage() async {
    final isLoadingMore = _ref.read(marketOverviewLoadingMoreProvider(_type));
    if (isLoadingMore || !_hasNext) return;

    _ref.read(marketOverviewLoadingMoreProvider(_type).notifier).state = true;

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getMarketOverview(
        _type,
        search: _searchQuery,
        page: nextPage,
        limit: 20,
      );
      
      _currentPage = nextPage;
      _hasNext = response.meta.hasNext;
      _instruments.addAll(response.instruments);
      state = AsyncValue.data(List.of(_instruments));
      _updateLivePricesSubscription();
    } catch (e) {
      debugPrint('Error loading next page for type $_type: $e');
    } finally {
      _ref.read(marketOverviewLoadingMoreProvider(_type).notifier).state = false;
    }
  }

  void _updateLivePricesSubscription() {
    _livePricesSubscription?.close();
    _livePricesSubscription = null;

    _livePricesSubscription = _ref.listen<Map<String, LivePriceUpdate>>(
      globalLivePricesProvider,
      (previous, next) {
        bool updated = false;
        _instruments = _instruments.map((instrument) {
          final cleanInstId = instrument.id.contains(':') ? instrument.id.split(':')[1] : instrument.id;
          final update = next[cleanInstId];
          if (update != null) {
            if (update.price != instrument.price ||
                update.change != instrument.change ||
                update.changePercent != instrument.changePercent) {
              updated = true;
              return instrument.copyWith(
                price: update.price,
                change: update.change,
                changePercent: update.changePercent,
              );
            }
          }
          return instrument;
        }).toList();

        if (updated) {
          state = AsyncValue.data(List.of(_instruments));
        }
      },
      fireImmediately: true,
    );
  }
}

final marketOverviewProvider = StateNotifierProvider.autoDispose.family<MarketOverviewNotifier, AsyncValue<List<MarketInstrument>>, String>((ref, type) {
  final repository = ref.watch(marketRepositoryProvider);
  final searchQuery = ref.watch(marketSearchQueryProvider);
  return MarketOverviewNotifier(repository, type, ref, searchQuery);
});

final livePricesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  // Disabled background stream for debugging as requested to "remove that we call all apis"
  return const Stream.empty();
});

final marketLivePricesProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, instrumentIdsString) {
  if (instrumentIdsString.isEmpty) return const Stream.empty();
  final instrumentIds = instrumentIdsString.split(',');
  final repository = ref.watch(marketRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() {
    cancelToken.cancel();
  });
  return repository.getMarketStream(instrumentIds, cancelToken: cancelToken);
});

class LivePriceUpdate {
  final double price;
  final double change;
  final double changePercent;
  final String? timestamp;

  LivePriceUpdate({
    required this.price,
    required this.change,
    required this.changePercent,
    this.timestamp,
  });
}

final globalLivePricesProvider = StateProvider<Map<String, LivePriceUpdate>>((ref) => {});

final isDetailsPageActiveProvider = StateProvider<bool>((ref) => false);
final visibleInstrumentsProvider = StateProvider<List<String>>((ref) => []);

final visibleMarketLivePricesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final isDetailsActive = ref.watch(isDetailsPageActiveProvider);
  if (isDetailsActive) {
    debugPrint('⏸️ [SSE] Pausing Market stream because Details page is active');
    return const Stream.empty();
  }

  final visibleIds = ref.watch(visibleInstrumentsProvider);
  if (visibleIds.isEmpty) return const Stream.empty();

  final repository = ref.watch(marketRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() {
    cancelToken.cancel();
  });
  
  debugPrint('[SSE] visibleMarketLivePricesProvider establishing stream for: $visibleIds');
  final stream = repository.getMarketStream(visibleIds, cancelToken: cancelToken);

  return stream.map((data) {
    if (data['type'] == 'price_update') {
      final instrumentId = data['instrumentId']?.toString();
      final price = (data['price'] as num?)?.toDouble();
      final change = (data['change'] as num?)?.toDouble();
      final changePercent = (data['changePercent'] as num?)?.toDouble();
      if (instrumentId != null && price != null && change != null && changePercent != null) {
        final cleanId = instrumentId.contains(':') ? instrumentId.split(':')[1] : instrumentId;
        ref.read(globalLivePricesProvider.notifier).update((state) => {
          ...state,
          cleanId: LivePriceUpdate(
            price: price,
            change: change,
            changePercent: changePercent,
            timestamp: data['timestamp']?.toString(),
          ),
        });
      }
    }
    return data;
  });
});

final instrumentDetailsProvider = FutureProvider.autoDispose.family<MarketInstrumentDetail, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentDetails(id);
});

final instrumentLivePriceProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  final repository = ref.watch(marketRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() {
    cancelToken.cancel();
  });
  final stream = repository.getMarketStream([id], cancelToken: cancelToken);

  return stream.map((data) {
    if (data['type'] == 'price_update') {
      final instrumentId = data['instrumentId']?.toString();
      final price = (data['price'] as num?)?.toDouble();
      final change = (data['change'] as num?)?.toDouble();
      final changePercent = (data['changePercent'] as num?)?.toDouble();
      if (instrumentId != null && price != null && change != null && changePercent != null) {
        final cleanId = instrumentId.contains(':') ? instrumentId.split(':')[1] : instrumentId;
        ref.read(globalLivePricesProvider.notifier).update((state) => {
          ...state,
          cleanId: LivePriceUpdate(
            price: price,
            change: change,
            changePercent: changePercent,
            timestamp: data['timestamp']?.toString(),
          ),
        });
      }
    }
    return data;
  });
});

class LiveInstrumentDetailNotifier extends StateNotifier<AsyncValue<MarketInstrumentDetail>> {
  final Ref _ref;
  final String _instrumentId;

  LiveInstrumentDetailNotifier(this._ref, this._instrumentId) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<MarketInstrumentDetail>>(
      instrumentDetailsProvider(_instrumentId),
      (previous, next) {
        if (next is AsyncData<MarketInstrumentDetail>) {
          var detail = next.value;
          final cachedPrices = _ref.read(globalLivePricesProvider);
          final cleanId = _instrumentId.contains(':') ? _instrumentId.split(':')[1] : _instrumentId;
          final cached = cachedPrices[cleanId];
          if (cached != null) {
            detail = MarketInstrumentDetail(
              id: detail.id,
              symbol: detail.symbol,
              name: detail.name,
              type: detail.type,
              exchange: detail.exchange,
              sector: detail.sector,
              industry: detail.industry,
              currency: detail.currency,
              description: detail.description,
              website: detail.website,
              logoUrl: detail.logoUrl,
              country: detail.country,
              price: PriceInfo(
                current: cached.price,
                change: cached.change,
                changePercent: cached.changePercent,
                dayHigh: detail.price.dayHigh,
                dayLow: detail.price.dayLow,
                lastUpdatedAt: cached.timestamp ?? detail.price.lastUpdatedAt,
                previousClose: detail.price.previousClose,
                open: detail.price.open,
                week52High: detail.price.week52High,
                week52Low: detail.price.week52Low,
              ),
              volume: detail.volume,
              fundamentals: detail.fundamentals,
              marketStatus: detail.marketStatus,
              tradingHours: detail.tradingHours,
              relatedInstruments: detail.relatedInstruments,
              contracts: detail.contracts,
              comments: detail.comments,
              cryptoMetrics: detail.cryptoMetrics,
              forexMetrics: detail.forexMetrics,
            );
          }
          state = AsyncValue.data(detail);
        } else if (next is AsyncError<MarketInstrumentDetail>) {
          state = next;
        }
      },
      fireImmediately: true,
    );

    _ref.listen<AsyncValue<Map<String, dynamic>>>(
      instrumentLivePriceProvider(_instrumentId),
      (previous, next) {
        if (next is AsyncError) {
          debugPrint('❌ [Details] instrumentLivePriceProvider Error: ${next.error}\n${next.stackTrace}');
        }
      },
      fireImmediately: true,
    );

    _ref.listen<Map<String, LivePriceUpdate>>(
      globalLivePricesProvider,
      (previous, next) {
        final cleanDetailId = _instrumentId.contains(':') ? _instrumentId.split(':')[1] : _instrumentId;
        final update = next[cleanDetailId];
        final currentDetail = state.valueOrNull;
        if (update != null && currentDetail != null) {
          if (update.price != currentDetail.price.current ||
              update.change != currentDetail.price.change ||
              update.changePercent != currentDetail.price.changePercent) {
            
            final priceUpdate = PriceInfo(
              current: update.price,
              change: update.change,
              changePercent: update.changePercent,
              dayHigh: currentDetail.price.dayHigh,
              dayLow: currentDetail.price.dayLow,
              lastUpdatedAt: update.timestamp ?? currentDetail.price.lastUpdatedAt,
              previousClose: currentDetail.price.previousClose,
              open: currentDetail.price.open,
              week52High: currentDetail.price.week52High,
              week52Low: currentDetail.price.week52Low,
            );

            state = AsyncValue.data(MarketInstrumentDetail(
              id: currentDetail.id,
              symbol: currentDetail.symbol,
              name: currentDetail.name,
              type: currentDetail.type,
              exchange: currentDetail.exchange,
              sector: currentDetail.sector,
              industry: currentDetail.industry,
              currency: currentDetail.currency,
              description: currentDetail.description,
              website: currentDetail.website,
              logoUrl: currentDetail.logoUrl,
              country: currentDetail.country,
              price: priceUpdate,
              volume: currentDetail.volume,
              fundamentals: currentDetail.fundamentals,
              marketStatus: currentDetail.marketStatus,
              tradingHours: currentDetail.tradingHours,
              relatedInstruments: currentDetail.relatedInstruments,
              contracts: currentDetail.contracts,
              comments: currentDetail.comments,
              cryptoMetrics: currentDetail.cryptoMetrics,
              forexMetrics: currentDetail.forexMetrics,
            ));
          }
        }
      },
      fireImmediately: true,
    );
  }
}

final liveInstrumentDetailProvider = StateNotifierProvider.autoDispose.family<LiveInstrumentDetailNotifier, AsyncValue<MarketInstrumentDetail>, String>((ref, id) {
  return LiveInstrumentDetailNotifier(ref, id);
});

class TrendingInstrumentsNotifier extends StateNotifier<AsyncValue<List<MarketInstrument>>> {
  final MarketRepository _repository;
  final String? _type;
  final Ref _ref;
  ProviderSubscription? _livePricesSubscription;
  List<MarketInstrument> _instruments = [];

  TrendingInstrumentsNotifier(this._repository, this._type, this._ref)
      : super(const AsyncValue.loading()) {
    _fetchTrending();
  }

  @override
  void dispose() {
    _livePricesSubscription?.close();
    super.dispose();
  }

  Future<void> _fetchTrending() async {
    state = const AsyncValue.loading();
    try {
      _instruments = await _repository.getTrendingInstruments(type: _type);
      state = AsyncValue.data(_instruments);
      _updateLivePricesSubscription();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _updateLivePricesSubscription() {
    _livePricesSubscription?.close();
    _livePricesSubscription = null;

    _livePricesSubscription = _ref.listen<Map<String, LivePriceUpdate>>(
      globalLivePricesProvider,
      (previous, next) {
        bool updated = false;
        _instruments = _instruments.map((instrument) {
          final cleanInstId = instrument.id.contains(':') ? instrument.id.split(':')[1] : instrument.id;
          final update = next[cleanInstId];
          if (update != null) {
            if (update.price != instrument.price ||
                update.change != instrument.change ||
                update.changePercent != instrument.changePercent) {
              updated = true;
              return instrument.copyWith(
                price: update.price,
                change: update.change,
                changePercent: update.changePercent,
              );
            }
          }
          return instrument;
        }).toList();

        if (updated) {
          state = AsyncValue.data(List.of(_instruments));
        }
      },
      fireImmediately: true,
    );
  }
}

final trendingInstrumentsProvider = StateNotifierProvider.autoDispose.family<TrendingInstrumentsNotifier, AsyncValue<List<MarketInstrument>>, String?>((ref, type) {
  final repository = ref.watch(marketRepositoryProvider);
  return TrendingInstrumentsNotifier(repository, type, ref);
});

final instrumentNewsProvider = FutureProvider.autoDispose.family<List<MarketNewsArticle>, String>((ref, param) async {
  // Expected param format: "instrumentId|type" or just "instrumentId"
  final parts = param.split('|');
  final id = parts[0];
  final type = parts.length > 1 ? parts[1] : null;
  
  debugPrint('[DEBUG] Riverpod instrumentNewsProvider called with ID: $id, type: $type');
  return ref.watch(marketRepositoryProvider).getInstrumentNews(id, type: type);
});

final instrumentStatsProvider = FutureProvider.autoDispose.family<MarketInstrumentStats, String>((ref, param) async {
  // Expected param format: "instrumentId|interval"
  final parts = param.split('|');
  final id = parts[0];
  final interval = parts.length > 1 ? parts[1] : null;
  
  return ref.watch(marketRepositoryProvider).getInstrumentStats(id, interval: interval);
});

final instrumentChartProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, param) async {
  // Expected param format: "instrumentId|period|interval"
  final parts = param.split('|');
  final id = parts[0];
  final period = parts.length > 1 ? parts[1] : null;
  final interval = (parts.length > 2 && parts[2] != '' && parts[2] != 'null') ? parts[2] : null;
  
  return ref.watch(marketRepositoryProvider).getInstrumentChart(id, period: period, interval: interval);
});

final marketSearchQueryProvider = StateProvider<String>((ref) => '');

class SearchHistoryNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final MarketRepository _repository;

  SearchHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _repository.getSearchHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearHistory() async {
    final previousState = state;
    state = const AsyncValue.data([]);
    final success = await _repository.clearSearchHistory();
    if (!success) {
      state = previousState;
    }
  }

  Future<void> saveQuery(String query) async {
    if (query.trim().isEmpty) return;
    try {
      await _repository.saveSearchHistory(query.trim());
      final history = await _repository.getSearchHistory();
      state = AsyncValue.data(history);
    } catch (e) {
      debugPrint('Error saving search query: $e');
    }
  }
}

final searchHistoryProvider = StateNotifierProvider.autoDispose<SearchHistoryNotifier, AsyncValue<List<String>>>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  return SearchHistoryNotifier(repository);
});

final searchResultsProvider = FutureProvider.autoDispose.family<List<MarketInstrument>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.watch(marketRepositoryProvider).searchInstruments(query.trim());
});
