import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────
class CommentModel {
  final String name;
  final String text;
  final String time;

  CommentModel({required this.name, required this.text, required this.time});
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final TextEditingController _commentController = TextEditingController(); // FIXED: was 'commentController'
  bool _isExpanded = false;

  final List<CommentModel> _comments = [
    CommentModel(
        name: "Mahmoud Ali",
        text: "I expect a surge in this stock, and it was very important.",
        time: "11 hours ago"),
    CommentModel(
        name: "Mahmoud Ali",
        text:
            "I expect a surge in this stock, and it was very important, I expect.",
        time: "11 hours ago"),
  ];

  void _postComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(
          0,
          CommentModel(
            name: "Guest User",
            text: _commentController.text,
            time: "Just now",
          ),
        );
        _commentController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main article section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "The United States is bracing for a winter storm that will impact the energy sector",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text("Reuters | January 25, 2026, 10:40",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),

                  // Article image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://picsum.photos/seed/storm/600/300',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStockChip("CIEN", "-0.39%"),
                        _buildStockChip("SBUX", "-0.39%"),
                        _buildStockChip("ULTA", "-0.39%"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI summary box
                  _buildAISummaryBox(),
                  const SizedBox(height: 24),

                  // Article body text
                  _buildArticleBody(),
                  const SizedBox(height: 16),

                  // See more/less button
                  _buildSeeMoreButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Ad banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAdBanner(),
            ),
            const SizedBox(height: 24),

            // ── Analyst opinions
            _buildSectionHeader("Analyst Opinions"),
            _buildAnalysisItem(),
            _buildAnalysisItem(),
            const SizedBox(height: 24),

            // ── Related news
            _buildSectionHeader("Related News", hasViewAll: true),
            _buildRelatedItem(),
            _buildRelatedItem(),
            const SizedBox(height: 24),

            // ── Comments section
            _buildSectionHeader("Comments"),
            _buildCommentInput(),
            const SizedBox(height: 8),
            ..._comments.map((c) => _buildCommentCard(c)).toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ARTICLE BODY  (was missing entirely)
  // ─────────────────────────────────────────────
  Widget _buildArticleBody() {
    const fullText =
        "A powerful winter storm system is expected to sweep across large parts of the United States this week, with forecasters warning of significant disruptions to energy infrastructure. Utility companies are already ramping up emergency response teams, while natural gas futures jumped amid concerns about supply chain disruptions. "
        "The storm is expected to bring heavy snow, ice, and dangerously cold temperatures to the central and eastern regions, affecting millions of households and businesses that rely on natural gas and electricity for heating. "
        "Energy analysts warn that a prolonged cold snap could stress the electrical grid, echoing the 2021 Texas power crisis.";

    const shortText =
        "A powerful winter storm system is expected to sweep across large parts of the United States this week, with forecasters warning of significant disruptions to energy infrastructure.";

    return Text(
      _isExpanded ? fullText : shortText,
      style: const TextStyle(
          color: Colors.white70, fontSize: 14, height: 1.6),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool hasViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (hasViewAll)
            const Text("View all",
                style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton() {
    return SizedBox(
      width: 140,
      child: ElevatedButton(
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(_isExpanded ? "See Less" : "See More",
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/seed/ads/600/200'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.1),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "NEW SPRING\nCOLLECTION",
                style: TextStyle(
                    color: Color(0xFF4A3420),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A3420)),
              child: const Text("SHOP NOW",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage:
                NetworkImage('https://i.pravatar.cc/150?u=user'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController, // FIXED: correct reference
              onSubmitted: (_) => _postComment(), // FIXED: correct signature
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Write a comment here...!",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent, size: 20),
            onPressed: _postComment,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?u=${comment.name}'),
              ),
              const SizedBox(width: 8),
              Text(comment.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white)),
              const Spacer(),
              Text(comment.time,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 4),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.text,
              style:
                  const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text("Replies (2)",
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
              SizedBox(width: 16),
              Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.thumb_down_outlined,
                  size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage:
                NetworkImage('https://i.pravatar.cc/150?u=analyst'),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The United States is bracing for a winter storm...",
                  maxLines: 2,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text("Reuters . 3 hours ago",
                    style:
                        TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://picsum.photos/seed/rel/80',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The United States is bracing for a winter storm...",
                  maxLines: 2,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text("Reuters . 3 hours ago",
                    style:
                        TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(String label, String percent) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white)),
          const SizedBox(width: 8),
          Text(percent,
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 12)),
          const SizedBox(width: 6),
          const Icon(Icons.star_border, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAISummaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.indigoAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_motion,
                color: Colors.indigoAccent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Summarize the news using AI.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white)),
                Text("What matters most to investors",
                    style:
                        TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.north_east, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}