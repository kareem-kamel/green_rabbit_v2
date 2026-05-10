import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../market/data/models/market_instrument.dart';
import '../../data/models/watchlist_model.dart';
import '../../data/repositories/watchlist_repository_impl.dart';

class WatchlistState {
  final List<WatchlistModel> watchlists;
  final WatchlistModel? selectedWatchlist;
  final bool isLoading;

  WatchlistState({
    required this.watchlists,
    this.selectedWatchlist,
    this.isLoading = false,
  });

  WatchlistState copyWith({
    List<WatchlistModel>? watchlists,
    WatchlistModel? selectedWatchlist,
    bool? isLoading,
  }) {
    return WatchlistState(
      watchlists: watchlists ?? this.watchlists,
      selectedWatchlist: selectedWatchlist ?? this.selectedWatchlist,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final WatchlistRepository _repository;

  WatchlistNotifier(this._repository) : super(WatchlistState(watchlists: [])) {
    loadWatchlists();
  }

  Future<void> loadWatchlists() async {
    state = state.copyWith(isLoading: true);
    try {
      final watchlists = await _repository.getWatchlists();
      WatchlistModel? selected = state.selectedWatchlist;
      
      // If we have watchlists and none is selected, select the first one
      if (watchlists.isNotEmpty) {
        if (selected == null) {
          selected = watchlists.first;
        } else {
          // Update the selected watchlist if it exists in the new list
          selected = watchlists.firstWhere((w) => w.id == selected?.id, orElse: () => watchlists.first);
        }
      } else {
        selected = null;
      }
      
      state = state.copyWith(watchlists: watchlists, selectedWatchlist: selected, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectWatchlist(WatchlistModel watchlist) {
    state = state.copyWith(selectedWatchlist: watchlist);
  }

  Future<void> createWatchlist(String name) async {
    try {
      final newWatchlist = await _repository.createWatchlist(name);
      state = state.copyWith(
        watchlists: [...state.watchlists, newWatchlist],
        selectedWatchlist: state.selectedWatchlist ?? newWatchlist,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> toggleInstrument(MarketInstrument instrument) async {
    // Ensure we have a watchlist to work with
    if (state.watchlists.isEmpty) {
      try {
        final newWatchlist = await _repository.createWatchlist('My Watchlist');
        state = state.copyWith(
          watchlists: [newWatchlist],
          selectedWatchlist: newWatchlist,
        );
      } catch (e) {
        return false;
      }
    }

    final selected = state.selectedWatchlist;
    if (selected == null) return false;

    final isAdded = selected.instruments.any((i) => i.id == instrument.id);
    
    try {
      if (isAdded) {
        await _repository.removeFromWatchlist(selected.id, instrument.id);
        
        // Optimistic UI update
        final updatedInstruments = selected.instruments.where((i) => i.id != instrument.id).toList();
        final updatedWatchlist = WatchlistModel(
          id: selected.id,
          name: selected.name,
          instrumentsCount: updatedInstruments.length,
          instruments: updatedInstruments,
          createdAt: selected.createdAt,
          updatedAt: DateTime.now(),
        );
        _updateLocalWatchlist(updatedWatchlist);
        return false;
      } else {
        await _repository.addToWatchlist(selected.id, instrument.id);
        
        // Optimistic UI update
        final updatedInstruments = [...selected.instruments, instrument];
        final updatedWatchlist = WatchlistModel(
          id: selected.id,
          name: selected.name,
          instrumentsCount: updatedInstruments.length,
          instruments: updatedInstruments,
          createdAt: selected.createdAt,
          updatedAt: DateTime.now(),
        );
        _updateLocalWatchlist(updatedWatchlist);
        return true;
      }
    } catch (e) {
      // Rollback or show error
      loadWatchlists(); // Full refresh on error
      return isAdded; // Return original state
    }
  }

  void _updateLocalWatchlist(WatchlistModel updated) {
    state = state.copyWith(
      watchlists: state.watchlists.map((w) => w.id == updated.id ? updated : w).toList(),
      selectedWatchlist: state.selectedWatchlist?.id == updated.id ? updated : state.selectedWatchlist,
    );
  }

  Future<void> reorder(String watchlistId, List<String> instrumentIds) async {
    try {
      await _repository.reorderInstruments(watchlistId, instrumentIds);
      // Wait for reorder to complete then refresh
      await loadWatchlists();
    } catch (e) {
      // Handle error
    }
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
      return WatchlistNotifier(sl<WatchlistRepository>());
    });

// Selector for knowing if an instrument is in the current watchlist
final isInstrumentInWatchlistProvider = Provider.family<bool, String>((ref, instrumentId) {
  final watchlistState = ref.watch(watchlistProvider);
  return watchlistState.selectedWatchlist?.instruments.any((i) => i.id == instrumentId) ?? false;
});
