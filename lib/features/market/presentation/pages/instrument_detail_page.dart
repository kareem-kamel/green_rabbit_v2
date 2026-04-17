import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
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

class InstrumentDetailPage extends ConsumerStatefulWidget {
  final String instrumentId;
  const InstrumentDetailPage({super.key, required this.instrumentId});

  @override
  ConsumerState<InstrumentDetailPage> createState() => _InstrumentDetailPageState();
}

class _InstrumentDetailPageState extends ConsumerState<InstrumentDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _showMovingAverages = false;
  final bool _isAreaChart = true; // Still used for portrait if needed, but the main state is _chartMode
  ProChartMode _chartMode = ProChartMode.area;
  String _selectedTimeframe = '15';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(instrumentDetailsProvider(widget.instrumentId));

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
            error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black))),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final detailAsync = ref.watch(instrumentDetailsProvider(widget.instrumentId));
    final isFavorite = ref.watch(isInstrumentInWatchlistProvider(widget.instrumentId));

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _buildAppBarIcon(Icons.search, onPressed: () {}),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/notification_icon.png',
                width: 20,
                height: 20,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.notifications_none_outlined,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        _buildAppBarIcon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87),
          onPressed: () {
            detailAsync.whenData((detail) {
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
              
              ref.read(watchlistProvider.notifier).toggleInstrument(instrument);
              
              if (!isFavorite) {
                _showSuccessSnackBar(context, instrument);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${instrument.symbol} removed from watchlist')),
                );
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
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
        ),
      ),
    );
  }

  Widget _buildContent(MarketInstrumentDetail detail) {
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
                children: [
                  Expanded(
                    child: Text(
                      '${detail.name} (${detail.symbol})',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            Text(
                              detail.price.current?.toStringAsFixed(2) ?? '--',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.displayMedium?.color, 
                                fontSize: isSmall ? 28 : 36, 
                                fontWeight: FontWeight.bold,
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
                        const Text('13 : 01 : 32', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
          Container(
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
                const Text('Analyze AI', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
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
    final newsAsync = ref.watch(instrumentNewsProvider(widget.instrumentId));
    return newsAsync.when(
      data: (articles) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildNewsItem(article, index);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
    );
  }

  Widget _buildAnalysisTab(MarketInstrumentDetail detail) {
    final newsAsync = ref.watch(instrumentNewsProvider(widget.instrumentId));
    return newsAsync.when(
      data: (articles) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildAnalysisItem(article, index);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.textPrimary))),
    );
  }

  Widget _buildAnalysisItem(Map<String, dynamic> article, int index) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).cardColor,
      onTap: () async {
        final url = article['url'];
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
            backgroundImage: NetworkImage(article['imageUrl'] ?? ''),
            child: article['imageUrl'] == null 
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
                  article['title'] ?? '',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.normal, height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${article['source']['name']} . 3 hours ago',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> article, int index) {
    final sentiment = article['sentiment']?.toString().toLowerCase() ?? 'neutral';
    final isBullish = sentiment == 'bullish';
    final isBearish = sentiment == 'bearish';
    final sentimentColor = isBullish ? AppColors.success : (isBearish ? AppColors.error : AppColors.textSecondary);
    
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.cardBackground,
      onTap: () async {
        final url = article['url'];
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
              image: article['imageUrl'] != null 
                ? DecorationImage(image: NetworkImage(article['imageUrl']), fit: BoxFit.cover)
                : null,
              color: AppColors.surface,
            ),
            child: article['imageUrl'] == null ? const Icon(Icons.newspaper, color: AppColors.textMuted) : null,
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
                      article['source']?.toString().toUpperCase() ?? 'NEWS',
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
                  article['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  article['publishedAt']?.toString() ?? 'Today',
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Date Range Selector
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
                        ? 'Daily 12/30/2026 - 01/29/2026' 
                        : 'Daily ${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.end)}', 
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _selectedDateRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: AppColors.cardBackground,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                        }
                      },
                      child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                    ),
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
        
        // Summary Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHistorySummaryItem('open', '76.065'),
            _buildHistorySummaryItem('Highest', '120.065'),
            _buildHistorySummaryItem('lowest', '69.065'),
            _buildHistorySummaryItem('Chg. %', '51.51%', valueColor: AppColors.success),
          ],
        ),
        const SizedBox(height: 24),
        
        // Data Table
        SingleChildScrollView(
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
                    Expanded(flex: 2, child: Text('Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Open', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('High', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Low', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Vol.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  ],
                ),
              ),
              ... (() {
                // Generate mock records for the last 30 days
                final allRecords = List.generate(30, (index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  return {
                    'date': date,
                    'price': 120.0 + (index % 5),
                    'open': 119.5 + (index % 4),
                    'high': 121.2 + (index % 3),
                    'low': 118.8 - (index % 2),
                    'vol': '${(0.59 + index * 0.05).toStringAsFixed(2)}K',
                    'isUp': index % 2 == 0,
                  };
                });

                // Filter by _selectedDateRange if it exists
                final filteredRecords = _selectedDateRange == null 
                  ? allRecords 
                  : allRecords.where((record) {
                      final date = record['date'] as DateTime;
                      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) && 
                             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }).toList();

                if (filteredRecords.isEmpty) {
                  return [
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text('No data found for the selected range', style: TextStyle(color: AppColors.textMuted))),
                    )
                  ];
                }

                return filteredRecords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final date = record['date'] as DateTime;
                  final isHighlighted = index % 2 == 1;
                  
                  return Container(
                    width: 600,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isHighlighted ? Theme.of(context).cardColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(DateFormat('MM/dd/yy').format(date), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                        Expanded(flex: 2, child: Text((record['price'] as double).toStringAsFixed(3), style: TextStyle(color: (record['isUp'] as bool) ? AppColors.success : AppColors.error, fontSize: 14))),
                        Expanded(flex: 2, child: Text((record['open'] as double).toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                        Expanded(flex: 2, child: Text((record['high'] as double).toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                        Expanded(flex: 2, child: Text((record['low'] as double).toStringAsFixed(3), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                        Expanded(flex: 2, child: Text(record['vol'] as String, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14))),
                      ],
                    ),
                  );
                }).toList();
              })(),
            ],
          ),
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
        _buildCommentsSection(detail),
      ],
    );
  }

  Widget _buildStatsTab(MarketInstrumentDetail detail) {
    final statsAsync = ref.watch(instrumentStatsProvider(widget.instrumentId));
    
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
    final chartAsync = ref.watch(instrumentChartProvider(widget.instrumentId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: chartAsync.when(
              data: (chartData) {
                final List<dynamic> candlesJson = chartData['candles'] ?? [];
                // Use backend fields: t (time), o (open), h (high), l (low), c (close), v (volume)
                final sparkData = candlesJson.map((e) => ((e['c'] ?? e['close'] ?? 0.0) as num).toDouble()).toList();
                final currentPrice = detail.price.current ?? 0.0;
                
                if (sparkData.isEmpty) {
                  return _buildChartError('Insufficient data', onRetry: () => ref.refresh(instrumentChartProvider(widget.instrumentId)));
                }

                // Generate simple labels based on data range
                final min = sparkData.reduce((a, b) => a < b ? a : b);
                final max = sparkData.reduce((a, b) => a > b ? a : b);
                final step = (max - min) / 4;
                final yLabels = List.generate(5, (i) => (min + i * step).toStringAsFixed(2));

                return SparklineChart(
                  data: sparkData,
                  currentPrice: currentPrice,
                  labelsY: yLabels,
                  labelsX: const ['10:30', '06:00', '01:15', '20:00', '15:30'],
                  color: (detail.price.change ?? 0) >= 0 ? AppColors.success : AppColors.error,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildChartError('Chart data unavailable: $err'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...['1D', '1W', '1Y', '5Y', 'Max'].map((t) => Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Text(t, style: TextStyle(color: t == '1D' ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14, fontWeight: t == '1D' ? FontWeight.bold : FontWeight.normal)),
              )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(
                  'assets/chart_group.png', 
                  width: 24, 
                  height: 24, 
                  errorBuilder: (_, __, ___) => const Icon(Icons.candlestick_chart, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatsSection(MarketInstrumentDetail detail, {bool isWide = false}) {
    final stats = [
      {'label': 'Previous Close', 'value': detail.price.previousClose?.toString() ?? '-'},
      {'label': 'Open', 'value': detail.price.open?.toString() ?? '-'},
      {'label': 'Day Range', 'value': '${detail.price.dayLow ?? '-'}-${detail.price.dayHigh ?? '-'}'},
      {'label': '52wk Range', 'value': '${detail.price.week52Low ?? '-'}-${detail.price.week52High ?? '-'}'},
      {'label': 'Market Cap', 'value': detail.fundamentals?.marketCap?.toString() ?? '-'},
      {'label': 'P/E Ratio', 'value': detail.fundamentals?.peRatio?.toString() ?? '-'},
      {'label': 'Div. Yield', 'value': '${detail.fundamentals?.dividendYield?.toString() ?? '-'}%'},
    ];

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Technical Analysis', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _tabController.animateTo(1),
                child: Text('More Details', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTechnicalBadge(TechnicalIndicator tech) {
    final isLocked = tech.isLocked;
    final color = tech.color == 'green' ? AppColors.success : (tech.color == 'red' ? AppColors.error : AppColors.textSecondary);
    
    // Background color based on signal strength/type
    Color bgColor = AppColors.tabUnselected; // Neutral background
    if (tech.signal.contains('Bullish')) {
      bgColor = AppColors.technicalBullishRoot;
    } else if (tech.signal.contains('Bearish')) {
      bgColor = AppColors.technicalBearishRoot;
    }

    return Column(
      children: [
        Text(tech.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.normal)),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isLocked ? AppColors.surface : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isLocked 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: AppColors.unlockBlue, size: 20),
                        const SizedBox(width: 4),
                        const Text('Unlock', style: TextStyle(color: AppColors.unlockBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              tech.signal.replaceAll(' ', '\n'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
                            ),
                          ),
                          Icon(
                            tech.color == 'green' ? Icons.trending_up : (tech.color == 'red' ? Icons.trending_down : Icons.trending_flat),
                            color: color,
                            size: 16,
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
    final newsAsync = ref.watch(instrumentNewsProvider(widget.instrumentId));
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
            final displayArticles = articles.length > 3 ? articles.sublist(0, 3) : articles;
            return Column(
              children: displayArticles.asMap().entries.map((entry) {
                return _buildNewsItem(entry.value, entry.key);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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
                    Expanded(flex: 2, child: Text('Hight', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
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

  Widget _buildCommentsSection(MarketInstrumentDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comments', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _tabController.animateTo(6), // Comments tab (index 6)
                child: Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(AppTheme.paddingM, 0, AppTheme.paddingM, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=me'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.3)),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text('Write a comment here...!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ... (detail.comments ?? []).map((comment) => Container(
          margin: const EdgeInsets.fromLTRB(AppTheme.paddingM, 0, AppTheme.paddingM, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 20, backgroundImage: NetworkImage(comment.avatar ?? '')),
                  const SizedBox(width: 12),
                  Text(comment.user, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(comment.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment.text,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.mode_comment_outlined, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text('Replies (2)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.thumb_up_alt_outlined, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 20),
                  const Icon(Icons.thumb_down_alt_outlined, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRelatedSection(MarketInstrumentDetail detail) {
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
            itemCount: 6,
            itemBuilder: (context, index) {
              final symbols = ['LCD', 'SBUX', 'ULTA', 'CIEN', 'USD/JPY', 'DX'];
              final changes = [-0.39, -0.39, -0.39, -0.39, -0.39, -0.39];
              final symbol = symbols[index % symbols.length];
              final change = changes[index % changes.length];
              final isUp = change >= 0;
              final isFavorite = index % 3 == 1;

              return Container(
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
                    Text(symbol, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? const Color(0xFFFBBF24) : AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalTab(MarketInstrumentDetail detail) {
    final statsAsync = ref.watch(instrumentStatsProvider(widget.instrumentId));

    return statsAsync.when(
      data: (stats) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Timeframes (Placeholder for now as individual stats come per interval)
          _buildTimeframeSection(stats),
          const SizedBox(height: 24),
          
          // Market Bias Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Text('Market Bias', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.normal)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (stats.technicals.overallSignal?.contains('Bullish') ?? false) 
                            ? AppColors.success.withOpacity(0.1) 
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(stats.technicals.overallSignal ?? 'Neutral', style: TextStyle(
                            color: (stats.technicals.overallSignal?.contains('Bullish') ?? false) ? AppColors.success : AppColors.error, 
                            fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Icon(
                            (stats.technicals.overallSignal?.contains('Bullish') ?? false) ? Icons.trending_up : Icons.trending_down, 
                            color: (stats.technicals.overallSignal?.contains('Bullish') ?? false) ? AppColors.success : AppColors.error, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildBiasRow('Moving averages', stats.technicals.overallSignal ?? '-', 'Overall Signal', ''),
              ],
            ),
          ),
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
      error: (err, _) => Center(child: Text('Error loading stats: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildTimeframeSection(MarketInstrumentStats stats) {
    // Current API provides one interval at a time, so we show the current one clearly
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTimeframeItem('Current', signal: stats.technicals.overallSignal ?? 'Neutral', 
            color: (stats.technicals.overallSignal?.contains('Bullish') ?? false) ? AppColors.success : AppColors.error),
          _buildTimeframeItem('1h', isLocked: true),
          _buildTimeframeItem('1d', isLocked: true),
          _buildTimeframeItem('1w', isLocked: true),
        ],
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

  Widget _buildTimeframeItem(String label, {bool isLocked = false, String? signal, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 85,
                height: 44,
                decoration: BoxDecoration(
                  color: signal != null ? color?.withOpacity(0.1) : const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(8),
                  border: signal != null ? Border.all(color: color?.withOpacity(0.2) ?? Colors.transparent) : null,
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
                            Text(
                              signal.split(' ').join('\n'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              signal.contains('Bullish') ? Icons.trending_up : (signal.contains('Bearish') ? Icons.trending_down : Icons.trending_flat),
                              color: color,
                              size: 14,
                            ),
                          ],
                        )
                      : const SizedBox()),
              ),
              if (isLocked)
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
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

  Widget _buildLandscapeChart(MarketInstrumentDetail detail) {
    final chartAsync = ref.watch(instrumentChartProvider(widget.instrumentId));

    return chartAsync.when(
      data: (chartData) {
        final List<dynamic> candlesJson = chartData['candles'] ?? [];
        final realCandles = candlesJson.map((json) {
          // Use backend fields: t (time), o (open), h (high), l (low), c (close), v (volume)
          final ts = json['t'] ?? json['timestamp'];
          final timestamp = ts is int ? ts * 1000 : (DateTime.tryParse(ts?.toString() ?? '')?.millisecondsSinceEpoch ?? 0);
          
          return CandleData(
            timestamp: timestamp,
            open: ((json['o'] ?? json['open'] ?? 0.0) as num).toDouble(),
            close: ((json['c'] ?? json['close'] ?? 0.0) as num).toDouble(),
            high: ((json['h'] ?? json['high'] ?? 0.0) as num).toDouble(),
            low: ((json['l'] ?? json['low'] ?? 0.0) as num).toDouble(),
            volume: ((json['v'] ?? json['volume'] ?? 0.0) as num).toDouble(),
          );
        }).toList();

        return Column(
          children: [
            _buildLandscapeHeader(detail),
            Expanded(
              child: ProTradingChart(
                candles: realCandles,
                showMovingAverages: _showMovingAverages,
                mode: _chartMode,
                timeframe: _selectedTimeframe,
              ),
            ),
          ],
        );
      },
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              const Text('Live Chart Unavailable', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text(err.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(instrumentChartProvider(widget.instrumentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildLandscapeHeader(MarketInstrumentDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundSubtle,
      child: Row(
        children: [
          // Timeframes
          _landscapeButton('5', isActive: _selectedTimeframe == '5', onTap: () => setState(() => _selectedTimeframe = '5')),
          _landscapeButton('30', isActive: _selectedTimeframe == '30', onTap: () => setState(() => _selectedTimeframe = '30')),
          _landscapeButton('1h', isActive: _selectedTimeframe == '1h', onTap: () => setState(() => _selectedTimeframe = '1h')),
          _landscapeButton('1D', isActive: _selectedTimeframe == '1D', onTap: () => setState(() => _selectedTimeframe = '1D')),
          _landscapeButton('1M', isActive: _selectedTimeframe == '1M', onTap: () => setState(() => _selectedTimeframe = '1M')),
          _landscapeButton('15', isActive: _selectedTimeframe == '15', hasDropdown: true, onTap: () => setState(() => _selectedTimeframe = '15')),
          const SizedBox(width: 12),
          // Chart Tools
          _landscapeButton('candles', isIcon: true, icon: Icons.candlestick_chart_outlined, isActive: _chartMode == ProChartMode.candle, onTap: () => setState(() => _chartMode = ProChartMode.candle)),
          _landscapeButton('area', isIcon: true, icon: Icons.show_chart, isActive: _chartMode == ProChartMode.area, hasDropdown: true, onTap: () => setState(() => _chartMode = ProChartMode.area)),
          const SizedBox(width: 12),
          _landscapeButton('indicators', isIcon: true, icon: Icons.bar_chart, isActive: _chartMode == ProChartMode.indicators, onTap: () => setState(() => _chartMode = ProChartMode.indicators)),
          const SizedBox(width: 12),
          // History
          _landscapeButton('undo', isIcon: true, icon: Icons.undo),
          _landscapeButton('redo', isIcon: true, icon: Icons.redo),
          const Spacer(),
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

  Widget _landscapeButton(String label, {bool isActive = false, bool hasDropdown = false, bool isIcon = false, IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E222D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: AppColors.unlockBlue, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isIcon) 
              Icon(icon, color: isActive ? AppColors.unlockBlue : AppColors.textSecondary, size: 20)
            else
              Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: isActive ? AppColors.unlockBlue : AppColors.textSecondary, size: 16),
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
}
