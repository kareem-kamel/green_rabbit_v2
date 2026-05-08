import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';
import 'news_detail_screen.dart';

class DeepLinkArticleHandler extends StatefulWidget {
  final String articleId;

  const DeepLinkArticleHandler({super.key, required this.articleId});

  @override
  State<DeepLinkArticleHandler> createState() => _DeepLinkArticleHandlerState();
}

class _DeepLinkArticleHandlerState extends State<DeepLinkArticleHandler> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchArticle();
  }

  Future<void> _fetchArticle() async {
    try {
      final repository = di.sl<NewsRepository>();
      final article = await repository.fetchArticleDetail(widget.articleId);
      
      if (article != null && mounted) {
        // Replace current loading screen with actual article
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(article: article),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Article not found.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load article.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator(color: AppColors.primaryPurple)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? "An error occurred",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Go Back", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
      ),
    );
  }
}
