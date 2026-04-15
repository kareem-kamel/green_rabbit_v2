import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ai_news_summary_card.dart';
import '../../../../core/widgets/ask_ai_badge.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';
import '../cubit/related_news_cubit.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';
import '../../../../core/di/injection_container.dart' as di;

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
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late bool _isFavorited;
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
  void initState() {
    super.initState();
    _isFavorited = widget.article.isBookmarked;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RelatedNewsCubit>().fetchRelatedNews(widget.article.id);
    });
  }

  void _toggleFavorite() async {
    final success = await di.sl<NewsRepository>().toggleFavorite(
      widget.article.id,
      !_isFavorited,
    );
    if (success) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
                _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                color: _isFavorited ? AppColors.primaryPurple : (isDark ? Colors.white : Colors.black)),
            onPressed: _toggleFavorite,
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
                  Text(
                    widget.article.title,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.article.sourceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      Text(" | ${widget.article.timeAgo}",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.article.largeImage.isNotEmpty
                            ? Image.network(
                                widget.article.largeImage,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 220,
                                  color: isDark ? AppColors.cardBg : Colors.grey[300],
                                  child: Icon(Icons.image_not_supported,
                                      color: isDark ? Colors.white : Colors.black54),
                                ),
                              )
                            : Container(
                                height: 220,
                                color: isDark ? AppColors.cardBg : Colors.grey[300]),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatBotScreen(
                                  initialPrompt: "Tell me more about this news: ${widget.article.title}",
                                ),
                              ),
                            );
                          },
                          child: const AskAIBadge(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock chips
                  if (widget.article.relatedSymbols.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.article.relatedSymbols.map((symbol) {
                          return _buildStockChip(
                              symbol.symbol,
                              "${symbol.changePercent >= 0 ? '+' : ''}${symbol.changePercent}%",
                              symbol.changePercent >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent);
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // AI summary card under the chips (CIEN, SBUX, ...)
                  AiNewsSummaryCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatBotScreen(
                            initialPrompt: "Summarize this article: ${widget.article.title}\n\n${widget.article.snippet}",
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),

                  _buildArticleBody(),
                  const SizedBox(height: 16),

                  _buildSeeMoreButton(),
                  const SizedBox(height: 8),
                  _buildSeparator(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Ad banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAdBanner(),
            ),
            const SizedBox(height: 8),
            _buildSeparator(),
            const SizedBox(height: 8),

            // ── Comments section (moved before related sections)
            _buildSectionHeader("Comments"),
            _buildCommentInput(),
            const SizedBox(height: 8),
            ..._comments.map((c) => _buildCommentCard(c)),
            const SizedBox(height: 8),
            _buildSeparator(),
            const SizedBox(height: 8),

            // ── Related news
            _buildSectionHeader("Related News", hasViewAll: true),
            BlocBuilder<RelatedNewsCubit, RelatedNewsState>(
              builder: (context, state) {
                if (state is RelatedNewsLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is RelatedNewsError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(state.message, style: const TextStyle(color: Colors.grey)),
                  );
                } else if (state is RelatedNewsLoaded) {
                  if (state.articles.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No related news found", style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(
                    children: state.articles.map((article) => _buildRelatedItem(article)).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            _buildSeparator(),
            const SizedBox(height: 8),

            // ── Related analysis
            _buildSectionHeader("Related Analysis"),
            if (widget.article.relatedAnalysis.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No analysis available for this article.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ...widget.article.relatedAnalysis.map((analysis) =>
                  _buildAnalysisItem(analysis.firm, analysis.text)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bodyText = widget.article.snippet.isNotEmpty 
        ? widget.article.snippet 
        : "No detailed content available for this article.";

    return Text(
      bodyText,
      style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool hasViewAll = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
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
  }

  Widget _buildCommentCard(CommentModel comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                child: Text(comment.name[0], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 10)),
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
              const Icon(Icons.reply_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text("Reply", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 20),
              const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text("12",
                  style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String firm, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
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
                Text(firm,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text(text,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedItem(NewsArticle article) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: article.thumbImage.isNotEmpty
                ? Image.network(
                    article.thumbImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: isDark ? AppColors.cardBg : Colors.grey[300],
                      child: Icon(Icons.image_not_supported,
                          color: isDark ? Colors.white : Colors.black54),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: isDark ? AppColors.cardBg : Colors.grey[300],
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15)),
                const SizedBox(height: 8),
                Text("${article.sourceName} • ${article.timeAgo}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(String label, String percent, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(width: 8),
          Text(percent,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
          Image.asset(
            'assets/icons/rabbiticonAI.png',
            width: 28,
            height: 28,
          ),
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

  Widget _buildSeparator() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.borderGrey.withOpacity(0.08),
    );
  }
}