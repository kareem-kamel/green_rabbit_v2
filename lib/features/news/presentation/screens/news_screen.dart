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

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String selectedCategory = "Featured";

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
      context.read<NewsCubit>().fetchNewsFeed();
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
        title: Text(
          "News",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          _buildAppBarIcon(
            icon: Icons.search,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildAppBarIcon(
            icon: Icons.add_alert_rounded,
            iconColor: AppColors.primaryPurple,
            onTap: () => _openAlertMenu(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NewsError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          } else if (state is NewsLoaded) {
            final articles = state.articles;
            final featuredArticle = articles.isNotEmpty ? articles.first : null;
            final otherArticles = articles.length > 1 ? articles.sublist(1) : <NewsArticle>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // AI Service Carousel (matches Market page)
                  AIServiceCarousel(
                    onItemTap: (index) {
                      if (index == 0) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBotScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),

                  // Category chips
                  _buildCategoryRow(),
                  const SizedBox(height: 24),

                  // Section header
                  _buildSectionHeader("Latest News", hasFilter: true),
                  const SizedBox(height: 12),

                  // Featured article
                  if (featuredArticle != null)
                    _buildFeaturedArticle(featuredArticle),

                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),

                  // Analysis & Opinions header
                  _buildSectionHeader("Analysis & Opinions", hasViewAll: true),
                  const SizedBox(height: 12),

                  // Small articles
                  ...otherArticles.map((article) => _buildSmallArticle(context, article)).toList(),

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
    final categories = ["Featured"];
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

  Widget _buildCategoryChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isActive = selectedCategory == label;

    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : (isDark ? AppColors.cardBg.withOpacity(0.5) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.unlockBlue : (isDark ? Colors.white10 : Colors.black12),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? (isDark ? Colors.white : AppColors.primary) : AppColors.textGrey,
            fontSize: 16,
            fontFamily: 'Urbanist',
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool hasFilter = false, bool hasViewAll = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        if (hasFilter)
          Image.asset(
            'assets/icons/filter.png',
            width: 24,
            height: 24,
            color: isDark ? null : Colors.black87,
          ),
        if (hasViewAll)
          GestureDetector(
            onTap: () {},
            child: const Text("View all",
                style: TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildFeaturedArticle(NewsArticle article) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(article: article),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: article.largeImage.isNotEmpty
                    ? Image.network(
                        article.largeImage,
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
                child: Row(
                  children: [
                    _buildCircleIcon('assets/icons/star.png'),
                    const SizedBox(width: 8),
                    _buildCircleIcon('assets/icons/share.png'),
                  ],
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
                initialPrompt: "Tell me more about this news: ${article.title}",
              ),
            ),
          );
        },
        child: const AskAIBadge(),
      ),
    );
  }

  Widget _buildCircleIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        assetPath,
        width: 20,
        height: 20,
        color: Colors.white,
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
    bool isBullish = article.relatedSymbols.isNotEmpty && article.relatedSymbols.first.changePercent >= 0;
    String tickerText = article.relatedSymbols.isNotEmpty 
        ? article.relatedSymbols.first.symbol 
        : "N/A";
    String changeText = article.relatedSymbols.isNotEmpty 
        ? "${article.relatedSymbols.first.changePercent >= 0 ? '+' : ''}${article.relatedSymbols.first.changePercent}%" 
        : "";

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(article: article),
        ),
      ),
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
                          article.smallImage,
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
                            initialPrompt: "Tell me more about this news: ${article.title}",
                          ),
                        ),
                      );
                    },
                    child: const AskAIBadge(
                      iconSize: 12,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text("$tickerText ",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 11)),
                      ),
                      if (changeText.isNotEmpty)
                        Text(changeText,
                            style: TextStyle(
                                color: isBullish
                                    ? AppColors.profitGreen
                                    : AppColors.lossRed,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                      const SizedBox(width: 8),
                      const Icon(Icons.mode_comment_outlined,
                          color: AppColors.textGrey, size: 14),
                      const SizedBox(width: 4),
                      Text("${article.commentCount}",
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 11)),
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
}