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
  final TextEditingController _commentController = TextEditingController();
  bool _isExpanded = false;

  final List<CommentModel> _comments = [
    CommentModel(
        name: "Mahmoud Ali",
        text: "I expect a surge in this stock, and it was very important.",
        time: "11 hours ago"),
    CommentModel(
        name: "Sarah Jenkins",
        text: "The energy sector is definitely looking volatile this quarter. Great summary!",
        time: "12 hours ago"),
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub Dark style
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text("Reuters", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(" | January 25, 2026, 10:40", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://picsum.photos/seed/energy/800/450',
                      height: 220,
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
                        _buildStockChip("CIEN", "-0.39%", Colors.redAccent),
                        _buildStockChip("SBUX", "+1.24%", Colors.greenAccent),
                        _buildStockChip("ULTA", "-0.15%", Colors.redAccent),
                        _buildStockChip("TSLA", "+2.10%", Colors.greenAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildAISummaryBox(),
                  const SizedBox(height: 24),

                  _buildArticleBody(),
                  const SizedBox(height: 16),

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
            const SizedBox(height: 32),

            // ── Analyst opinions
            _buildSectionHeader("Analyst Opinions"),
            _buildAnalysisItem("Goldman Sachs", "Neutral rating maintained despite storm concerns."),
            _buildAnalysisItem("Morgan Stanley", "Energy infrastructure remains resilient."),
            const SizedBox(height: 32),

            // ── Related news
            _buildSectionHeader("Related News", hasViewAll: true),
            _buildRelatedItem("Natural gas prices surge as cold front approaches", "3 hours ago"),
            _buildRelatedItem("How to prepare your portfolio for climate volatility", "5 hours ago"),
            const SizedBox(height: 32),

            // ── Comments section
            _buildSectionHeader("Comments"),
            _buildCommentInput(),
            const SizedBox(height: 8),
            ..._comments.map((c) => _buildCommentCard(c)).toList(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ARTICLE BODY
  // ─────────────────────────────────────────────
  Widget _buildArticleBody() {
    const fullText =
        "A powerful winter storm system is expected to sweep across large parts of the United States this week, with forecasters warning of significant disruptions to energy infrastructure. Utility companies are already ramping up emergency response teams, while natural gas futures jumped amid concerns about supply chain disruptions.\n\n"
        "The storm is expected to bring heavy snow, ice, and dangerously cold temperatures to the central and eastern regions, affecting millions of households and businesses that rely on natural gas and electricity for heating. "
        "Energy analysts warn that a prolonged cold snap could stress the electrical grid, echoing the 2021 Texas power crisis.";

    const shortText =
        "A powerful winter storm system is expected to sweep across large parts of the United States this week, with forecasters warning of significant disruptions to energy infrastructure...";

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _isExpanded ? fullText : shortText,
        style: const TextStyle(
            color: Colors.white70, fontSize: 16, height: 1.6),
      ),
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
                  fontSize: 20,
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
    return ElevatedButton(
      onPressed: () => setState(() => _isExpanded = !_isExpanded),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigoAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: Text(_isExpanded ? "See Less" : "See More",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/seed/fashion/600/200'),
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

  Widget _buildCommentInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=me'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              onSubmitted: (_) => _postComment(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                hintStyle: TextStyle(color: Colors.grey),
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
  }

  Widget _buildCommentCard(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${comment.name}'),
              ),
              const SizedBox(width: 10),
              Text(comment.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              const Spacer(),
              Text(comment.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment.text, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.reply_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text("Reply", style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(width: 20),
              Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text("12", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String firm, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firm, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network('https://picsum.photos/seed/$title/100', width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                const SizedBox(height: 8),
                Text("Reuters • $time", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(String label, String percent, Color color) {
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          const SizedBox(width: 8),
          Text(percent, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAISummaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.withOpacity(0.3), Colors.blue.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Smart Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                Text("Get the key investor takeaways", style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
        ],
      ),
    );
  }
}