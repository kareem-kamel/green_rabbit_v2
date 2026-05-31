import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import 'news_detail_screen.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';
import '../../../alerts/presentation/widgets/create_alert_sheet.dart';
import '../../../../core/widgets/ask_ai_badge.dart';
import '../../../../core/widgets/ai_service_carousel.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_state.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

import 'package:shimmer/shimmer.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String selectedCategory = "Featured";
  bool _isExpanded = false;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerLoadMore(BuildContext context) {
    String? categoryParam;
    if (selectedCategory == "Stocks") {
      categoryParam = "stocks";
    } else if (selectedCategory == "Cryptocurrency") {
      categoryParam = "crypto";
    } else if (selectedCategory == "Forex") {
      categoryParam = "forex";
    } else if (selectedCategory == "Popular") {
      categoryParam = "most_popular";
    }
    
    context.read<NewsCubit>().loadMoreNews(
      limit: 10,
      category: categoryParam,
    );
  }

  // --- OPEN THE ALERT MENU ---
  void _openAlertMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAlertSheet(
        assetName: "Silver", 
        lastPrice: 113.225,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsCubit>().fetchNewsFeed(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Search news...",
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.8)),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                "News",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
        actions: [
          _buildAppBarIcon(
            icon: _isSearching ? Icons.close : Icons.search,
            onTap: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = "";
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 12),
          _buildAppBarIcon(
            icon: Icons.menu,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildSkeletonLoading();
          } else if (state is NewsError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          } else if (state is NewsLoaded) {
            final articles = state.articles;
            final hasMore = state.hasMore;
            final isLoadingMore = state.isLoadingMore;
            
            if (_isSearching) {
              final filteredArticles = _searchQuery.isEmpty 
                  ? articles 
                  : articles.where((a) => 
                      a.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                      a.snippet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (a.relatedSymbols.isNotEmpty && a.relatedSymbols.first.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
                    ).toList();
                    
              if (filteredArticles.isEmpty) {
                return Center(
                  child: Text("No results found for '$_searchQuery'", style: const TextStyle(color: AppColors.textGrey)),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredArticles.length,
                itemBuilder: (context, index) {
                  return _buildSmallArticle(context, filteredArticles[index]);
                },
              );
            }

            final featuredArticle = articles.isNotEmpty ? articles.first : null;
            final otherArticles = articles.length > 1 ? articles.sublist(1) : <NewsArticle>[];
            
            // Limit display to 5 articles total if not expanded
            final displayedArticles = _isExpanded ? otherArticles : otherArticles.take(4).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  AIServiceCarousel(
                    onItemTap: (index) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatBotScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),

                  // Category chips
                  _buildCategoryRow(),
                  const SizedBox(height: 24),

                  // Section header
                  _buildSectionHeader(
                    selectedCategory == "Favorites" ? "Favorite Articles" : "Latest News", 
                    hasFilter: selectedCategory != "Favorites",
                    hasViewAll: false,
                  ),
                  const SizedBox(height: 12),

                  if (selectedCategory == "Favorites") ...[
                    if (articles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            "No favorite articles yet.",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...articles.map((article) => _buildSmallArticle(context, article)),
                  ] else ...[
                    // Featured article (only the first one)
                    if (featuredArticle != null)
                      _buildFeaturedArticle(featuredArticle),

                    const SizedBox(height: 16),
                    _buildSeparator(),
                    const SizedBox(height: 16),

                    // List of small articles (either 4 or all depending on expansion)
                    ...displayedArticles.map((article) => _buildSmallArticle(context, article)),

                    // Unified Controls: View More / View Less / Load More
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          if (!_isExpanded && (otherArticles.length > 4 || hasMore))
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() => _isExpanded = true);
                                  // If we only have the initial batch, fetch more immediately to populate the list
                                  if (otherArticles.length <= 4 && hasMore) {
                                    _triggerLoadMore(context);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  backgroundColor: AppColors.secondaryBlue.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text("View More", style: TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          
                          if (_isExpanded) ...[
                            if (isLoadingMore)
                              const Center(child: CircularProgressIndicator(color: AppColors.secondaryBlue))
                            else if (hasMore)
                              Center(
                                child: TextButton(
                                  onPressed: () => _triggerLoadMore(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    backgroundColor: AppColors.secondaryBlue.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: const Text("Load More News", style: TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => setState(() => _isExpanded = false),
                                child: const Text("View Less", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),

                  // Ad banner at the end
                  _buildAdBanner(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────

  Widget _buildAppBarIcon({String? assetPath, IconData? icon, Color? iconColor, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                width: 22,
                height: 22,
                color: iconColor ?? (isDark ? Colors.white : Colors.black87),
              )
            : Icon(
                icon,
                size: 22,
                color: iconColor ?? (isDark ? Colors.white : Colors.black87),
              ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = ["Featured", "Popular", "Stocks", "Cryptocurrency", "Forex", "Favorites"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) => _buildCategoryChip(cat)).toList(),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/id/237/600/200'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "NEW SPRING\nCOLLECTION",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black),
              child: const Text("SHOP NOW",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label) {
      case 'Featured':
        return Icons.star_rounded;
      case 'Popular':
        return Icons.local_fire_department_rounded;
      case 'Stocks':
        return Icons.show_chart_rounded;
      case 'Cryptocurrency':
        return Icons.currency_bitcoin_rounded;
      case 'Forex':
        return Icons.swap_horiz_rounded;
      case 'Favorites':
        return Icons.bookmark_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Widget _buildCategoryChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isActive = selectedCategory == label;
    final icon = _getCategoryIcon(label);

    return GestureDetector(
      onTap: () {
        if (selectedCategory == label) return;
        setState(() {
          selectedCategory = label;
          _isExpanded = false; // Reset expansion on category change
        });
        if (label == "Favorites") {
          context.read<NewsCubit>().fetchFavoriteNews(limit: 20);
        } else {
          // Map UI labels to backend 'category' parameters
          String? categoryParam;
          if (label == "Stocks") {
            categoryParam = "stocks";
          } else if (label == "Cryptocurrency") {
            categoryParam = "crypto";
          } else if (label == "Forex") {
            categoryParam = "forex";
          } else if (label == "Popular") {
            categoryParam = "most_popular";
          }
          
          context.read<NewsCubit>().fetchNewsFeed(limit: 5, category: categoryParam);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : (isDark ? AppColors.cardBg.withOpacity(0.5) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.unlockBlue : (isDark ? Colors.white10 : Colors.black12),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? (isDark ? Colors.white : AppColors.primary) : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? (isDark ? Colors.white : AppColors.primary) : AppColors.textGrey,
                fontSize: 14,
                fontFamily: 'Urbanist',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool hasFilter = false, bool hasViewAll = false, VoidCallback? onViewAll}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                  color: isDark ? Colors.white : Colors.black)),
        ),
        if (hasFilter) ...[
          const SizedBox(width: 8),
          Image.asset(
            'assets/icons/filter.png',
            width: 24,
            height: 24,
            color: isDark ? null : Colors.black87,
          ),
        ],
        if (hasViewAll) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewAll,
            child: const Text("View all",
                style: TextStyle(
                    color: AppColors.secondaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Urbanist')),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturedArticle(NewsArticle article) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(article: article),
          ),
        );
        if (context.mounted) {
          if (selectedCategory == "Favorites") {
            context.read<NewsCubit>().fetchFavoriteNews();
          } else {
            context.read<NewsCubit>().fetchNewsFeed();
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: article.largeImage.isNotEmpty
                    ? Image.network(
                        ImageUtils.getSafeImageUrl(article.largeImage),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220,
                          color: isDark ? AppColors.cardBg : Colors.grey[300],
                          child: Icon(Icons.image_not_supported, color: isDark ? Colors.white : Colors.black54),
                        ),
                      )
                    : Container(height: 220, color: isDark ? AppColors.cardBg : Colors.grey[300]),
              ),
              _buildAskAIBadge(context, 12, 12, article),
              Positioned(
                top: 12,
                right: 12,
                child: StatefulBuilder(
                  builder: (context, setStateLocal) {
                    bool isFavorited = article.isBookmarked;
                    return Row(
                      children: [
                        _buildCircleIcon(
                          'assets/icons/star.png',
                          color: isFavorited ? AppColors.primaryPurple : Colors.black.withOpacity(0.3),
                          onTap: () async {
                            final success = await di.sl<NewsRepository>().toggleFavorite(
                              article,
                              !isFavorited,
                            );
                            if (success) {
                              final added = !isFavorited;
                              context.read<NewsCubit>().toggleFavoriteLocally(
                                article.id,
                                added,
                                isFavoritesTab: selectedCategory == "Favorites",
                              );
                              if (added && selectedCategory == "Favorites") {
                                context.read<NewsCubit>().fetchFavoriteNews(limit: 20);
                              }
                              setStateLocal(() {
                                isFavorited = added;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(added ? 'Added to favorites' : 'Removed from favorites'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCircleIcon(
                          'assets/icons/share.png',
                          onTap: () {
                            final String deepLink = "https://greenrabbit.com/article?id=${article.id}";
                            final String shareText = article.url.isNotEmpty 
                                ? "${article.title}\n\nRead more: ${article.url}\n\nOpen in Green Rabbit App: $deepLink" 
                                : "${article.title}\n\nOpen in Green Rabbit App: $deepLink";
                            Share.share(shareText);
                          },
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            article.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text("${article.sourceName} • ${article.timeAgo}",
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAskAIBadge(BuildContext context, double top, double left, NewsArticle article) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatBotScreen(
                summaryId: article.id,
                summaryType: 'news_article',
                summaryUrl: article.url,
              ),
            ),
          );
        },
        child: const AskAIBadge(),
      ),
    );
  }

  Widget _buildCircleIcon(String assetPath, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color ?? Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          assetPath,
          width: 20,
          height: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: 1,
      width: double.infinity,
      color: AppColors.borderGrey.withOpacity(0.08),
    );
  }

  Widget _buildSmallArticle(BuildContext context, NewsArticle article) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String tickerText = article.tickers.isNotEmpty 
        ? article.tickers.first 
        : (article.relatedSymbols.isNotEmpty ? article.relatedSymbols.first.symbol : "N/A");

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(article: article),
          ),
        );
        if (context.mounted) {
          if (selectedCategory == "Favorites") {
            context.read<NewsCubit>().fetchFavoriteNews();
          } else {
            context.read<NewsCubit>().fetchNewsFeed();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBg : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: article.smallImage.isNotEmpty
                      ? Image.network(
                          ImageUtils.getSafeImageUrl(article.smallImage),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 90,
                            height: 90,
                            color: isDark ? AppColors.scaffoldBg : Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: isDark ? Colors.white : Colors.black54, size: 20),
                          ),
                        )
                      : Container(width: 90, height: 90, color: isDark ? AppColors.scaffoldBg : Colors.grey[200]),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatBotScreen(
                            summaryId: article.id,
                            summaryType: 'news_article',
                            summaryUrl: article.url,
                          ),
                        ),
                      );
                    },
                    child: const AskAIBadge(
                      label: "Ask AI",
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tickerText != "N/A")
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(tickerText,
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text("${article.sourceName} • ${article.timeAgo}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 150, height: 16, color: Colors.white),
                        const SizedBox(height: 16),
                        Container(width: 100, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}