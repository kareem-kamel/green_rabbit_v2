import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'news_detail_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../alerts/create_alert_sheet.dart'; // Import the new alert sheet

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String selectedCategory = "Featured";

  // --- NEW: THE FUNCTION TO OPEN THE ALERT MENU ---
  void _openAlertMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAlertSheet(
        assetName: "Silver", // Hardcoded for now until you have a market list
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
        title: const Text("News",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search), 
            onPressed: () {}
          ),
          // --- UPDATED: THIS ICON NOW OPENS THE ALERT SYSTEM ---
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
            const SizedBox(height: 20),

            // Category chips
            _buildCategoryRow(),
            const SizedBox(height: 20),

            // Section header
            _buildSectionHeader("Top News", hasFilter: true),
            const SizedBox(height: 12),

            // Featured article
            _buildFeaturedArticle(),
            const SizedBox(height: 24),

            // Opinion cards
            _buildSectionHeader("Opinions", hasViewAll: true),
            const SizedBox(height: 12),
            _buildOpinionCard(context, 'https://i.pravatar.cc/150?u=op1'),
            _buildOpinionCard(context, 'https://i.pravatar.cc/150?u=op2'),
            const SizedBox(height: 24),

            // Small articles
            _buildSectionHeader("More News", hasViewAll: true),
            const SizedBox(height: 12),
            _buildSmallArticle(context, isBullish: true),
            _buildSmallArticle(context, isBullish: false,
                title: "Apple unveils new MacBook Pro with M4 chip..."),
            _buildSmallArticle(context, isBullish: true,
                title: "Oil prices stabilize after OPEC+ meeting..."),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ... rest of your existing _build methods stay the same ...
  // (e.g., _buildCategoryRow, _buildSectionHeader, _buildAICard, etc.)

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip("Featured"),
          _buildCategoryChip("Most Popular"),
          _buildCategoryChip("Cryptocurrency"),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isActive = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primaryPurple
                : AppColors.textGrey.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGrey,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {bool hasFilter = false, bool hasViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        if (hasFilter)
          const Icon(Icons.filter_list, color: AppColors.secondaryBlue),
        if (hasViewAll)
          TextButton(
            onPressed: () {},
            child: const Text("View all",
                style: TextStyle(color: AppColors.secondaryBlue)),
          ),
      ],
    );
  }

  Widget _buildAICard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatBotScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI Trading Assistant",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
                  Text(
                      "Understand prices, indicators, and news with AI-powered explanations",
                      style:
                          TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedArticle() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewsDetailScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://picsum.photos/seed/news1/400/200'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              _buildAskAIBadge(10, 10),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "The United States is bracing for a winter storm that will impact the energy sector.",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          const Text("Reuters . 3 hours ago",
              style:
                  TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAskAIBadge(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome,
                color: AppColors.primaryPurple, size: 14),
            SizedBox(width: 4),
            Text("Ask AI",
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpinionCard(BuildContext context, String imgUrl) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewsDetailScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
                radius: 24, backgroundImage: NetworkImage(imgUrl)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Market Analysis: Winter trends and energy costs...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  Text("Reuters . 3 hours ago",
                      style: TextStyle(
                          color: AppColors.textGrey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallArticle(
    BuildContext context, {
    required bool isBullish,
    String title =
        "The United States is bracing for a winter storm...",
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewsDetailScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                  'https://picsum.photos/seed/small/80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("ATCOa ",
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 11)),
                      Text(
                          isBullish ? "+0.47%" : "-0.47%",
                          style: TextStyle(
                              color: isBullish
                                  ? AppColors.profitGreen
                                  : AppColors.lossRed,
                              fontSize: 11)),
                    ],
                  ),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const Row(
                    children: [
                      Text("Reuters . 3 hours ago",
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 10)),
                      Spacer(),
                      Icon(Icons.chat_bubble_outline,
                          color: AppColors.textGrey, size: 14),
                      SizedBox(width: 4),
                      Text("2",
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 10)),
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