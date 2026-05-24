import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/market_instrument.dart';
import '../../data/models/market_instrument_detail.dart';
import '../../data/repositories/market_repository_impl.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) => sl<MarketRepository>());

final marketOverviewProvider = FutureProvider.autoDispose.family<List<MarketInstrument>, String>((ref, type) async {
  final searchQuery = ref.watch(marketSearchQueryProvider);
  return ref.watch(marketRepositoryProvider).getMarketOverview(type, search: searchQuery);
});

final livePricesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  // Disabled background stream for debugging as requested to "remove that we call all apis"
  return const Stream.empty();
});

final instrumentDetailsProvider = FutureProvider.autoDispose.family<MarketInstrumentDetail, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentDetails(id);
});

final instrumentLivePriceProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  final repository = ref.watch(marketRepositoryProvider);
  return repository.getMarketStream([id]);
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
        if (next is AsyncData<MarketInstrumentDetail> || next is AsyncError<MarketInstrumentDetail>) {
          state = next;
        }
      },
      fireImmediately: true,
    );

    _ref.listen<AsyncValue<Map<String, dynamic>>>(
      instrumentLivePriceProvider(_instrumentId),
      (previous, next) {
        next.whenData((liveUpdate) {
          if (liveUpdate['type'] == 'price_update' &&
              (liveUpdate['instrumentId'] == _instrumentId || liveUpdate['symbol'] == state.valueOrNull?.symbol)) {
            final currentDetail = state.valueOrNull;
            if (currentDetail != null) {
              final priceUpdate = PriceInfo(
                current: (liveUpdate['price'] as num?)?.toDouble() ?? currentDetail.price.current,
                change: (liveUpdate['change'] as num?)?.toDouble() ?? currentDetail.price.change,
                changePercent: (liveUpdate['changePercent'] as num?)?.toDouble() ?? currentDetail.price.changePercent,
                dayHigh: (liveUpdate['dayHigh'] as num?)?.toDouble() ?? currentDetail.price.dayHigh,
                dayLow: (liveUpdate['dayLow'] as num?)?.toDouble() ?? currentDetail.price.dayLow,
                lastUpdatedAt: liveUpdate['timestamp']?.toString() ?? currentDetail.price.lastUpdatedAt,
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
                volume: VolumeInfo(
                  current: liveUpdate['volume'] as num? ?? currentDetail.volume.current,
                  average10d: currentDetail.volume.average10d,
                  average3m: currentDetail.volume.average3m,
                ),
                fundamentals: currentDetail.fundamentals,
                marketStatus: currentDetail.marketStatus,
                tradingHours: currentDetail.tradingHours,
                relatedInstruments: currentDetail.relatedInstruments,
                contracts: currentDetail.contracts,
                comments: currentDetail.comments,
              ));
            }
          }
        });
      },
      fireImmediately: true,
    );
  }
}

final liveInstrumentDetailProvider = StateNotifierProvider.autoDispose.family<LiveInstrumentDetailNotifier, AsyncValue<MarketInstrumentDetail>, String>((ref, id) {
  return LiveInstrumentDetailNotifier(ref, id);
});

final trendingInstrumentsProvider = FutureProvider.autoDispose.family<List<MarketInstrument>, String?>((ref, type) async {
  return ref.watch(marketRepositoryProvider).getTrendingInstruments(type: type);
});

final instrumentNewsProvider = FutureProvider.autoDispose.family<List<MarketNewsArticle>, String>((ref, param) async {
  // Expected param format: "instrumentId|type" or just "instrumentId"
  final parts = param.split('|');
  final id = parts[0];
  final type = parts.length > 1 ? parts[1] : null;
  
  debugPrint('📰 [DEBUG] Riverpod instrumentNewsProvider called with ID: $id, type: $type');
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
