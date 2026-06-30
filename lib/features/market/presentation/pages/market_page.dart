import '../../../profile/presentation/screens/subscription_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_state.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/profile/presentation/screens/profile_screen.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/price_flash_widget.dart';
import '../../../../shared/widgets/app_section_header.dart';
import 'instrument_detail_page.dart';
import '../providers/market_providers.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../../data/models/market_instrument.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../notifications/presentation/cubit/notification_state.dart';
import 'package:green_rabbit/features/market/presentation/pages/search_page.dart';
import 'package:green_rabbit/features/chatbot/presentation/screens/chatbot_screen.dart';
import '../widgets/market_skeleton_loader.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  String _selectedType = 'popular';
  Timer? _visibilityDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _scrollController = ScrollController()..addListener(_onScroll);
    
    // Ensure profile data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().getProfile();
      context.read<NotificationCubit>().fetchUnreadCount();
    });
  }

  void _onSearchChanged() {
    ref.read(marketSearchQueryProvider.notifier).state = _searchController.text;
  }

  void _updateVisibleInstruments() {
    if (!mounted) return;
    
    final instrumentsAsync = _selectedType == 'popular'
        ? ref.read(trendingInstrumentsProvider(null))
        : (_selectedType == 'etf'
            ? ref.read(trendingInstrumentsProvider('etf'))
            : ref.read(marketOverviewProvider(_selectedType)));
            
    final instruments = instrumentsAsync.valueOrNull ?? [];
    if (instruments.isEmpty) return;

    _visibilityDebounceTimer?.cancel();
    _visibilityDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      final double viewportHeight = _scrollController.hasClients ? _scrollController.position.viewportDimension : 600.0;

      final bool isMobile = MediaQuery.of(context).size.width <= 600;
      final List<String> visibleIds = [];

      if (isMobile) {
        const double headerHeight = 350.0; 
        const double itemHeight = 74.0; 
        
        for (int i = 0; i < instruments.length; i++) {
          final double itemTop = headerHeight + (i * itemHeight);
          final double itemBottom = itemTop + itemHeight;
          
          if (itemBottom > scrollOffset && itemTop < scrollOffset + viewportHeight) {
            visibleIds.add(instruments[i].id);
          }
        }
      } else {
        final double width = MediaQuery.of(context).size.width;
        final int crossAxisCount = width > 900 ? 3 : 2;
        const double headerHeight = 300.0;
        final double colWidth = (width.clamp(0.0, 1000.0) - 40.0) / crossAxisCount;
        final double itemHeight = colWidth / (width > 900 ? 2.8 : 2.5) + 16.0; 
        
        for (int i = 0; i < instruments.length; i++) {
          final int rowIndex = i ~/ crossAxisCount;
          final double itemTop = headerHeight + (rowIndex * itemHeight);
          final double itemBottom = itemTop + itemHeight;
          
          if (itemBottom > scrollOffset && itemTop < scrollOffset + viewportHeight) {
            visibleIds.add(instruments[i].id);
          }
        }
      }

      if (visibleIds.isEmpty) {
        visibleIds.addAll(instruments.take(5).map((i) => i.id));
      }

      // Update provider
      final currentIds = ref.read(visibleInstrumentsProvider);
      bool isSame = currentIds.length == visibleIds.length;
      if (isSame) {
        for (int i = 0; i < currentIds.length; i++) {
          if (currentIds[i] != visibleIds[i]) {
            isSame = false;
            break;
          }
        }
      }
      
      if (!isSame) {
        ref.read(visibleInstrumentsProvider.notifier).state = visibleIds;
        debugPrint('[SSE] Calculated visible instruments: $visibleIds');
      }
    });
  }

  void _onScroll() {
    _updateVisibleInstruments();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_selectedType != 'popular' && _selectedType != 'etf') {
      ref.read(marketOverviewProvider(_selectedType).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _visibilityDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _selectedType == 'popular'
          ? trendingInstrumentsProvider(null)
          : (_selectedType == 'etf'
              ? trendingInstrumentsProvider('etf')
              : marketOverviewProvider(_selectedType)),
      (prev, next) {
        if (next is AsyncData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateVisibleInstruments();
          });
        }
      },
    );

    final visibleStream = ref.watch(visibleMarketLivePricesProvider);
    if (visibleStream is AsyncError) {
      debugPrint('❌ [MarketPage] visibleMarketLivePricesProvider Error: ${visibleStream.error}');
    }

    final instrumentsAsync = _selectedType == 'popular'
        ? ref.watch(trendingInstrumentsProvider(null))
        : (_selectedType == 'etf'
            ? ref.watch(trendingInstrumentsProvider('etf'))
            : ref.watch(marketOverviewProvider(_selectedType)));

    final isLoadingMore = (_selectedType != 'popular' && _selectedType != 'etf')
        ? ref.watch(marketOverviewLoadingMoreProvider(_selectedType))
        : false;

    final hasHitRateLimit = (_selectedType != 'popular' && _selectedType != 'etf')
        ? ref.watch(marketRateLimitHitProvider(_selectedType))
        : false;

    final watchlistState = ref.watch(watchlistProvider);
    final watchlistIds = watchlistState.selectedWatchlist?.instruments.map((i) => i.id).toSet() ?? <String>{};

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
          
          final double horizontalPadding = isDesktop 
              ? (constraints.maxWidth - 1000) / 2 
              : (isTablet ? 40 : AppTheme.paddingM + 4);

          return SingleChildScrollView(
            controller: _scrollController,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppSectionHeader(title: 'Market'),
                          Consumer(
                            builder: (context, ref, child) {
                              final status = ref.watch(marketOverviewStatusProvider(_selectedType));
                              final lastUpdated = ref.watch(marketOverviewLastUpdatedProvider(_selectedType));
                              
                              if (lastUpdated == null && status == null) return const SizedBox.shrink();
                              
                              String timeText = '';
                              if (lastUpdated != null) {
                                try {
                                  final dateTime = DateTime.parse(lastUpdated).toLocal();
                                  timeText = DateFormat('HH:mm:ss').format(dateTime);
                                } catch (_) {
                                  timeText = lastUpdated;
                                }
                              }
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (status.toLowerCase() == 'open' ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status.toLowerCase() == 'open' ? Colors.green : Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (timeText.isNotEmpty)
                                    Text(
                                      'Updated: $timeText',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTabs(context, constraints.maxWidth),
                      const SizedBox(height: 12),
                      if (hasHitRateLimit) _buildThrottledNotice(context),
                      const SizedBox(height: 8),
                      instrumentsAsync.when(
                        data: (instruments) {
                          final sortedInstruments = List<MarketInstrument>.from(instruments);
                          sortedInstruments.sort((a, b) {
                            final aInWatchlist = watchlistIds.contains(a.id);
                            final bInWatchlist = watchlistIds.contains(b.id);
                            if (aInWatchlist && !bInWatchlist) {
                              return -1;
                            } else if (!aInWatchlist && bInWatchlist) {
                              return 1;
                            } else {
                              return a.symbol.compareTo(b.symbol);
                            }
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInstrumentList(context, ref, sortedInstruments, constraints.maxWidth),
                              if (isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => MarketSkeletonLoader(width: constraints.maxWidth),
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
            onPressed: () {
              if (_selectedType == 'popular') {
                ref.refresh(trendingInstrumentsProvider(null));
              } else if (_selectedType == 'etf') {
                ref.refresh(trendingInstrumentsProvider('etf'));
              } else {
                ref.refresh(marketOverviewProvider(_selectedType));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildThrottledNotice(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.secondaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate Limit Reached',
                  style: TextStyle(
                    color: AppColors.secondaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have reached the free plan rate limit. Loading will resume shortly. Upgrade to Pro for unlimited instant data.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionScreen()),
              );
              if (context.mounted) {
                context.read<ProfileCubit>().getProfile();
              }
            },
            child: const Text(
              'UPGRADE',
              style: TextStyle(
                color: AppColors.secondaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String userName = 'User';
        String avatarUrl = 'assets/images/default_avatar.png';
        
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
                    backgroundImage: avatarUrl.startsWith('http')
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
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
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                          if (context.mounted) {
                            context.read<NotificationCubit>().fetchUnreadCount();
                          }
                        },
                        child: _headerIcon(
                          assetPath: 'assets/notification_icon.png',
                          hasBadge: state.unreadCount > 0,
                          fallbackIcon: Icons.notifications_none,
                        ),
                      );
                    },
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
          _tabItem('Popular', Icons.local_fire_department_rounded, type: 'popular'),
          const SizedBox(width: 12),
          _tabItem('Stocks', Icons.show_chart_rounded, type: 'stocks'),
          const SizedBox(width: 12),
          _tabItem('Cryptocurrency', Icons.currency_bitcoin_rounded, type: 'crypto'),
          const SizedBox(width: 12),
          _tabItem('Forex', Icons.swap_horiz_rounded, type: 'forex'),
          const SizedBox(width: 12),
          _tabItem('ETFs', Icons.layers_rounded, type: 'etf'),
          const SizedBox(width: 12),
          _tabItem('Commodities', Icons.oil_barrel_rounded, type: 'commodities'),
        ],
      ),
    );
  }

  Widget _tabItem(String label, IconData icon, {required String type}) {
    final bool isActive = _selectedType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color contentColor = isActive 
        ? (isDark ? Colors.white : AppColors.primary) 
        : theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        if (_selectedType == type) return;
        setState(() => _selectedType = type);
        // Reset rate limit notice when switching tabs
        ref.read(marketRateLimitHitProvider(_selectedType).notifier).state = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateVisibleInstruments();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : theme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: contentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: contentColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
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
          childAspectRatio: width > 900 ? 2.8 : 2.5,
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPriceColumn(context, instrument, isUp),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131722) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: instrument.logoUrl != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            instrument.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 12),
                          ),
                        )
                      : Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: (() {
                      final words = instrument.name.trim().split(RegExp(r'\s+'));
                      final style = TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      );
                      return words.length > 1
                          ? Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: words.map((word) => Text(
                                word,
                                style: style,
                                maxLines: 1,
                                softWrap: false,
                              )).toList(),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                instrument.name,
                                style: style,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            );
                    })(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${instrument.symbol}${instrument.lastUpdatedAt != null ? ' | ${(() {
                        try {
                          final dt = DateTime.parse(instrument.lastUpdatedAt!).toLocal();
                          return DateFormat('HH:mm').format(dt);
                        } catch (_) {
                          return instrument.lastUpdatedAt;
                        }
                      })()}' : ''}',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (instrument.type.toLowerCase() == 'crypto' && (instrument.cryptoMetrics?.marketCap != null || instrument.marketCap != null))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'MCap: ${_formatLargeNumber(instrument.cryptoMetrics?.marketCap ?? instrument.marketCap, isCurrency: true)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          )
        : Column( // Redesigned layout for list items
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Row with Logo
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131722) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: instrument.logoUrl != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            instrument.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 12),
                          ),
                        )
                      : Icon(Icons.diamond_outlined, color: theme.iconTheme.color?.withOpacity(0.5), size: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:Text(
                                '${instrument.symbol} | ${instrument.exchange ?? 'Global'}${instrument.lastUpdatedAt != null ? ' | ${(() {
                                  try {
                                    final dt = DateTime.parse(instrument.lastUpdatedAt!).toLocal();
                                    return DateFormat('HH:mm').format(dt);
                                  } catch (_) {
                                    return instrument.lastUpdatedAt;
                                  }
                                })()}' : ''}',
                                style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Other Components Row (without logo)
              Row(
                children: [
                  // Symbol and Exchange Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child:Text(
                      instrument.name,
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
                        if (instrument.type.toLowerCase() == 'crypto' && (instrument.cryptoMetrics?.marketCap != null || instrument.marketCap != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              'MCap: ${_formatLargeNumber(instrument.cryptoMetrics?.marketCap ?? instrument.marketCap, isCurrency: true)}',
                              style: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildPriceColumn(context, instrument, isUp),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildPriceColumn(BuildContext context, MarketInstrument instrument, bool isUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        PriceFlashWidget(
          price: instrument.price,
          child: Text(
            instrument.price?.toStringAsFixed(2) ?? '--',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
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

  String _formatLargeNumber(num? number, {bool isCurrency = false}) {
    if (number == null) return '-';
    final prefix = isCurrency ? '\$' : '';
    if (number >= 1e12) {
      return '$prefix${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '$prefix${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '$prefix${(number / 1e6).toStringAsFixed(2)}M';
    } else {
      return '$prefix${NumberFormat('#,##0', 'en_US').format(number)}';
    }
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
        final double cardHeight = constraints.maxWidth > 600 ? 115 : 100;
        final double iconSize = constraints.maxWidth > 600 ? 55 : 46;
        
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
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatBotScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: Theme.of(context).brightness == Brightness.dark 
                              ? [const Color(0xFF2E246A), const Color(0xFF1B1839)]
                              : [AppColors.primaryPurple, const Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              item['image'],
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: TextStyle(color: Colors.white, fontSize: constraints.maxWidth > 600 ? 16 : 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc'],
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: constraints.maxWidth > 600 ? 12 : 11, height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        Positioned(
          bottom: 6,
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
