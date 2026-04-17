import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../providers/market_providers.dart';
import '../../data/models/market_instrument.dart';
import 'instrument_detail_page.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isActive = false;
  final List<String> _recentSearches = ['Apple', 'Microsoft', 'Google'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketAsync = ref.watch(marketOverviewProvider('stocks'));

    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: marketAsync.when(
                data: (instruments) => _buildContent(instruments),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: AppSearchField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _isActive = val.isNotEmpty;
                });
              },
              hintText: 'Search here...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<MarketInstrument> instruments) {
    final query = _searchController.text.toLowerCase();
    final filtered = instruments.where((i) => 
      i.symbol.toLowerCase().contains(query) ||
      i.name.toLowerCase().contains(query)
    ).toList();

    if (!_isActive && query.isEmpty) {
      return _buildDefaultState(instruments.take(5).toList());
    }
    
    if (filtered.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildActiveState(filtered);
  }

  Widget _buildDefaultState(List<MarketInstrument> popular) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent search',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ..._recentSearches.map((search) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Text(search, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.close, color: AppColors.textMuted, size: 18),
              ],
            ),
          )),
          const SizedBox(height: 24),
          const Text(
            'Popular',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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

  Widget _buildActiveState(List<MarketInstrument> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4, vertical: 10),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _instrumentSearchItem(filtered[index]),
    );
  }

  Widget _buildNoResultsState() {
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
                color: AppColors.textPrimary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: AppColors.textMuted, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'We couldn\'t find what you\'re looking for. Try a different symbol or name',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
                      color: isDark ? AppColors.textPrimary : Colors.black,
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
          IconButton(
            onPressed: () {
              ref.read(watchlistProvider.notifier).addInstrument(instrument);
              _showSuccessSnackBar(context, instrument);
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
              ),
              child: const Icon(Icons.add, color: Colors.white70, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, MarketInstrument instrument) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF4072FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popularStockItem(String name, String details, String price, String change, bool isUp) {
    // Keep for backward compatibility or remove if not used
    return const SizedBox.shrink();
  }
}
