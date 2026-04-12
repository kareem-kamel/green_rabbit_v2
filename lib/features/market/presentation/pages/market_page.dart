import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/profile/presentation/screens/profile_screen.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/sparkline_painter.dart';
import 'instrument_detail_page.dart';
import '../providers/market_providers.dart';
import '../../data/models/market_instrument.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'package:green_rabbit/features/market/presentation/pages/search_page.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth > 900 
                ? (constraints.maxWidth - 800) / 2 
                : AppTheme.paddingM + 4;

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
                          loading: () => const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          )),
                          error: (err, stack) => _buildErrorState(ref),
                        ),
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
          const Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please check your internet or API settings.', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => ref.refresh(marketOverviewProvider('stocks')),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mahmoud'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome,',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : Colors.black45, fontSize: 12),
              ),
              Text(
                'Mahmoud',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            child: _headerIcon(
              assetPath: 'assets/notification_icon.png',
              hasBadge: true,
              fallbackIcon: Icons.notifications_none,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
            },
            child: _headerIcon(icon: Icons.search),
          ),
          const SizedBox(width: 12),
          _headerIcon(icon: Icons.menu),
        ],
      ),
    );
  }

  Widget _headerIcon({IconData? icon, String? assetPath, bool hasBadge = false, IconData? fallbackIcon}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: assetPath != null 
            ? Image.asset(
                assetPath,
                width: 22,
                height: 22,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon ?? Icons.error,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87,
                  size: 22,
                ),
              )
            : Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87, size: 22),
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
          // _tabItem('Indices'),
          // const SizedBox(width: 12),
          // _tabItem('Indices Futures'),
        ],
      ),
    );
  }

  Widget _tabItem(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.transparent : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive 
              ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.primary) 
              : Colors.grey,
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
    final isUp = instrument.change >= 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Logo Section
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: instrument.logoUrl != null 
              ? Image.network(
                  instrument.logoUrl!,
                  errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black45),
                )
              : Icon(Icons.diamond_outlined, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black45),
          ),
          const SizedBox(width: 16),
          // Name and Symbol Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.name,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${instrument.symbol} | 23/01',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price and Change Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                instrument.price.toStringAsFixed(2),
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isUp ? '+' : ''}${instrument.change.toStringAsFixed(2)} (${instrument.changePercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: isUp ? AppColors.success : AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
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
    return Stack(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28), // Increased bottom padding for dots
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark 
                        ? [const Color(0xFF2E246A), const Color(0xFF1B1839)]
                        : [AppColors.primaryPurple, const Color(0xFF6366F1)],
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['desc'],
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (index) {
              final bool isActive = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
