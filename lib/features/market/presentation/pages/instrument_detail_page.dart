
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/price_flash_widget.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../providers/market_providers.dart';
import '../../data/models/market_instrument.dart';
import '../../data/models/market_instrument_detail.dart';
import '../widgets/pro_trading_chart.dart';
import '../widgets/sparkline_chart.dart';
import 'package:intl/intl.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:green_rabbit/features/alerts/presentation/widgets/create_alert_sheet.dart';
import 'package:green_rabbit/features/market/presentation/pages/search_page.dart';
import 'package:green_rabbit/core/utils/image_utils.dart';
import 'package:green_rabbit/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:green_rabbit/features/profile/presentation/screens/subscription_screen.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:green_rabbit/features/profile/presentation/cubit/profile_state.dart';
import 'package:green_rabbit/features/news/data/models/news_model.dart';
import 'package:shimmer/shimmer.dart';

class InstrumentDetailPage extends ConsumerStatefulWidget {
  final String instrumentId;
  const InstrumentDetailPage({super.key, required this.instrumentId});

  @override
  ConsumerState<InstrumentDetailPage> createState() => _InstrumentDetailPageState();
}

class _InstrumentDetailPageState extends ConsumerState<InstrumentDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  /// Active period for the chart (matches API `period` param).
  /// Defaults to '1M' which is the confirmed-working tier for free/classic accounts.
  String _selectedPeriod = '1M';
  final bool _showMovingAverages = false;
  ProChartMode _chartMode = ProChartMode.area;
  String _selectedTechnicalInterval = '15m';
  DateTimeRange? _selectedDateRange;
  final Set<String> _activeIndicators = {};

  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;
  bool _showAllComments = false;

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final comments = await ref.read(marketRepositoryProvider).fetchComments(
        widget.instrumentId,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      String userName = "You";
      String? userAvatar;

      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        userName = profileState.user.fullName;
        userAvatar = profileState.user.avatarUrl;
      }

      _commentController.clear();
      FocusScope.of(context).unfocus();
      
      // Optimistic UI update
      setState(() {
        _comments.insert(
          0,
          CommentModel(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            name: userName,
            avatarUrl: userAvatar,
            text: text,
            time: "Just now",
            likesCount: 0,
            isLiked: false,
          ),
        );
      });

      final success = await ref.read(marketRepositoryProvider).postComment(
        widget.instrumentId,
        text,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to post comment. Please try again.")),
          );
          _loadComments();
        }
      } else {
        _loadComments();
        if (context.mounted) {
          context.read<ProfileCubit>().getProfile();
        }
      }
    }
  }

  void _toggleLikeComment(CommentModel comment) async {
    final index = _comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    final isLiked = comment.isLiked;
    final newLikesCount = isLiked ? comment.likesCount - 1 : comment.likesCount + 1;

    setState(() {
      _comments[index] = comment.copyWith(
        isLiked: !isLiked,
        likesCount: newLikesCount < 0 ? 0 : newLikesCount,
      );
    });

    final success = isLiked
        ? await ref.read(marketRepositoryProvider).unlikeComment(comment.id)
        : await ref.read(marketRepositoryProvider).likeComment(comment.id);

    if (!success) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _comments[index] = comment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update like. Please try again.")),
        );
      }
    }
  }

  late StateController<bool> _detailsPageActiveController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _detailsPageActiveController = ref.read(isDetailsPageActiveProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detailsPageActiveController.state = true;
      _loadComments();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      _detailsPageActiveController.state = false;
    });
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the live price provider alive by watching it in the UI
    final livePriceStream = ref.watch(instrumentLivePriceProvider(widget.instrumentId));
    if (livePriceStream is AsyncError) {
      debugPrint('❌ [InstrumentDetailPage] livePriceStream Error: ${livePriceStream.error}');
    }

    final detailAsync = ref.watch(liveInstrumentDetailProvider(widget.instrumentId));

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return _buildLandscapeUI(detailAsync);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(),
          body: detailAsync.when(
            data: (detail) => _buildContent(detail),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildErrorState(err),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final detailAsync = ref.watch(liveInstrumentDetailProvider(widget.instrumentId));
    final isFavorite = ref.watch(isInstrumentInWatchlistProvider(widget.instrumentId));

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _buildAppBarIcon(
          Icons.search,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          },
        ),
        _buildAppBarIcon(
          Icons.notifications_none_outlined,
          onPressed: () {
            final detail = detailAsync.valueOrNull;
            if (detail == null) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateAlertSheet(
                assetName: detail.symbol,
                instrumentId: detail.id,
                lastPrice: detail.price.current ?? 0.0,
              ),
            );
          },
        ),
        _buildAppBarIcon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87),
          onPressed: () async {
            detailAsync.whenData((detail) async {
              final instrument = MarketInstrument(
                id: detail.id,
                symbol: detail.symbol,
                name: detail.name,
                type: detail.type,
                price: detail.price.current,
                change: detail.price.change,
                changePercent: detail.price.changePercent,
                logoUrl: detail.logoUrl,
                sparkline7d: [], 
              );
              
              final result = await ref.read(watchlistProvider.notifier).toggleInstrument(instrument);
              
              if (result) {
                if (mounted) _showSuccessSnackBar(context, instrument);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${instrument.symbol} removed from watchlist'),
                      backgroundColor: AppColors.error.withOpacity(0.8),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarIcon(IconData icon, {Color? color, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87), size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildLandscapeUI(AsyncValue<MarketInstrumentDetail> detailAsync) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) => _buildLandscapeChart(detail),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildErrorState(err),
        ),
      ),
    );
  }

  String _getNewsProviderKey(MarketInstrumentDetail detail) {
    final String type;
    final cleanType = detail.type.toLowerCase();
    if (cleanType == 'stock' || cleanType == 'stocks') {
      type = 'stocks';
    } else if (cleanType == 'crypto') {
      type = 'crypto';
    } else if (cleanType == 'forex') {
      type = 'forex';
    } else {
      type = 'stocks';
    }
    return '${widget.instrumentId}|$type';
  }

  Widget _buildContent(MarketInstrumentDetail detail) {
    // Preload news provider immediately to ensure the request starts right away
    ref.watch(instrumentNewsProvider(_getNewsProviderKey(detail)));
    return Column(
      children: [
        _buildHeader(detail),
        const SizedBox(height: 20),
        _buildTabBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return TabBarView(
                controller: _tabController,
                children: [
                   _buildOverviewTab(detail, isWide: isWide),
                  _buildTechnicalTab(detail),
                  _buildNewsTab(detail),
                  _buildAnalysisTab(detail),
                  _buildHistoryDataTab(detail),
                  _buildContractsTab(detail),
                  _buildCommentsTab(detail),
                  _buildChartTab(detail),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  String _getExchangeAndSectorText(MarketInstrumentDetail detail) {
    final List<String> details = [];
    if (detail.sector != null && detail.sector!.isNotEmpty) {
      details.add(detail.sector!);
    }
    if (detail.industry != null && detail.industry!.isNotEmpty) {
      details.add(detail.industry!);
    }
    
    final exchange = detail.exchange ?? '';
    if (details.isEmpty) {
      return exchange;
    }
    
    if (exchange.isEmpty) {
      return '(${details.join(" • ")})';
    }
    
    return '$exchange (${details.join(" • ")})';
  }

  Widget _buildHeader(MarketInstrumentDetail detail) {
    final isUp = (detail.price.change ?? 0) >= 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${detail.name} (${detail.symbol})',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getExchangeAndSectorText(detail),
                          style: const TextStyle(
                            color: AppColors.textSecondary, 
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showSharePopup(context, 'https://greenrabbit.app/${detail.symbol}'),
                    child: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isUp ? AppColors.success : AppColors.error, size: 32),
                            const SizedBox(width: 4),
                            PriceFlashWidget(
                              price: detail.price.current,
                              child: Text(
                                detail.price.current?.toStringAsFixed(2) ?? '--',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.displayMedium?.color, 
                                  fontSize: isSmall ? 28 : 36, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${isUp ? '+' : ''}${detail.price.change?.toStringAsFixed(2) ?? '--'} (${detail.price.changePercent?.toStringAsFixed(2) ?? '--'}%)',
                          style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF34D399), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          detail.price.lastUpdatedAt != null 
                            ? DateFormat('HH : mm : ss').format(DateTime.parse(detail.price.lastUpdatedAt!))
                            : DateFormat('HH : mm : ss').format(DateTime.now()), 
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        const Text('.', style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Real time derived Currency in USD', 
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 48,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.tabIndicatorBorder, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primaryPurple,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        tabs: [
          _buildTabItem('Overview'),
          _buildTabItem('Technical'),
          _buildTabItem('News'),
          _buildTabItem('Analysis'),
          _buildTabItem('History Data'),
          _buildTabItem('Contract'),
          _buildTabItem('Comments'),
          _buildTabItem('Chart'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildOverviewTab(MarketInstrumentDetail detail, {bool isWide = false}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _buildToolbar(detail),
        _buildSparklineSection(detail),
        _buildKeyStatsSection(detail, isWide: isWide),
        _buildTechnicalSection(detail),
        _buildNewsDashboardTab(detail),
        _buildContractsSection(detail),
        _buildCommentsSection(detail),
        _buildRelatedSection(detail),
      ],
    );
  }

  Widget _buildToolbar(MarketInstrumentDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            ),
            child: InkWell(
              onTap: () => _tabController.animateTo(7), // Chart tab (index 7)
              child: Icon(Icons.fullscreen, color: Theme.of(context).iconTheme.color, size: 24),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatBotScreen(
                    summaryId: detail.id,
                    summaryType: 'instrument',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5AE0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset('assets/trade_logo.png', width: 16, height: 16, errorBuilder: (_, __, ___) => const Icon(Icons.psychology, color: Colors.purple, size: 16)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Financial Advisor Analysis', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartTypeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showSaveChartPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: AppCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: AppColors.searchBarBackground,
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  ),
                ),
                Text(
                  'Save your Chart',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _saveActionIcon(Icons.file_download_outlined),
                    const SizedBox(width: 24),
                    _saveActionIcon(Icons.file_upload_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Save or Load your chart layout',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('GOT IT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 24),
    );
  }



  Widget _buildNewsTab(MarketInstrumentDetail detail) {
    final newsAsync = ref.watch(instrumentNewsProvider(_getNewsProviderKey(detail)));
    debugPrint('📰 [DEBUG] _buildNewsTab building, state: $newsAsync');
    return newsAsync.when(
      data: (articles) {
        if (articles.isEmpty) {
          return const Center(
            child: Text(
              'No recent news available.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return _buildNewsItem(article, index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
    );
  }

  Widget _buildAnalysisTab(MarketInstrumentDetail detail) {
    final newsAsync = ref.watch(instrumentNewsProvider(_getNewsProviderKey(detail)));
    return newsAsync.when(
      data: (articles) {
        if (articles.isEmpty) {
          return const Center(
            child: Text(
              'No analysis available.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return _buildAnalysisItem(article, index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
    );
  }

  Widget _buildAnalysisItem(MarketNewsArticle article, int index) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).cardColor,
      onTap: () async {
        final url = article.url;
        if (url != null && await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.surface,
            backgroundImage: article.imageUrl != null ? NetworkImage(ImageUtils.getSafeImageUrl(article.imageUrl!)) : null,
            child: article.imageUrl == null 
                ? const Icon(Icons.person, color: AppColors.textMuted, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  article.title,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.normal, height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${article.source ?? "News"} . ${article.publishedAt ?? "Today"}',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(MarketNewsArticle article, int index) {
    final sentiment = article.sentiment?.toLowerCase() ?? 'neutral';
    final isBullish = sentiment == 'bullish';
    final isBearish = sentiment == 'bearish';
    final sentimentColor = isBullish ? AppColors.success : (isBearish ? AppColors.error : AppColors.textSecondary);
    
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.cardBackground,
      onTap: () async {
        final url = article.url;
        if (url != null && await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: article.imageUrl != null 
                ? DecorationImage(image: NetworkImage(ImageUtils.getSafeImageUrl(article.imageUrl!)), fit: BoxFit.cover)
                : null,
              color: AppColors.surface,
            ),
            child: article.imageUrl == null ? const Icon(Icons.newspaper, color: AppColors.textMuted) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article.source?.toUpperCase() ?? 'NEWS',
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sentimentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sentiment.toUpperCase(),
                        style: TextStyle(color: sentimentColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  article.publishedAt ?? 'Today',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDataTab(MarketInstrumentDetail detail) {
    final interval = _getIntervalForPeriod(_selectedPeriod);
    final chartAsync = ref.watch(instrumentChartProvider('${widget.instrumentId}|$_selectedPeriod|$interval'));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Date Range Selector (UI only for now)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _selectedDateRange == null 
                        ? 'Market History (Daily)' 
                        : 'History ${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.end)}', 
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _showSharePopup(context, 'https://greenrabbit.app/${detail.symbol}'),
                child: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Summary Row - uses detail stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHistorySummaryItem('Open', detail.price.open?.toStringAsFixed(3) ?? '-'),
            _buildHistorySummaryItem('High', detail.price.dayHigh?.toStringAsFixed(3) ?? '-'),
            _buildHistorySummaryItem('Low', detail.price.dayLow?.toStringAsFixed(3) ?? '-'),
            _buildHistorySummaryItem('Chg. %', '${detail.price.changePercent?.toStringAsFixed(2) ?? '-'}%', 
              valueColor: (detail.price.change ?? 0) >= 0 ? AppColors.success : AppColors.error),
          ],
        ),
        const SizedBox(height: 24),
        
        // Data Table populated from chartAsync
        chartAsync.when(
          data: (chartData) {
            final List<dynamic> candlesJson = chartData['candles'] ?? [];
            if (candlesJson.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No historical data found', style: TextStyle(color: AppColors.textMuted)),
              ));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 600,
                    padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Close', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Open', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text('High', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Low', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text('Vol.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                      ],
                    ),
                  ),
                  ... candlesJson.asMap().entries.map((entry) {
                    final index = entry.key;
                    final candle = entry.value;
                    final isHighlighted = index % 2 == 1;
                    
                    final ts = candle['t'] ?? candle['timestamp'];
                    final dateStr = ts is String ? ts.split(' ').first : DateFormat('MM/dd/yy').format(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
                    
                    final open = ((candle['o'] ?? candle['open'] ?? 0.0) as num).toDouble();
                    final close = ((candle['c'] ?? candle['close'] ?? 0.0) as num).toDouble();
                    final high = ((candle['h'] ?? candle['high'] ?? 0.0) as num).toDouble();
                    final low = ((candle['l'] ?? candle['low'] ?? 0.0) as num).toDouble();
                    final vol = candle['v'] ?? candle['volume'] ?? 0;
                    
                    return Container(
                      width: 600,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isHighlighted ? Theme.of(context).cardColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(dateStr, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                          Expanded(flex: 2, child: Text(close.toStringAsFixed(3), style: TextStyle(color: close >= open ? AppColors.success : AppColors.error, fontSize: 14))),
                          Expanded(flex: 2, child: Text(open.toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                          Expanded(flex: 2, child: Text(high.toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                          Expanded(flex: 2, child: Text(low.toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                          Expanded(flex: 2, child: Text(vol.toString(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, _) => Center(child: Text('Error loading history: $err', style: const TextStyle(color: AppColors.textMuted))),
        ),
      ],
    );
  }

  Widget _buildHistorySummaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildContractsTab(MarketInstrumentDetail detail) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _buildContractsSection(detail),
      ],
    );
  }

  Widget _buildCommentsTab(MarketInstrumentDetail detail) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _buildCommentsSection(detail, isTab: true),
      ],
    );
  }

  Widget _buildStatsTab(MarketInstrumentDetail detail) {
    final statsAsync = ref.watch(instrumentStatsProvider('${widget.instrumentId}|15m'));
    
    return statsAsync.when(
      data: (stats) {
        final perf = stats.performance;
        final vol = stats.volatility;
        final div = stats.dividends;
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Performance', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('1D Return', '${perf.return1d?.toStringAsFixed(2) ?? '-'}%'),
            _buildStatRow('1W Return', '${perf.return1w?.toStringAsFixed(2) ?? '-'}%'),
            _buildStatRow('1M Return', '${perf.return1m?.toStringAsFixed(2) ?? '-'}%'),
            _buildStatRow('1Y Return', '${perf.return1y?.toStringAsFixed(2) ?? '-'}%'),
            const SizedBox(height: 24),
            Text('Volatility', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Beta', vol.beta?.toStringAsFixed(2) ?? '-'),
            _buildStatRow('Std Dev (30d)', vol.standardDeviation30d?.toStringAsFixed(4) ?? '-'),
            _buildStatRow('ATR (14d)', vol.averageTrueRange14d?.toStringAsFixed(4) ?? '-'),
            if (div != null) ...[
              const SizedBox(height: 24),
              Text('Dividends', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildStatRow('Yield', '${div.yield?.toStringAsFixed(2) ?? '-'}%'),
              _buildStatRow('Annual Div.', div.annualDividend?.toStringAsFixed(2) ?? '-'),
              _buildStatRow('Ex-Date', div.exDividendDate ?? '-'),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
    );
  }

  Widget _buildRelatedTab(MarketInstrumentDetail detail) {
    final related = detail.relatedInstruments ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: related.length,
      itemBuilder: (context, index) {
        final item = related[index];
        final isUp = item.changePercent! >= 0;
        return AppCard(
          padding: const EdgeInsets.all(12),
          backgroundColor: AppColors.searchBarBackground,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => InstrumentDetailPage(instrumentId: item.id)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.diamond_outlined, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.symbol, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Text(item.name, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                '${isUp ? '+' : ''}${item.changePercent?.toStringAsFixed(2)}%',
                style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSparklineSection(MarketInstrumentDetail detail) {
    final interval = _getIntervalForPeriod(_selectedPeriod);
    final providerKey = '${widget.instrumentId}|$_selectedPeriod|$interval';
    debugPrint('📊 [DEBUG] Portrait Chart Request: $providerKey');
    final chartAsync = ref.watch(instrumentChartProvider(providerKey));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: chartAsync.when(
              data: (chartData) {
                final List<dynamic> candlesJson = chartData['candles'] != null ? List.from(chartData['candles']) : [];
                
                final List<CandleData> realCandles = candlesJson.map((json) {
                  final ts = json['t'] ?? json['timestamp'];
                  final timestamp = ts is int
                      ? ts * 1000
                      : (DateTime.tryParse(ts?.toString() ?? '')?.millisecondsSinceEpoch ?? 0);
                  return CandleData(
                    timestamp: timestamp,
                    open: ((json['o'] ?? json['open'] ?? 0.0) as num).toDouble(),
                    close: ((json['c'] ?? json['close'] ?? 0.0) as num).toDouble(),
                    high: ((json['h'] ?? json['high'] ?? 0.0) as num).toDouble(),
                    low: ((json['l'] ?? json['low'] ?? 0.0) as num).toDouble(),
                    volume: ((json['v'] ?? json['volume'] ?? 0.0) as num).toDouble(),
                  );
                }).toList();

                if (_chartMode == ProChartMode.area) {
                  final sparkData = candlesJson.map((e) {
                    final val = e['c'] ?? e['close'] ?? e['price'] ?? 0.0;
                    return double.tryParse(val.toString()) ?? 0.0;
                  }).toList();

                  final currentPrice = detail.price.current ?? (sparkData.isNotEmpty ? sparkData.last : 0.0);
                  
                  if (sparkData.isEmpty) {
                    return _buildChartError('Insufficient candle data', onRetry: () => ref.refresh(instrumentChartProvider('${widget.instrumentId}|$_selectedPeriod|$interval')));
                  }

                  // Generate vertical labels based on price range
                  final min = sparkData.reduce((a, b) => a < b ? a : b);
                  final max = sparkData.reduce((a, b) => a > b ? a : b);
                  final range = max - min;
                  final yLabels = List.generate(5, (i) => (min + (i * range / 4)).toStringAsFixed(2));

                  // Generate horizontal labels from actual timestamps
                  final List<String> xLabels = [];
                  if (candlesJson.length >= 3) {
                    final first = candlesJson.first['timestamp']?.toString().split(' ').last ?? '';
                    final mid = candlesJson[candlesJson.length ~/ 2]['timestamp']?.toString().split(' ').last ?? '';
                    final last = candlesJson.last['timestamp']?.toString().split(' ').last ?? '';
                    xLabels.addAll([first, mid, last]);
                  } else {
                    xLabels.addAll(['Start', 'End']);
                  }

                  return SparklineChart(
                    data: sparkData,
                    currentPrice: currentPrice,
                    labelsY: yLabels,
                    labelsX: xLabels,
                    color: (detail.price.change ?? 0) >= 0 ? AppColors.success : AppColors.error,
                  );
                } else {
                  if (realCandles.isEmpty) {
                    return _buildChartError('Insufficient candle data', onRetry: () => ref.refresh(instrumentChartProvider('${widget.instrumentId}|$_selectedPeriod|$interval')));
                  }
                  return ProTradingChart(
                    candles: realCandles,
                    showMovingAverages: _showMovingAverages,
                    mode: _chartMode,
                    period: _selectedPeriod,
                    interval: interval,
                    symbolName: '${detail.name} (${detail.symbol})',
                    currency: detail.currency ?? 'USD',
                    isLoading: false,
                    onRetry: () => ref.refresh(instrumentChartProvider(providerKey)),
                    activeIndicators: _activeIndicators,
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildChartError('Chart data unavailable: $err'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...['1D', '1W', '1M', '3M', '1Y', '5Y', '10Y', '15Y'].map((t) {
                        const bool mightBeLocked = false;
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() { _selectedPeriod = t; });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  Text(
                                    t,
                                    style: TextStyle(
                                      color: t == _selectedPeriod ? AppColors.textPrimary : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: t == _selectedPeriod ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (mightBeLocked)
                                    const SizedBox(height: 2),
                                  if (mightBeLocked)
                                    Icon(
                                      Icons.lock_outline,
                                      size: 8,
                                      color: t == _selectedPeriod ? AppColors.premiumGold : AppColors.textMuted,
                                    ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTapDown: (details) {
                  final position = details.globalPosition;
                  showMenu<ProChartMode>(
                    context: context,
                    color: Theme.of(context).cardColor,
                    position: RelativeRect.fromLTRB(
                      position.dx - 100,
                      position.dy + 20,
                      position.dx,
                      position.dy,
                    ),
                    items: [
                      PopupMenuItem(
                        value: ProChartMode.area,
                        child: Row(
                          children: [
                            Icon(Icons.show_chart, color: _chartMode == ProChartMode.area ? AppColors.primary : AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              'Area Chart',
                              style: TextStyle(
                                color: _chartMode == ProChartMode.area ? Colors.white : AppColors.textSecondary,
                                fontWeight: _chartMode == ProChartMode.area ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProChartMode.candle,
                        child: Row(
                          children: [
                            Icon(Icons.candlestick_chart, color: _chartMode == ProChartMode.candle ? AppColors.success : AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              'Candle Chart',
                              style: TextStyle(
                                color: _chartMode == ProChartMode.candle ? Colors.white : AppColors.textSecondary,
                                fontWeight: _chartMode == ProChartMode.candle ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).then((value) {
                    if (value != null) {
                      setState(() {
                        _chartMode = value;
                      });
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  child: Image.asset(
                    'assets/chart_group.png', 
                    width: 24, 
                    height: 24, 
                    errorBuilder: (_, __, ___) => Icon(
                      _chartMode == ProChartMode.candle 
                          ? Icons.candlestick_chart 
                          : Icons.show_chart, 
                      color: AppColors.primary, 
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the best confirmed-working interval for the given period.
  /// Based on API testing: only 1M→1h is confirmed for free/classic tier.
  /// Other combos return 503 on restricted accounts.
  String _getIntervalForPeriod(String period) {
    return getIntervalForPeriod(period);
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

  Widget _buildKeyStatsSection(MarketInstrumentDetail detail, {bool isWide = false}) {
    final type = detail.type.toLowerCase();
    final List<Map<String, String>> stats;

    final prevClose = detail.price.previousClose?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-';
    final openVal = detail.price.open?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-';
    final dayRange = '${detail.price.dayLow?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-'}-${detail.price.dayHigh?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-'}';
    final wkRange = '${detail.price.week52Low?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-'}-${detail.price.week52High?.toStringAsFixed(type == 'forex' ? 4 : 2) ?? '-'}';

    if (type == 'crypto') {
      stats = [
        {'label': 'Previous Close', 'value': prevClose},
        {'label': 'Open', 'value': openVal},
        {'label': 'Day Range', 'value': dayRange},
        {'label': '52wk Range', 'value': wkRange},
        {'label': 'Circulating Supply', 'value': _formatLargeNumber(detail.cryptoMetrics?.circulatingSupply)},
        {'label': 'Max Supply', 'value': _formatLargeNumber(detail.cryptoMetrics?.maxSupply)},
        {'label': 'Total Supply', 'value': _formatLargeNumber(detail.cryptoMetrics?.totalSupply)},
        {'label': 'Market Cap', 'value': _formatLargeNumber(detail.cryptoMetrics?.marketCap, isCurrency: true)},
        {'label': 'Market Dominance', 'value': detail.cryptoMetrics?.marketDominance != null ? '${detail.cryptoMetrics!.marketDominance!.toStringAsFixed(2)}%' : '-'},
        {'label': 'Fully Diluted Valuation', 'value': _formatLargeNumber(detail.cryptoMetrics?.fullyDilutedValuation, isCurrency: true)},
      ];
    } else if (type == 'forex') {
      stats = [
        {'label': 'Previous Close', 'value': prevClose},
        {'label': 'Open', 'value': openVal},
        {'label': 'Day Range', 'value': dayRange},
        {'label': '52wk Range', 'value': wkRange},
        {'label': 'Bid', 'value': detail.forexMetrics?.bid?.toStringAsFixed(4) ?? '-'},
        {'label': 'Ask', 'value': detail.forexMetrics?.ask?.toStringAsFixed(4) ?? '-'},
        {'label': 'Spread (pips)', 'value': detail.forexMetrics?.spreadPips?.toString() ?? '-'},
        {'label': 'Pip Value', 'value': detail.forexMetrics?.pipValue?.toString() ?? '-'},
      ];
    } else if (type == 'etf') {
      stats = [
        {'label': 'Previous Close', 'value': prevClose},
        {'label': 'Open', 'value': openVal},
        {'label': 'Day Range', 'value': dayRange},
        {'label': '52wk Range', 'value': wkRange},
        {'label': 'P/E Ratio', 'value': detail.fundamentals?.peRatio?.toString() ?? '-'},
        {'label': 'Div. Yield', 'value': detail.fundamentals?.dividendYield != null ? '${detail.fundamentals!.dividendYield!.toStringAsFixed(2)}%' : '-'},
      ];
    } else {
      stats = [
        {'label': 'Previous Close', 'value': prevClose},
        {'label': 'Open', 'value': openVal},
        {'label': 'Day Range', 'value': dayRange},
        {'label': '52wk Range', 'value': wkRange},
        {'label': 'Market Cap', 'value': _formatLargeNumber(detail.fundamentals?.marketCap, isCurrency: true)},
        {'label': 'P/E Ratio', 'value': detail.fundamentals?.peRatio?.toString() ?? '-'},
        {'label': 'Div. Yield', 'value': detail.fundamentals?.dividendYield != null ? '${detail.fundamentals!.dividendYield!.toStringAsFixed(2)}%' : '-'},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(AppTheme.paddingM),
          child: Text('Key Statistics', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (isWide)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4,
                mainAxisSpacing: 0,
                crossAxisSpacing: 24,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                return _buildStatRow(stats[index]['label']!, stats[index]['value']!, horizontalPadding: 0);
              },
            ),
          )
        else
          Column(
            children: stats.map<Widget>((s) => _buildStatRow(s['label']!, s['value']!)).toList(),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {double horizontalPadding = AppTheme.paddingM}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15))),
          Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTechnicalSection(MarketInstrumentDetail detail) {
    final statsAsync = ref.watch(instrumentStatsProvider('${widget.instrumentId}|15m'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Technical', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _tabController.animateTo(1),
                child: const Text('View More', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
        ),
        statsAsync.when(
          data: (stats) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
            child: _buildTimeframeGrid(stats),
          ),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (err, _) => const Center(child: Text('Technical data unavailable', style: TextStyle(color: AppColors.textMuted))),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTechnicalBadge(TechnicalIndicator tech) {
    final isLocked = false;
    final isBullish = tech.signal.contains('Bullish');
    final isBearish = tech.signal.contains('Bearish');
    final signalColor = isBullish ? AppColors.success : (isBearish ? AppColors.error : AppColors.textSecondary);
    
    Color bgColor = const Color(0xFF1E222D); // Base back color
    if (isBullish) {
      bgColor = AppColors.success.withOpacity(0.08);
    } else if (isBearish) {
      bgColor = AppColors.error.withOpacity(0.08);
    }

    return GestureDetector(
      onTap: isLocked
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            }
          : null,
      child: Column(
        children: [
          Text(tech.name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: isLocked 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                          SizedBox(width: 4),
                          Text('Unlock', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                tech.signal.replaceAll(' ', '\n'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: signalColor, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold, 
                                  height: 1.1
                                ),
                              ),
                            ),
                            if (isBullish || isBearish)
                              Transform.rotate(
                                angle: isBullish ? -0.5 : 0.5,
                                child: Icon(
                                  isBullish ? Icons.arrow_outward : Icons.south_east, 
                                  color: signalColor, 
                                  size: 14
                                ),
                              ),
                          ],
                        ),
                      ),
                ),
                if (isLocked)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.premiumGold,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalButton(String label, Color color, {bool isActive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: isActive ? color : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildNewsDashboardTab(MarketInstrumentDetail detail) {
    final newsAsync = ref.watch(instrumentNewsProvider(_getNewsProviderKey(detail)));
    debugPrint('📰 [DEBUG] _buildNewsDashboardTab building, state: $newsAsync');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('News & Analysis', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _tabController.animateTo(2), // Navigate to News tab
                child: Text('View More', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
        ),
        newsAsync.when(
          data: (articles) {
            if (articles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: AppTheme.paddingM),
                child: Center(
                  child: Text(
                    'No recent news available.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              );
            }
            final displayArticles = articles.length > 3 ? articles.sublist(0, 3) : articles;
            return Column(
              children: displayArticles.asMap().entries.map((entry) {
                return _buildNewsItem(entry.value, entry.key);
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildContractsSection(MarketInstrumentDetail detail) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contracts', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _tabController.animateTo(5), // Contracts tab (index 5)
                child: Text('View More', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 600, // Fixed width for horizontal scroll
                padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                child: Row(
                  children: const [
                    Expanded(flex: 2, child: Text('Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Last', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Change', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Vol.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Open', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('High', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  ],
                ),
              ),
              ... (detail.contracts ?? []).asMap().entries.map((entry) {
                final index = entry.key;
                final c = entry.value;
                final isHighlighted = index % 2 == 1; // Highlighted rows (e.g., Feb, then skip, then Feb)
                
                return Container(
                  width: 600,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Theme.of(context).cardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(c.month, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.normal))),
                      Expanded(flex: 2, child: Text(c.price!.toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                      Expanded(flex: 2, child: Text('${c.change! > 0 ? '+' : ''}${c.change?.toStringAsFixed(3)}', style: TextStyle(color: c.change! >= 0 ? AppColors.success : AppColors.error, fontSize: 14))),
                      Expanded(flex: 2, child: Text(c.volume.toString(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                      Expanded(flex: 2, child: Text(c.price!.toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))), // Mocking Open
                      Expanded(flex: 2, child: Text((c.price! * 1.01).toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))), // Mocking High
                    ],
                  ),
                );
              }).toList() ?? [],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(MarketInstrumentDetail detail, {bool isTab = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comments', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              if (!isTab)
                InkWell(
                  onTap: () => _tabController.animateTo(6), // Comments tab (index 6)
                  child: Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                ),
            ],
          ),
        ),
        _buildCommentInput(),
        const SizedBox(height: 8),
        if (_isLoadingComments && _comments.isEmpty)
          Column(
            children: List.generate(2, (index) => _buildSkeletonComment()),
          )
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No comments yet. Be the first to comment!",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey("comments_list_${isTab || _showAllComments}"),
              children: (isTab || _showAllComments ? _comments : _comments.take(3))
                  .map((c) => _buildCommentCard(c))
                  .toList(),
            ),
          ),
          if (!isTab && _comments.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAllComments = !_showAllComments),
                  child: Text(
                    _showAllComments ? "See less" : "See more",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCommentInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String? avatarUrl;
        if (state is ProfileLoaded) {
          avatarUrl = state.user.avatarUrl;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppColors.cardBg : Colors.grey[200],
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  onSubmitted: (_) => _postComment(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add a comment...",
                    hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 22),
                onPressed: _postComment,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? AppColors.cardBg : Colors.grey[200],
                backgroundImage: comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
                    ? NetworkImage(comment.avatarUrl!) as ImageProvider
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                child: null,
              ),
              const SizedBox(width: 10),
              Text(comment.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black)),
              const Spacer(),
              Text(comment.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment.text,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLikeComment(comment),
                child: Row(
                  children: [
                    Icon(
                      comment.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 16,
                      color: comment.isLiked ? Colors.blueAccent : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likesCount.toString(),
                      style: TextStyle(
                        color: comment.isLiked
                            ? Colors.blueAccent
                            : (isDark ? Colors.grey : Colors.grey[600]),
                        fontSize: 12,
                        fontWeight: comment.isLiked ? FontWeight.bold : FontWeight.normal,
                      ),
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

  Widget _buildSkeletonComment() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 150, height: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection(MarketInstrumentDetail detail) {
    final related = detail.relatedInstruments ?? [];
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 16),
          child: Text('People Also Watch', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
            itemCount: related.length,
            itemBuilder: (context, index) {
              final item = related[index];
              final change = item.changePercent ?? 0.0;
              final isUp = change >= 0;

              return InkWell(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => InstrumentDetailPage(instrumentId: item.id)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.symbol, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                        style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star_border, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalTab(MarketInstrumentDetail detail) {
    final statsAsync = ref.watch(instrumentStatsProvider('${widget.instrumentId}|$_selectedTechnicalInterval'));

    return statsAsync.when(
      data: (stats) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Timeframes Selector
          // Timeframes Selector (2-Row Grid)
          _buildTimeframeGrid(stats),
          const SizedBox(height: 32),
          
          // Pivot Point
          _buildTechnicalSectionHeader('Pivot Point'),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return _buildPivotPointsTable(stats.technicals.pivotPoints, isWide: isWide);
            }
          ),
          const SizedBox(height: 32),
          
          // Moving Averages
          _buildTechnicalSectionHeader('Moving Averages'),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return _buildMovingAveragesTable(stats.technicals.movingAverages, isWide: isWide);
            }
          ),
          const SizedBox(height: 32),
          
          // Technical Indicators
          _buildTechnicalSectionHeader('Technical Indicators'),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return _buildTechnicalIndicatorsTable(stats.technicals.indicators, isWide: isWide);
            }
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading technicals: $err', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(instrumentStatsProvider('${widget.instrumentId}|$_selectedTechnicalInterval')),
            child: const Text('Retry'),
          ),
        ],
      )),
    );
  }

  Widget _buildTimeframeGrid(MarketInstrumentStats stats) {
    return Column(
      children: [
        Row(
          children: [
            _buildTimeframeItem('15 Min.', interval: '15m', isPremium: false, stats: stats),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTimeframeItem('Hourly', interval: '1h', stats: stats),
            _buildTimeframeItem('Daily', interval: '1d', stats: stats),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeItem(String label, {required String interval, bool isPremium = false, required MarketInstrumentStats stats}) {
    final bool isSelected = _selectedTechnicalInterval == interval;
    
    // Fetch unique signal for this specific interval
    final specificStatsAsync = ref.watch(instrumentStatsProvider('${widget.instrumentId}|$interval'));
    final bool isLoading = specificStatsAsync.isLoading;
    final String? signal = isPremium 
        ? null 
        : (specificStatsAsync.valueOrNull?.technicals.overallSignal ?? (isSelected ? stats.technicals.overallSignal : null));
    
    // In a real app, isLocked would depend on user tier and backend status
    // For now, mirroring the reference image design
    final bool isLocked = false; 

    Color signalColor = Colors.white60;
    IconData? signalIcon;
    
    if (signal != null) {
      if (signal.contains('Bullish')) {
        signalColor = AppColors.success;
        signalIcon = Icons.trending_up;
      } else if (signal.contains('Bearish')) {
        signalColor = AppColors.error;
        signalIcon = Icons.trending_down;
      } else {
        signalColor = Colors.white70;
        signalIcon = Icons.trending_flat;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: isLocked 
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              }
            : () => setState(() => _selectedTechnicalInterval = interval),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400)),
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: signal != null 
                          ? signalColor.withOpacity(0.08) 
                          : const Color(0xFF161922),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : (signal != null ? Border.all(color: signalColor.withOpacity(0.15)) : null),
                    ),
                    alignment: Alignment.center,
                    child: isLocked 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock_outline, color: Color(0xFF2D5CFF), size: 18),
                            SizedBox(width: 4),
                            Text('Unlock', style: TextStyle(color: Color(0xFF2D5CFF), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        )
                      : (signal != null 
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    signal,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: signalColor, fontSize: 11, fontWeight: FontWeight.bold, height: 1.1),
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(signalIcon, color: signalColor, size: 16),
                              ],
                            )
                          : (isLoading 
                              ? const SizedBox(
                                  height: 12, 
                                  width: 12, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)
                                ) 
                              : const Text('Neutral', style: TextStyle(color: Colors.white24, fontSize: 11)))),
                  ),
                  if (isPremium)
                    Positioned(
                      top: -10,
                      left: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.workspace_premium, color: Color(0xFF2D5CFF), size: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPivotPointsTable(Map<String, dynamic>? pivotPoints, {bool isWide = false}) {
    if (pivotPoints == null || pivotPoints['classic'] == null) return const Center(child: Text('No pivot data', style: TextStyle(color: Colors.white54)));
    final classic = pivotPoints['classic'] as Map<String, dynamic>;
    
    final rows = [
      {'label': 'R3', 'value': classic['r3'].toString()},
      {'label': 'R2', 'value': classic['r2'].toString()},
      {'label': 'R1', 'value': classic['r1'].toString()},
      {'label': 'Pivot', 'value': classic['pivot'].toString(), 'isMain': true},
      {'label': 'S1', 'value': classic['s1'].toString()},
      {'label': 'S2', 'value': classic['s2'].toString()},
      {'label': 'S3', 'value': classic['s3'].toString()},
    ];

    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 5,
          crossAxisSpacing: 32,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) => _buildPivotRow(rows[index]['label'] as String, rows[index]['value'] as String, isMain: rows[index]['isMain'] == true),
      );
    }

    return Column(
      children: rows.map((r) => _buildPivotRow(r['label'] as String, r['value'] as String, isMain: r['isMain'] == true)).toList(),
    );
  }

  Widget _buildPivotRow(String label, String value, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isMain ? AppColors.primary : Colors.white70, fontWeight: isMain ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMovingAveragesTable(List<dynamic>? maData, {bool isWide = false}) {
    if (maData == null || maData.isEmpty) return const Center(child: Text('No MA data', style: TextStyle(color: Colors.white54)));
    
    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 6,
          crossAxisSpacing: 32,
        ),
        itemCount: maData.length,
        itemBuilder: (context, index) => _buildMARow(maData[index]),
      );
    }

    return Column(
      children: maData.map((ma) => _buildMARow(ma)).toList(),
    );
  }

  Widget _buildMARow(dynamic ma) {
    final period = ma['period']?.toString() ?? '-';
    final simple = ma['simple'] as Map<String, dynamic>?;
    final signal = simple?['signal']?.toString() ?? '-';
    final color = signal.contains('buy') ? AppColors.success : (signal.contains('sell') ? AppColors.error : Colors.white70);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(period, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 3, child: Text(simple?['value']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
          Expanded(flex: 2, child: Text(signal.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicatorsTable(List<dynamic>? indicators, {bool isWide = false}) {
    if (indicators == null || indicators.isEmpty) return const Center(child: Text('No indicators data', style: TextStyle(color: Colors.white54)));
    
    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 6,
          crossAxisSpacing: 32,
        ),
        itemCount: indicators.length,
        itemBuilder: (context, index) => _buildIndicatorRow(indicators[index]),
      );
    }

    return Column(
      children: indicators.map((ind) => _buildIndicatorRow(ind)).toList(),
    );
  }

  Widget _buildIndicatorRow(dynamic ind) {
    final name = ind['name']?.toString() ?? '-';
    final value = ind['value']?.toString() ?? '-';
    final signal = ind['signal']?.toString() ?? '-';
    final color = signal.contains('Bullish') || signal.contains('Buy') ? AppColors.success : (signal.contains('Bearish') || signal.contains('Sell') ? AppColors.error : Colors.white70);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 2, child: Text(value, style: const TextStyle(color: Colors.white))),
          Expanded(flex: 2, child: Text(signal, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildBiasRow(String label, String mainSignal, String sub1, String sub2) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Expanded(flex: 2, child: Text(mainSignal, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        Expanded(flex: 2, child: Text(sub1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        Expanded(flex: 2, child: Text(sub2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      ],
    );
  }

  Widget _buildTechnicalSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.normal)),
          const Text('Jan 29, 2026 ,12:32', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }


  void _showSharePopup(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.popupBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Share with your friends!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share this link via',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shareSocialIcon(Icons.facebook, () => _launchSocialShare('facebook', url)),
                _shareSocialIcon(Icons.close, () => _launchSocialShare('twitter', url)), // X icon mock
                _shareSocialIcon(Icons.send, () => _launchSocialShare('telegram', url)),
                _shareSocialIcon(Icons.reddit, () => _launchSocialShare('reddit', url)),
              ],
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'or copy link',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      url,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard!')),
                    );
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: AppColors.shareGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _launchSocialShare(String platform, String url) async {
    String shareUrl = '';
    switch (platform) {
      case 'facebook':
        shareUrl = 'https://www.facebook.com/sharer/sharer.php?u=$url';
        break;
      case 'twitter':
        shareUrl = 'https://twitter.com/intent/tweet?url=$url';
        break;
      case 'telegram':
        shareUrl = 'https://t.me/share/url?url=$url';
        break;
      case 'reddit':
        shareUrl = 'https://www.reddit.com/submit?url=$url';
        break;
    }
    
    final uri = Uri.parse(shareUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to native sharing if web link fails
      await Share.share('Check out this instrument on GreenRabbit: $url');
    }
  }

  Widget _buildChartTab(MarketInstrumentDetail detail) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.screen_rotation, size: 60, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rotate to View Full Chart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showIndicatorsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final indicatorsList = [
              {'id': 'SMA_Overlay', 'name': 'SMA (Overlay)', 'type': 'overlay'},
              {'id': 'SMA_Subchart', 'name': 'SMA (Sub-chart)', 'type': 'subchart'},
              {'id': 'EMA_Overlay', 'name': 'EMA (Overlay)', 'type': 'overlay'},
              {'id': 'EMA_Subchart', 'name': 'EMA (Sub-chart)', 'type': 'subchart'},
              {'id': 'BB_Overlay', 'name': 'Bollinger Bands (Overlay)', 'type': 'overlay'},
              {'id': 'BB_Subchart', 'name': 'Bollinger Bands (Sub-chart)', 'type': 'subchart'},
              {'id': 'Volume', 'name': 'Volume', 'type': 'subchart'},
              {'id': 'RSI', 'name': 'Relative Strength Index (RSI)', 'type': 'subchart'},
              {'id': 'MACD', 'name': 'MACD', 'type': 'subchart'},
              {'id': 'ATR', 'name': 'Average True Range (ATR)', 'type': 'subchart'},
              {'id': 'Stoch', 'name': 'Stochastic Oscillator', 'type': 'subchart'},
            ];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Technical Indicators', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: indicatorsList.length,
                      itemBuilder: (context, index) {
                        final ind = indicatorsList[index];
                        final id = ind['id']!;
                        final isSelected = _activeIndicators.contains(id);
                        return CheckboxListTile(
                          title: Text(ind['name']!, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(ind['type'] == 'overlay' ? 'Chart Overlay' : 'Sub-chart Pane', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          value: isSelected,
                          activeColor: AppColors.unlockBlue,
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setSheetState(() {
                              if (value == true) {
                                _activeIndicators.add(id);
                              } else {
                                _activeIndicators.remove(id);
                              }
                            });
                            setState(() {}); // Update the chart behind the sheet
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLandscapeChart(MarketInstrumentDetail detail) {
    final interval = _getIntervalForPeriod(_selectedPeriod);
    final providerKey = '${widget.instrumentId}|$_selectedPeriod|$interval';
    final chartAsync = ref.watch(instrumentChartProvider(providerKey));

    // Build candle list only when data is available
    List<CandleData> realCandles = [];
    String? errorMsg;
    bool isLoading = chartAsync.isLoading;

    chartAsync.when(
      data: (chartData) {
        final List<dynamic> candlesJson = chartData['candles'] ?? [];
        realCandles = candlesJson.map((json) {
          final ts = json['t'] ?? json['timestamp'];
          final timestamp = ts is int
              ? ts * 1000
              : (DateTime.tryParse(ts?.toString() ?? '')?.millisecondsSinceEpoch ?? 0);
          return CandleData(
            timestamp: timestamp,
            open: ((json['o'] ?? json['open'] ?? 0.0) as num).toDouble(),
            close: ((json['c'] ?? json['close'] ?? 0.0) as num).toDouble(),
            high: ((json['h'] ?? json['high'] ?? 0.0) as num).toDouble(),
            low: ((json['l'] ?? json['low'] ?? 0.0) as num).toDouble(),
            volume: ((json['v'] ?? json['volume'] ?? 0.0) as num).toDouble(),
          );
        }).toList();
      },
      loading: () {},
      error: (err, _) {
        errorMsg = err.toString();
      },
    );

    return Column(
      children: [
        _buildLandscapeHeader(detail, interval: interval),
        Expanded(
          child: ProTradingChart(
            candles: realCandles,
            showMovingAverages: _showMovingAverages,
            mode: _chartMode,
            period: _selectedPeriod,
            interval: interval,
            symbolName: '${detail.name} (${detail.symbol})',
            currency: detail.currency ?? 'USD',
            isLoading: isLoading,
            errorMessage: errorMsg,
            onRetry: () => ref.invalidate(instrumentChartProvider(providerKey)),
            activeIndicators: _activeIndicators,
          ),
        ),
      ],
    );
  }


  Widget _buildChartError(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildLandscapeHeader(MarketInstrumentDetail detail, {String interval = '1h'}) {
    // These are the API period values – buttons drive real data fetching.
    // Grayed-out ones may return 503 on free/classic tier but are still tappable.
    const List<Map<String, String>> periods = [
      {'label': '1D', 'period': '1D'},
      {'label': '1W', 'period': '1W'},
      {'label': '1M', 'period': '1M'},   // ✅ Confirmed working
      {'label': '3M', 'period': '3M'},
      {'label': '1Y', 'period': '1Y'},
      {'label': '5Y', 'period': '5Y'},
      {'label': '10Y', 'period': '10Y'},
      {'label': '15Y', 'period': '15Y'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundSubtle,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ── Period Buttons (drive API calls) ──────────────────────
                  ...periods.map((p) {
                    final isActive = _selectedPeriod == p['period'];
                    const bool mightBeLocked = false;
                    return _landscapeButton(
                      p['label']!,
                      isActive: isActive,
                      onTap: () => setState(() => _selectedPeriod = p['period']!),
                      trailingIcon: null,
                    );
                  }),
                  const SizedBox(width: 4),
                  // Interval badge (informational)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.unlockBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.unlockBlue.withOpacity(0.4)),
                    ),
                    child: Text(
                      interval,
                      style: const TextStyle(color: AppColors.unlockBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Chart Style Tools ─────────────────────────────────────
                  _landscapeButton('', isIcon: true, icon: Icons.candlestick_chart_outlined, isActive: _chartMode == ProChartMode.candle, onTap: () => setState(() => _chartMode = ProChartMode.candle)),
                  _landscapeButton('', isIcon: true, icon: Icons.show_chart, isActive: _chartMode == ProChartMode.area, onTap: () => setState(() => _chartMode = ProChartMode.area)),
                  _landscapeButton('', isIcon: true, icon: Icons.add_chart, isActive: _activeIndicators.isNotEmpty, onTap: () => _showIndicatorsBottomSheet(context)),
                  const SizedBox(width: 8),
                  _landscapeButton('', isIcon: true, icon: Icons.undo),
                  _landscapeButton('', isIcon: true, icon: Icons.redo),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Actions
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading Chart Snapshot...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.primary,
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chart saved to Gallery successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              });
            },
            child: const Icon(Icons.file_download_outlined, color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: () async {
              // Force portrait orientation and show feedback
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              
              // Give the system a moment to rotate, then re-enable all orientations 
              // so the user can rotate back if they want later
              Future.delayed(const Duration(seconds: 1), () {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Returning to Portrait Overview...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Icon(Icons.close, color: AppColors.textSecondary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _landscapeButton(
    String label, {
    bool isActive = false,
    bool hasDropdown = false,
    bool isIcon = false,
    IconData? icon,
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E222D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: AppColors.unlockBlue, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isIcon && icon != null)
              Icon(icon, color: isActive ? AppColors.unlockBlue : AppColors.textSecondary, size: 18)
            else
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon, color: AppColors.textMuted, size: 9),
            ],
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: isActive ? AppColors.unlockBlue : AppColors.textSecondary, size: 14),
            ],
          ],
        ),
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
                  '${instrument.name} ${instrument.symbol} successfully added to favorites',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
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

  Widget _buildErrorState(Object err) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Extract a user-friendly error message
    String title = 'Instrument Not Found';
    String message = 'We couldn\'t find details for "${widget.instrumentId}". Please verify the symbol or try again.';
    
    if (err is DioException) {
      final responseData = err.response?.data;
      if (responseData is Map) {
        final errorMap = responseData['error'];
        if (errorMap is Map && errorMap['message'] != null) {
          message = errorMap['message'].toString();
        }
      }
    } else {
      final errString = err.toString();
      if (errString.contains('INSTRUMENT_NOT_FOUND') || errString.contains('404')) {
        title = 'Instrument Not Found';
      } else {
        title = 'Load Failed';
        message = 'An unexpected error occurred while loading details. Please try again.';
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.invalidate(instrumentDetailsProvider(widget.instrumentId));
                ref.invalidate(liveInstrumentDetailProvider(widget.instrumentId));
              },
              child: const Text(
                'Retry Connection',
                style: TextStyle(
                  color: Color(0xFF6B5AE0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


