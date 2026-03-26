import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/sparkline_painter.dart';
import 'instrument_detail_page.dart';
import '../providers/market_providers.dart';
import '../../data/models/market_instrument.dart';
import 'search_page.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ref.read(marketSearchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketSearchQuery = ref.watch(marketSearchQueryProvider);
    final marketData = ref.watch(marketOverviewProvider('stocks'));
    final liveData = ref.watch(livePricesProvider);
    
    final instrumentsAsync = liveData.asData != null ? liveData : marketData;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(context, ref),
                const SizedBox(height: 24),
                const AIServiceCarousel(),
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'Market'),
                const SizedBox(height: 16),
                _buildTabs(context),
                const SizedBox(height: 20),
                instrumentsAsync.when(
                  data: (instruments) {
                    final filtered = instruments.where((i) => 
                      i.symbol.toLowerCase().contains(marketSearchQuery.toLowerCase()) ||
                      i.name.toLowerCase().contains(marketSearchQuery.toLowerCase())
                    ).toList();
                    return _buildInstrumentList(context, ref, filtered);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildErrorState(ref),
                ),
                const SizedBox(height: 100), // Added safe margin above bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          const Text('Connection Error', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please check your internet or API settings.', style: TextStyle(color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.refresh(marketOverviewProvider('stocks')),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mahmoud'),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              'Mahmoud',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppSearchField(
            readOnly: false,
            controller: _searchController,
          ),
        ),
        const SizedBox(width: 12),
        _headerIcon(Icons.notifications_none, hasBadge: true),
        const SizedBox(width: 12),
        _headerIcon(Icons.menu),
      ],
    );
  }

  Widget _headerIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        if (hasBadge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabItem('Popular', isActive: true),
          const SizedBox(width: 12),
          _tabItem('Indices'),
          const SizedBox(width: 12),
          _tabItem('Indices Futures'),
        ],
      ),
    );
  }

  Widget _tabItem(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.transparent : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildInstrumentList(BuildContext context, WidgetRef ref, List<MarketInstrument> instruments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: instruments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return _instrumentCard(
          context: context,
          ref: ref,
          instrument: instrument,
        );
      },
    );
  }

  Widget _instrumentCard({
    required BuildContext context,
    required WidgetRef ref,
    required MarketInstrument instrument,
  }) {
    final isUp = instrument.change > 0;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstrumentDetailPage(instrumentId: instrument.id),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: instrument.logoUrl != null 
              ? Image.network(
                  instrument.logoUrl!,
                  errorBuilder: (_, __, ___) => const Icon(Icons.diamond_outlined, color: AppColors.textSecondary),
                )
              : const Icon(Icons.diamond_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.symbol,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  instrument.name,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (instrument.sparkline != null && instrument.sparkline!.isNotEmpty)
            SizedBox(
              width: 60,
              height: 30,
              child: CustomPaint(
                painter: SparklinePainter(
                  instrument.sparkline!,
                  isUp ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${instrument.price.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${isUp ? '+' : ''}${instrument.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isUp ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
            onPressed: () {
              ref.read(watchlistProvider.notifier).addInstrument(instrument);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${instrument.symbol} added to Watchlist')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AIServiceCarousel extends StatefulWidget {
  const AIServiceCarousel({super.key});

  @override
  State<AIServiceCarousel> createState() => _AIServiceCarouselState();
}

class _AIServiceCarouselState extends State<AIServiceCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'AI Trading Assistant',
      'desc': 'Understand prices, indicators, and news with AI-powered explanations',
      'image': 'assets/component_1.png',
    },
    {
      'title': 'AI News Summaries',
      'desc': 'Turns complex financial news into short, easy-to-read insights',
      'image': 'assets/component_2.png',
    },
    {
      'title': 'Watchlist Insights',
      'desc': 'Summarizes key changes across your tracked assets',
      'image': 'assets/component_3.png',
    },
    {
      'title': 'Market Pattern Detection',
      'desc': 'Identifies repeating patterns and notable market behavior',
      'image': 'assets/component_4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        item['image'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['desc'],
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == index ? 24 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
