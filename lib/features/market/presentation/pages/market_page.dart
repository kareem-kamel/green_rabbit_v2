import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_state.dart';
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
  String _selectedType = 'stocks';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    
    // Ensure profile data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().getProfile();
    });
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
    final marketData = ref.watch(marketOverviewProvider(_selectedType));
    final trendingData = ref.watch(trendingInstrumentsProvider);
    final liveData = ref.watch(livePricesProvider);
    
    // Use market data based on tab selection
    final instrumentsAsync = marketData;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
          
          final double horizontalPadding = isDesktop 
              ? (constraints.maxWidth - 1000) / 2 
              : (isTablet ? 40 : AppTheme.paddingM + 4);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? horizontalPadding : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
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
                      _buildTabs(context, constraints.maxWidth),
                      const SizedBox(height: 20),
                      instrumentsAsync.when(
                        data: (instruments) {
                          return _buildInstrumentList(context, ref, instruments, constraints.maxWidth);
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
            onPressed: () => ref.refresh(trendingInstrumentsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String userName = 'User';
        String avatarUrl = 'https://i.pravatar.cc/150?u=green_rabbit';
        
        if (state is ProfileLoaded && state.user.fullName.isNotEmpty) {
          userName = state.user.fullName.split(' ').first;
          avatarUrl = state.user.avatarUrl ?? avatarUrl;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          userName,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                    },
                    child: _headerIcon(icon: Icons.search),
                  ),
                  const SizedBox(width: 8),
                  _headerIcon(icon: Icons.menu),
                ],
              ),
            );
      },
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
                color: Theme.of(context).iconTheme.color,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon ?? Icons.error,
                  color: Theme.of(context).iconTheme.color,
                  size: 22,
                ),
              )
            : Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
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

  Widget _buildTabs(BuildContext context, double width) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: width > 600 ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          _tabItem('Stocks', type: 'stocks'),
          const SizedBox(width: 12),
          _tabItem('Crypto', type: 'crypto'),
          const SizedBox(width: 12),
          _tabItem('Forex', type: 'forex'),
        ],
      ),
    );
  }

  Widget _tabItem(String label, {required String type}) {
    final bool isActive = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
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
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primary) 
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInstrumentList(BuildContext context, WidgetRef ref, List<MarketInstrument> instruments, double width) {
    if (width > 600) {
      // Grid for Tablet/Desktop
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width > 900 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width > 900 ? 2.5 : 2.2,
        ),
        itemCount: instruments.length,
        itemBuilder: (context, index) {
          final instrument = instruments[index];
          return _instrumentCard(
            context: context,
            ref: ref,
            instrument: instrument,
            isGrid: true,
          );
        },
      );
    }

    // List for Mobile
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
          isGrid: false,
        );
      },
    );
  }

  Widget _instrumentCard({
    required BuildContext context,
    required WidgetRef ref,
    required MarketInstrument instrument,
    required bool isGrid,
  }) {
    final isUp = (instrument.change ?? 0) >= 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isGrid ? 12 : 14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstrumentDetailPage(instrumentId: instrument.id),
          ),
        );
      },
      child: isGrid 
        ? Column( // Vertical layout for grid items
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131722) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: instrument.logoUrl != null 
                      ? Image.network(
                          instrument.logoUrl!,
                          errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 18),
                        )
                      : Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 18),
                  ),
                  _buildPriceColumn(context, instrument, isUp),
                ],
              ),
              const Spacer(),
              Text(
                instrument.name,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      instrument.symbol,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (instrument.sparkline7d != null && instrument.sparkline7d!.isNotEmpty)
                    SizedBox(
                      width: 40,
                      height: 18,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          instrument.sparkline7d!,
                          isUp ? AppColors.success : AppColors.error,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
        : Row( // Horizontal layout for list items
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
                      errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5)),
                    )
                  : Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5)),
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
                        color: theme.textTheme.bodyLarge?.color,
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
                        Icon(Icons.access_time, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${instrument.symbol} | ${instrument.exchange ?? 'Global'}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Sparkline Section
              if (instrument.sparkline7d != null && instrument.sparkline7d!.isNotEmpty)
                SizedBox(
                  width: 80,
                  height: 40,
                  child: CustomPaint(
                    painter: SparklinePainter(
                      instrument.sparkline7d!,
                      isUp ? AppColors.success : AppColors.error,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              _buildPriceColumn(context, instrument, isUp),
            ],
          ),
    );
  }

  Widget _buildPriceColumn(BuildContext context, MarketInstrument instrument, bool isUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          instrument.price?.toStringAsFixed(2) ?? '--',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${isUp ? '+' : ''}${instrument.change?.toStringAsFixed(2) ?? '--'} (${instrument.changePercent?.toStringAsFixed(2) ?? '--'}%)',
            style: TextStyle(
              color: isUp ? AppColors.success : AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardHeight = constraints.maxWidth > 600 ? 180 : 160;
        final double iconSize = constraints.maxWidth > 600 ? 90 : 72;
        
        return Stack(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
                          width: iconSize,
                          height: iconSize,
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
                                style: TextStyle(color: Colors.white, fontSize: constraints.maxWidth > 600 ? 22 : 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['desc'],
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: constraints.maxWidth > 600 ? 15 : 13, height: 1.4),
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
      },
    );
  }
}
