import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/market_instrument.dart';
import '../../data/models/market_instrument_detail.dart';
import '../../data/repositories/market_repository_impl.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) => sl<MarketRepository>());

final marketOverviewProvider = FutureProvider.family<List<MarketInstrument>, String>((ref, type) async {
  return ref.watch(marketRepositoryProvider).getMarketOverview(type);
});

final livePricesProvider = StreamProvider<List<MarketInstrument>>((ref) async* {
  // Real-time integration placeholder
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
  }
});

final instrumentDetailsProvider = FutureProvider.family<MarketInstrumentDetail, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentDetails(id);
});

final trendingInstrumentsProvider = FutureProvider<List<MarketInstrument>>((ref) async {
  return ref.watch(marketRepositoryProvider).getTrendingInstruments();
});

final instrumentNewsProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentNews(id);
});

final instrumentStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentStats(id);
});

final instrumentChartProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(marketRepositoryProvider).getInstrumentChart(id);
});

final marketSearchQueryProvider = StateProvider<String>((ref) => '');
