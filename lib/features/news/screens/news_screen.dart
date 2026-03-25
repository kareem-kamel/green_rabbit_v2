import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'news_detail_screen.dart';
import '../../chatbot/chatbot_screen.dart';
import '../../alerts/create_alert_sheet.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "News",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.primaryPurple),
            onPressed: () => _openAlertMenu(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // AI Trading Assistant card
            _buildAICard(context),
            const SizedBox(height: 24),

            // Category chips
            _buildCategoryRow(),
            const SizedBox(height: 24),

            // Section header
            _buildSectionHeader("Top News", hasFilter: true),
            const SizedBox(height: 12),

            // Featured article
            _buildFeaturedArticle(),
            const SizedBox(height: 32),

            // Opinion cards
            _buildSectionHeader("Opinions", hasViewAll: true),
            const SizedBox(height: 12),
            _buildOpinionCard(context, 'https://i.pravatar.cc/150?u=op1', "Alex Rivera", "Why the Fed's next move matters for tech stocks."),
            _buildOpinionCard(context, 'https://i.pravatar.cc/150?u=op2', "Elena Belova", "Crypto regulation: The winter is finally thawing."),
            const SizedBox(height: 24),

            // Small articles
            _buildSectionHeader("More News", hasViewAll: true),
            const SizedBox(height: 12),
            _buildSmallArticle(context, isBullish: true),
            _buildSmallArticle(context, 
                isBullish: false,
                title: "Apple unveils new MacBook Pro with M4 chip architecture."),
            _buildSmallArticle(context, 
                isBullish: true,
                title: "Oil prices stabilize after OPEC+ unexpected meeting."),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────

  Widget _buildCategoryRow() {
    final categories = ["Featured", "Most Popular", "Cryptocurrency", "Forex", "Stocks"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) => _buildCategoryChip(cat)).toList(),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isActive = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPurple : AppColors.cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive ? AppColors.primaryPurple : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGrey,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool hasFilter = false, bool hasViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        if (hasFilter)
          const Icon(Icons.filter_list, color: AppColors.secondaryBlue),
        if (hasViewAll)
          GestureDetector(
            onTap: () {},
            child: const Text("View all",
                style: TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildAICard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBotScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI Trading Assistant",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  SizedBox(height: 4),
                  Text(
                      "Decode complex indicators and news with instant AI summaries.",
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedArticle() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsDetailScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://picsum.photos/seed/market/600/300',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              _buildAskAIBadge(12, 12),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Global markets react as inflation data suggests potential rate cuts in Q3.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text("Financial Times • 2 hours ago",
              style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAskAIBadge(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 14),
            SizedBox(width: 6),
            Text("Ask AI", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpinionCard(BuildContext context, String imgUrl, String author, String summary) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsDetailScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: NetworkImage(imgUrl)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(color: AppColors.secondaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallArticle(BuildContext context, {required bool isBullish, String title = "Winter storm impacts energy sector..."}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsDetailScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network('https://picsum.photos/seed/$title/100', width: 90, height: 90, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Ticker ", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                      Text(isBullish ? "+0.82%" : "-1.14%",
                          style: TextStyle(color: isBullish ? AppColors.profitGreen : AppColors.lossRed, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text("Bloomberg • 4h ago", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                      Spacer(),
                      Icon(Icons.mode_comment_outlined, color: AppColors.textGrey, size: 14),
                      SizedBox(width: 4),
                      Text("5", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
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