import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../market/presentation/pages/instrument_detail_page.dart';
import '../providers/watchlist_providers.dart';
import '../../../../shared/widgets/main_wrapper.dart';

class WatchlistPage extends ConsumerWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistState = ref.watch(watchlistProvider);

    if (watchlistState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = constraints.maxWidth > 900 
              ? (constraints.maxWidth - 800) / 2 
              : AppTheme.paddingM;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(context, ref, watchlistState),
                      const SizedBox(height: 24),
                      _buildAISummaryBanner(context),
                      const SizedBox(height: 24),
                      _buildTrackedSection(context, ref, watchlistState),
                      const SizedBox(height: 32),
                      _buildNewsSection(context),
                      const SizedBox(height: 100), // Added safe margin above bottom nav
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, WatchlistState state) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Watchlist',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (state.selectedWatchlist != null)
              Text(
                state.selectedWatchlist!.name,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
          ],
        ),
        const Spacer(),
        if (state.watchlists.length > 1)
          IconButton(
            icon: Icon(Icons.swap_horiz, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black),
            onPressed: () => _showWatchlistPicker(context, ref, state),
          ),
        _headerIcon(context, Icons.filter_alt_outlined),
        const SizedBox(width: 12),
        _headerIcon(context, Icons.menu),
      ],
    );
  }

  Widget _headerIcon(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87, size: 22),
    );
  }

  Widget _buildAISummaryBanner(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E246A), Color(0xFF1B1839)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/watchlist.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Watchlist Summarize',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Smart insights based on today\'s market news',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_outward, color: Colors.white70, size: 24),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.black87, size: 14),
                SizedBox(width: 4),
                Text(
                  'Free Trial',
                  style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackedSection(BuildContext context, WidgetRef ref, WatchlistState state) {
    final instruments = state.selectedWatchlist?.instruments ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Instruments (${instruments.length})',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (state.selectedWatchlist != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                onPressed: () {
                  // Navigate to market to add more
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (instruments.isEmpty)
          _buildEmptyState(context, ref),
        if (instruments.isNotEmpty)
          ...instruments.map((instrument) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Dismissible(
              key: Key('${state.selectedWatchlist!.id}_${instrument.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                ref.read(watchlistProvider.notifier).toggleInstrument(instrument);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              child: _stockItem(
                context,
                instrument.name,
                instrument.symbol,
                instrument.price?.toStringAsFixed(2) ?? 'N/A',
                '${(instrument.change ?? 0) >= 0 ? '+' : ''}${instrument.change?.toStringAsFixed(2) ?? '0.00'} (${instrument.changePercent?.toStringAsFixed(2) ?? '0.00'}%)',
                (instrument.change ?? 0) >= 0,
                logoUrl: instrument.logoUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstrumentDetailPage(instrumentId: instrument.id),
                    ),
                  );
                },
              ),
            ),
          )),
      ],
    );
  }

  void _showWatchlistPicker(BuildContext context, WidgetRef ref, WatchlistState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('My Watchlists', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...state.watchlists.map((w) => ListTile(
            leading: Icon(Icons.list, color: state.selectedWatchlist?.id == w.id ? AppColors.primary : Colors.grey),
            title: Text(w.name, style: const TextStyle(color: Colors.white)),
            trailing: Text('${w.instrumentsCount} items', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              ref.read(watchlistProvider.notifier).selectWatchlist(w);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/empty_watchlist.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Build your watchlist',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Set price alerts for your favorite assets and never miss a market move',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Market tab
                ref.read(navigationIndexProvider.notifier).state = 0;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFF4A3BC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Explore Now',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockItem(BuildContext context, String name, String ticker, String price, String change, bool isUp, {String? logoUrl, VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.unfold_more, color: AppColors.textMuted, size: 24),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon(name))
                : _fallbackIcon(name),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('$ticker | 23/01', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(String name) {
    return Center(
      child: Icon(
        name.toLowerCase().contains('bit') ? Icons.currency_bitcoin : Icons.diamond_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Watchlist News',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View all', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _newsItem(
          context,
          'NVIDIA',
          'The United States is bracing for a winter storm that will impact the energy sector.',
          'Reuters . 3 hours ago',
          'https://upload.wikimedia.org/wikipedia/sco/thumb/2/21/Nvidia_logo.svg/1200px-Nvidia_logo.svg.png',
        ),
      ],
    );
  }

  Widget _newsItem(BuildContext context, String source, String title, String meta, String imageUrl) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceLight, width: 90, height: 90)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATCOa -0.47% ATLCY -0.22', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('$source . 3 hours ago', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.mode_comment_outlined, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 4),
                        const Text('2', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
