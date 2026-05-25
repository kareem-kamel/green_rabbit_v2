import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ai_news_summary_card.dart';
import '../../../../core/widgets/ask_ai_badge.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';
import '../cubit/related_news_cubit.dart';
import '../cubit/news_cubit.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/image_utils.dart';

import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/app_card.dart';

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
  NewsArticle? _fullArticle;
  bool _isLoadingDetail = false;
  bool _showAllRelated = false;
  bool _showAllAnalysis = false;
  bool _showAllComments = false;

  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;

  Future<void> _loadArticleDetailAndRelated() async {
    context.read<RelatedNewsCubit>().reset();

    setState(() {
      _isLoadingDetail = true;
    });

    NewsArticle? detail;
    try {
      detail = await di.sl<NewsRepository>().fetchArticleDetail(
        widget.article.id,
        type: widget.article.type,
      );
    } catch (e) {
      print('DEBUG: fetchArticleDetail error: $e');
    }

    if (mounted) {
      setState(() {
        if (detail != null) {
          _fullArticle = detail;
          _isFavorited = detail.isBookmarked;
        }
        _isLoadingDetail = false;
      });
    }

    if (!mounted) return;

    await context.read<RelatedNewsCubit>().fetchRelatedNews(
      widget.article.id,
      type: detail?.type ?? widget.article.type,
      fallback: detail?.relatedNews ?? widget.article.relatedNews,
    );
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final comments = await di.sl<NewsRepository>().fetchComments(
        widget.article,
        'news_article',
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

      final success = await di.sl<NewsRepository>().postComment(
        widget.article,
        'news_article',
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
        ? await di.sl<NewsRepository>().unlikeComment(comment.id)
        : await di.sl<NewsRepository>().likeComment(comment.id);

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

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.article.isBookmarked;
    _fullArticle = widget.article;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticleDetailAndRelated();
      _loadComments();
    });
  }

  void _toggleFavorite() async {
    final article = _fullArticle ?? widget.article;
    final success = await di.sl<NewsRepository>().toggleFavorite(
      article,
      !_isFavorited,
    );
    if (success) {
      context.read<NewsCubit>().toggleFavoriteLocally(widget.article.id, !_isFavorited);
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
            onPressed: () {
              final String deepLink = "https://greenrabbit.com/article?id=${widget.article.id}";
              final String shareText = widget.article.url.isNotEmpty 
                  ? "${widget.article.title}\n\nRead more: ${widget.article.url}\n\nOpen in Green Rabbit App: $deepLink" 
                  : "${widget.article.title}\n\nOpen in Green Rabbit App: $deepLink";
              Share.share(shareText);
            },
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
                      if (widget.article.sentiment.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (widget.article.sentiment.toLowerCase() == 'bullish' ? Colors.green : (widget.article.sentiment.toLowerCase() == 'bearish' ? Colors.red : Colors.grey)).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.article.sentiment.toUpperCase(),
                            style: TextStyle(
                              color: widget.article.sentiment.toLowerCase() == 'bullish' ? Colors.green : (widget.article.sentiment.toLowerCase() == 'bearish' ? Colors.red : Colors.grey),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.article.largeImage.isNotEmpty
                            ? Image.network(
                                ImageUtils.getSafeImageUrl(widget.article.largeImage),
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
                                  summaryId: widget.article.id,
                                  summaryType: 'news_article',
                                  summaryUrl: widget.article.url,
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
                  if (widget.article.tickers.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: widget.article.tickers.map((ticker) {
                          return _buildStockChip(ticker);
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
                            summaryId: widget.article.id,
                            summaryType: 'news_article',
                            summaryUrl: widget.article.url,
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

                  if ((_fullArticle ?? widget.article).content.length > 200 || 
                      (_fullArticle ?? widget.article).summary.length > 200)
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
                  key: ValueKey("comments_list_${_showAllComments}"),
                  children: (_showAllComments ? _comments : _comments.take(3))
                      .map((c) => _buildCommentCard(c))
                      .toList(),
                ),
              ),
              if (_comments.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(height: 8),
            _buildSeparator(),
            const SizedBox(height: 8),

            // ── Analysis & Opinions section
            if (_isLoadingDetail && (_fullArticle == null || _fullArticle!.analysisOpinions.isEmpty)) ...[
              _buildSectionHeader("Analysis & Opinions"),
              ...List.generate(2, (index) => _buildSkeletonRelatedItem()),
              const SizedBox(height: 8),
              _buildSeparator(),
              const SizedBox(height: 8),
            ] else if (_fullArticle != null && _fullArticle!.analysisOpinions.isNotEmpty) ...[
              _buildSectionHeader(
                "Analysis & Opinions",
                hasViewAll: _fullArticle!.analysisOpinions.length > 3,
                onViewAll: () => setState(() => _showAllAnalysis = !_showAllAnalysis),
                isExpanded: _showAllAnalysis,
              ),
              ...( _showAllAnalysis 
                  ? _fullArticle!.analysisOpinions 
                  : _fullArticle!.analysisOpinions.take(3)
                ).map((analysis) => _buildRelatedItem(analysis)).toList(),
              const SizedBox(height: 8),
              _buildSeparator(),
              const SizedBox(height: 8),
            ],

            // ── Related news
            _buildSectionHeader(
              "Related News",
              hasViewAll: true,
              onViewAll: () => setState(() => _showAllRelated = !_showAllRelated),
              isExpanded: _showAllRelated,
            ),
            BlocBuilder<RelatedNewsCubit, RelatedNewsState>(
              builder: (context, state) {
                List<NewsArticle> relatedArticles = [];
                bool isLoading = false;
                String? error;

                if (state is RelatedNewsLoading) {
                  isLoading = true;
                } else if (state is RelatedNewsError) {
                  error = state.message;
                } else if (state is RelatedNewsLoaded) {
                  relatedArticles = state.articles;
                }

                // Fallback to related news from the detail response if cubit is empty or loading
                if (relatedArticles.isEmpty && _fullArticle != null && _fullArticle!.relatedNews.isNotEmpty) {
                  relatedArticles = _fullArticle!.relatedNews;
                  // If we have fallback data, don't show loading/error
                  isLoading = false;
                  error = null;
                }

                if (isLoading && relatedArticles.isEmpty) {
                  return Column(
                    children: List.generate(3, (index) => _buildSkeletonRelatedItem()),
                  );
                } else if (error != null && relatedArticles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(error, style: const TextStyle(color: Colors.grey)),
                  );
                } else if (relatedArticles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No related news found", style: TextStyle(color: Colors.grey)),
                  );
                }

                final displayArticles = _showAllRelated 
                    ? relatedArticles 
                    : relatedArticles.take(3).toList();

                return AnimatedSwitcher(
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
                    key: ValueKey("related_list_${_showAllRelated}"),
                    children: displayArticles.map((article) => _buildRelatedItem(article)).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSeparator(),
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
    
    final article = _fullArticle ?? widget.article;

    if (_isLoadingDetail && article.content.isEmpty) {
      final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
      final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
      
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              width: index == 3 ? 200 : double.infinity,
              height: 16,
              color: Colors.white,
            ),
          )),
        ),
      );
    }

    final bodyText = article.content.isNotEmpty 
        ? article.content 
        : (article.summary.isNotEmpty ? article.summary : "No detailed content available for this article.");

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        );
      },
      child: Text(
        bodyText,
        key: ValueKey("body_${_isExpanded}"),
        maxLines: _isExpanded ? null : 4,
        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool hasViewAll = false, VoidCallback? onViewAll, bool isExpanded = false}) {
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
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                isExpanded ? "See less" : "View all",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
              ),
            ),
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

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String? avatarUrl;
        if (state is ProfileLoaded) {
          avatarUrl = state.user.avatarUrl;
        }

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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(article: article),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: article.thumbImage.isNotEmpty
                  ? Image.network(
                      ImageUtils.getSafeImageUrl(article.thumbImage),
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
      ),
    );
  }

  Widget _buildStockChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87)),
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

  Widget _buildSkeletonRelatedItem() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}