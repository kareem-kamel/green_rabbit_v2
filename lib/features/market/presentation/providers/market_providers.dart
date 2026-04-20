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

final trendingInstrumentsProvider = FutureProvider.autoDispose<List<MarketInstrument>>((ref) async {
  return ref.watch(marketRepositoryProvider).getTrendingInstruments();
});

final instrumentNewsProvider = FutureProvider.autoDispose.family<List<MarketNewsArticle>, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentNews(id);
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
