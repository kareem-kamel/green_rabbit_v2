import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_search_field.dart';
import 'instrument_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isActive = false;
  final List<String> _recentSearches = ['History title', 'History title', 'History title'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingM + 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: AppSearchField(
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

  Widget _buildContent() {
    if (!_isActive && _searchController.text.isEmpty) {
      return _buildDefaultState();
    }
    
    // Simulate search logic for now
    if (_searchController.text == 'XYZ') {
      return _buildNoResultsState();
    }

    return _buildActiveState();
  }

  Widget _buildDefaultState() {
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
          _popularStockItem('Intel', 'INTC | 23/01', '45.07', '-9.25(-17.03%)', false),
        ],
      ),
    );
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4),
            itemCount: 3,
            itemBuilder: (context, index) {
              return _popularStockItem('Intel', 'INTC | 23/01', '45.07', '-9.25(-17.03%)', false, id: 'intel-id');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final types = ['All', 'Stocks', 'Funds', 'Forex'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.searchBarBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              types[index],
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
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

  Widget _popularStockItem(String name, String details, String price, String change, bool isUp, {String? id}) {
    return AppCard(
      onTap: () {
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentDetailPage(instrumentId: id),
            ),
          );
        }
      },
      backgroundColor: AppColors.searchBarBackground,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.diamond_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              Text(details, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              Text(change, style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
