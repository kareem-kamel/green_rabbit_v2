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
      
      // We rely entirely on the backend to filter categories.
      // The backend uses 'category' query parameter properly now.
      
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