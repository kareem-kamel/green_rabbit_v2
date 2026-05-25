import 'package:flutter_bloc/flutter_bloc.dart';
import 'news_state.dart';
import '../../data/repositories/news_repository.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;

  NewsCubit({required this.repository}) : super(NewsInitial());

  // THIS NAME MUST MATCH WHAT YOU TYPE IN MAIN.DART
  Future<void> fetchNewsFeed({int limit = 10, String? category}) async {
    try {
      emit(NewsLoading());
      var articles = await repository.fetchNewsFeed(limit: limit, category: category);
      
      // Local filtering as a safeguard if the backend returns mixed news
      // However, we should be careful not to be too strict, especially for Forex.
      if (category != null && category.toLowerCase() != 'featured' && category.toLowerCase() != 'popular') {
        final targetType = category.toLowerCase();
        articles = articles.where((a) {
          final articleType = a.type.toLowerCase();
          
          // If the article explicitly says it's of the target type, keep it.
          if (articleType.contains(targetType)) return true;
          
          final cats = a.categories.map((c) => c.toLowerCase()).toList();
          final tags = a.tags.map((t) => t.toLowerCase()).toList();
          final tickers = a.tickers.map((t) => t.toLowerCase()).toList();
          
          // Loosen filtering for Forex to also catch 'fx' or common currency pairs
          if (targetType == 'forex') {
            final forexTerms = [
              'forex', 'fx', 'currency', 'exchange rate', 
              'eur', 'usd', 'gbp', 'jpy', 'aud', 'chf', 'cad', 'nzd', 'hkd', 'sgd',
              'gold', 'xau', 'silver', 'xag'
            ];
            return articleType.contains('forex') || articleType.contains('fx') ||
                   cats.any((c) => forexTerms.any((term) => c.contains(term))) ||
                   tags.any((t) => forexTerms.any((term) => t.contains(term))) ||
                   tickers.any((t) => forexTerms.any((term) => t.contains(term)));
          }

          return articleType.contains(targetType) || 
                 cats.any((c) => c.contains(targetType)) ||
                 tags.any((t) => t.contains(targetType)) ||
                 tickers.any((t) => t.contains(targetType));
        }).toList();
      }
      
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError("Error: ${e.toString()}"));
    }
  }

  Future<void> fetchFavoriteNews({int limit = 10}) async {
    try {
      // Load from cache first for immediate display
      final cachedArticles = repository.getCachedFavorites();
      if (cachedArticles.isNotEmpty) {
        emit(NewsLoaded(cachedArticles));
      } else {
        emit(NewsLoading());
      }

      final articles = await repository.fetchFavoriteArticles(limit: limit);
      
      // Update cache with fresh data
      await repository.cacheFavorites(articles);
      
      emit(NewsLoaded(articles));
    } catch (e) {
      // If we already have cached data, don't emit error
      if (state is! NewsLoaded) {
        emit(NewsError("Error: ${e.toString()}"));
      }
    }
  }

  void toggleFavoriteLocally(String articleId, bool isBookmarked, {bool isFavoritesTab = false}) {
    if (state is NewsLoaded) {
      final currentState = state as NewsLoaded;
      final updatedArticles = currentState.articles.map((article) {
        if (article.id == articleId) {
          return article.copyWith(isBookmarked: isBookmarked);
        }
        return article;
      }).toList();

      if (isFavoritesTab && !isBookmarked) {
        updatedArticles.removeWhere((article) => article.id == articleId);
      }

      emit(NewsLoaded(updatedArticles));
      
      // Sync cache after local toggle
      repository.cacheFavorites(updatedArticles.where((a) => a.isBookmarked).toList());
    }
  }
}