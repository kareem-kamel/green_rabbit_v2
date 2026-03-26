import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart';
import '../../../market/data/models/market_instrument.dart';
import '../../data/repositories/watchlist_repository_impl.dart';

class WatchlistState {
  final List<MarketInstrument> items;
  final bool isLoading;

  WatchlistState({required this.items, this.isLoading = false});

  WatchlistState copyWith({List<MarketInstrument>? items, bool? isLoading}) {
    return WatchlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final WatchlistRepository _repository;

  WatchlistNotifier(this._repository) : super(WatchlistState(items: [])) {
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getWatchlists();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addInstrument(MarketInstrument instrument) async {
    try {
      await _repository.addToWatchlist(instrument.id);
      if (!state.items.any((i) => i.id == instrument.id)) {
        state = state.copyWith(items: [...state.items, instrument]);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeInstrument(String id) async {
    try {
      await _repository.removeFromWatchlist(id);
      state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
    } catch (e) {
      // Handle error
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
  return WatchlistNotifier(sl<WatchlistRepository>());
});
