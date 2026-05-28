import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../providers/market_providers.dart';
import '../../data/models/market_instrument.dart';
import 'instrument_detail_page.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';
import 'package:green_rabbit/features/watchlist/presentation/providers/watchlist_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _idleTimer;
  Timer? _debounceTimer;
  String _debouncedQuery = '';
  String? _lastSavedQuery;
  late SearchHistoryNotifier _searchHistoryNotifier;

  @override
  void initState() {
    super.initState();
    _searchHistoryNotifier = ref.read(searchHistoryProvider.notifier);
  }

  void _saveFinalSearch() {
    _idleTimer?.cancel();
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();
    if (_debouncedQuery != query) {
      setState(() {
        _debouncedQuery = query;
      });
    }
    if (query.length >= 2) {
      if (query != _lastSavedQuery) {
        _lastSavedQuery = query;
        _searchHistoryNotifier.saveQuery(query);
      }
    } else {
      _lastSavedQuery = null;
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _debouncedQuery = val.trim();
        });
      }
    });
  }

  void _resetIdleTimer(String value) {
    _idleTimer?.cancel();
    if (value.trim().length >= 2) {
      _idleTimer = Timer(const Duration(seconds: 3), () {
        _saveFinalSearch();
      });
    }
  }

  @override
  void dispose() {
    _saveFinalSearch();
    _idleTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isQueryValid = _debouncedQuery.length >= 2;

    final searchAsync = isQueryValid 
        ? ref.watch(searchResultsProvider(_debouncedQuery)) 
        : const AsyncValue<List<MarketInstrument>>.data([]);
        
    final historyAsync = ref.watch(searchHistoryProvider);
    final popularAsync = ref.watch(marketOverviewProvider('stocks'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            Expanded(
              child: isQueryValid
                  ? searchAsync.when(
                      data: (instruments) => _buildContent(instruments, isDark),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                    )
                  : historyAsync.when(
                      data: (history) {
                        return popularAsync.when(
                          data: (popular) => _buildDefaultState(history, popular.take(5).toList(), isDark),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => _buildDefaultState(history, [], isDark),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color, size: 20),
            onPressed: () {
              _saveFinalSearch();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: AppSearchField(
              controller: _searchController,
              onChanged: (val) {
                if (val.trim().isEmpty) {
                  _debounceTimer?.cancel();
                  setState(() {
                    _debouncedQuery = '';
                  });
                  ref.invalidate(searchHistoryProvider);
                } else {
                  _onSearchChanged(val);
                }
                _lastSavedQuery = null;
                _resetIdleTimer(val);
              },
              onSubmitted: (val) {
                _saveFinalSearch();
              },
              hintText: 'Search here...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<MarketInstrument> instruments, bool isDark) {
    if (instruments.isEmpty) {
      return _buildNoResultsState(isDark);
    }
    return _buildActiveState(instruments, isDark);
  }

  Widget _buildDefaultState(List<String> history, List<MarketInstrument> popular, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent search',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
              ),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(searchHistoryProvider.notifier).clearHistory();
                  },
                  child: const Text('Clear all', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No search history yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            )
          else
            ...history.map((search) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _debounceTimer?.cancel();
                      _idleTimer?.cancel();
                      _searchController.text = search;
                      _lastSavedQuery = search;
                      setState(() {
                        _debouncedQuery = search;
                      });
                    },
                    child: Text(search, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
                  ),
                ],
              ),
            )),
          const SizedBox(height: 24),
          Text(
            'Popular',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _instrumentSearchItem(popular[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveState(List<MarketInstrument> filtered, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4, vertical: 10),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _instrumentSearchItem(filtered[index]),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textPrimary.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search, color: isDark ? AppColors.textMuted : Colors.black38, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find what you\'re looking for. Try a different symbol or name',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.textMuted : Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instrumentSearchItem(MarketInstrument instrument) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _saveFinalSearch();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InstrumentDetailPage(instrumentId: instrument.id),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${instrument.symbol} | ${instrument.exchange ?? 'Market'}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          (() {
            final isInWatchlist = ref.watch(isInstrumentInWatchlistProvider(instrument.id));
            return IconButton(
              onPressed: () {
                ref.read(watchlistProvider.notifier).toggleInstrument(instrument);
                if (!isInWatchlist) {
                  _showSuccessSnackBar(context, instrument);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${instrument.symbol} removed from watchlist')),
                  );
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInWatchlist ? AppColors.success.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: isInWatchlist ? AppColors.success : (isDark ? Colors.white24 : Colors.black26)),
                ),
                child: Icon(
                  isInWatchlist ? Icons.check : Icons.add, 
                  color: isInWatchlist ? AppColors.success : (isDark ? Colors.white70 : Colors.black54), 
                  size: 12,
                ),
              ),
            );
          })(),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, MarketInstrument instrument) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (!isDark) BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${instrument.name} ${instrument.symbol} successfully added to watchlist',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ref.read(navigationIndexProvider.notifier).state = 1;
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: Color(0xFF4072FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
