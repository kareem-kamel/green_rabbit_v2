import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../market/data/models/market_instrument.dart';
import '../../../market/data/models/market_instrument_detail.dart';
import '../../data/models/watchlist_model.dart';
import '../../data/repositories/watchlist_repository_impl.dart';
import '../../../market/presentation/providers/market_providers.dart';
import '../../../news/data/models/news_model.dart';

class WatchlistState {
  final List<WatchlistModel> watchlists;
  final WatchlistModel? selectedWatchlist;
  final bool isLoading;
  final String? error;

  WatchlistState({
    required this.watchlists,
    this.selectedWatchlist,
    this.isLoading = false,
    this.error,
  });

  WatchlistState copyWith({
    List<WatchlistModel>? watchlists,
    WatchlistModel? selectedWatchlist,
    bool? isLoading,
    String? error,
  }) {
    return WatchlistState(
      watchlists: watchlists ?? this.watchlists,
      selectedWatchlist: selectedWatchlist ?? this.selectedWatchlist,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final WatchlistRepository _repository;
  final Ref _ref;
  ProviderSubscription? _livePricesSubscription;

  WatchlistNotifier(this._repository, this._ref) : super(WatchlistState(watchlists: [])) {
    loadWatchlists();
    _updateLivePricesSubscription();
  }

  @override
  void dispose() {
    _livePricesSubscription?.close();
    super.dispose();
  }

  void _updateLivePricesSubscription() {
    _livePricesSubscription?.close();
    _livePricesSubscription = _ref.listen<Map<String, LivePriceUpdate>>(
      globalLivePricesProvider,
      (previous, next) {
        if (state.selectedWatchlist == null) return;
        
        bool updated = false;
        final instruments = state.selectedWatchlist!.instruments.map((instrument) {
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
          final updatedWatchlist = WatchlistModel(
            id: state.selectedWatchlist!.id,
            name: state.selectedWatchlist!.name,
            instrumentsCount: state.selectedWatchlist!.instrumentsCount,
            createdAt: state.selectedWatchlist!.createdAt,
            updatedAt: state.selectedWatchlist!.updatedAt,
            instruments: instruments,
          );
          state = state.copyWith(
            selectedWatchlist: updatedWatchlist,
            watchlists: state.watchlists.map((w) => w.id == updatedWatchlist.id ? updatedWatchlist : w).toList(),
          );
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> loadWatchlists() async {
    state = state.copyWith(isLoading: true, error: null);
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
      
      state = state.copyWith(watchlists: watchlists, selectedWatchlist: selected, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      return WatchlistNotifier(sl<WatchlistRepository>(), ref);
    });

// Selector for knowing if an instrument is in the current watchlist
final isInstrumentInWatchlistProvider = Provider.family<bool, String>((ref, instrumentId) {
  final watchlistState = ref.watch(watchlistProvider);
  return watchlistState.selectedWatchlist?.instruments.any((i) => i.id == instrumentId) ?? false;
});

final watchlistNewsProvider = FutureProvider.autoDispose<List<NewsArticle>>((ref) async {
  final idsString = ref.watch(watchlistProvider.select((state) {
    final watchlistId = state.selectedWatchlist?.id ?? '';
    final ids = state.selectedWatchlist?.instruments.map((i) => i.id).join(',') ?? '';
    return '$watchlistId|$ids';
  }));

  if (idsString.isEmpty || idsString.startsWith('|')) return [];

  final watchlistState = ref.read(watchlistProvider);
  final instruments = watchlistState.selectedWatchlist?.instruments ?? [];
  if (instruments.isEmpty) return [];

  final marketRepository = ref.watch(marketRepositoryProvider);
  final List<NewsArticle> allArticles = [];
  final Set<String> seenIds = {};

  // Fetch news for each instrument in parallel from marketRepository, preventing 429 errors
  final results = await Future.wait(
    instruments.map((inst) async {
      try {
        return await marketRepository.getInstrumentNews(inst.id, type: inst.type);
      } catch (e) {
        return <MarketNewsArticle>[];
      }
    }),
  );

  for (int i = 0; i < results.length; i++) {
    final instrument = instruments[i];
    final articles = results[i];
    for (final article in articles) {
      final url = article.url ?? '';
      final title = article.title;
      final publishedAt = article.publishedAt ?? DateTime.now().toIso8601String();
      final id = url.isNotEmpty ? url.hashCode.toString() : title.hashCode.toString();
      
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        allArticles.add(
          NewsArticle(
            id: id,
            title: title,
            summary: article.summary ?? '',
            imageUrl: article.imageUrl ?? '',
            sourceName: article.source ?? 'News',
            sourceLogo: article.sourceLogoUrl ?? '',
            publishedAt: publishedAt,
            isBookmarked: false,
            url: url,
            sentiment: article.sentiment ?? '',
            readTimeMinutes: article.readTimeMinutes ?? 0,
            type: instrument.type,
          ),
        );
      }
    }
  }

  // Sort by publishedAt desc
  allArticles.sort((a, b) {
    try {
      final aDate = DateTime.parse(a.publishedAt);
      final bDate = DateTime.parse(b.publishedAt);
      return bDate.compareTo(aDate);
    } catch (_) {
      return 0;
    }
  });

  return allArticles;
});
