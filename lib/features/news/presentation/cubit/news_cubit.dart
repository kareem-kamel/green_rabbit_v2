import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'news_state.dart';
import '../../data/repositories/news_repository.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;

  NewsCubit({required this.repository}) : super(NewsInitial());

  // Fetch initial news feed
  Future<void> fetchNewsFeed({int limit = 10, String? category, String? country, String? region}) async {
    try {
      emit(NewsLoading());
      final articles = await repository.fetchNewsFeed(
        page: 1,
        limit: limit,
        category: category,
        country: country,
        region: region,
      );
      
      // If we got fewer articles than requested, we assume there's no more
      final hasMore = articles.length >= limit;
      
      emit(NewsLoaded(
        articles,
        currentPage: 1,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('[ERROR] News feed error: $e');
      emit(NewsError("Unable to load news"));
    }
  }

  // Load more news for pagination
  Future<void> loadMoreNews({int limit = 10, String? category, String? country, String? region}) async {
    if (state is! NewsLoaded) return;
    
    final currentState = state as NewsLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final nextPage = currentState.currentPage + 1;
      final newArticles = await repository.fetchNewsFeed(
        page: nextPage,
        limit: limit,
        category: category,
        country: country,
        region: region,
      );
      
      final hasMore = newArticles.length >= limit;
      final allArticles = [...currentState.articles, ...newArticles];
      
      emit(NewsLoaded(
        allArticles,
        currentPage: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('[ERROR] Load more news error: $e');
      // On error, we just stop loading more but keep existing articles
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> fetchFavoriteNews({int limit = 20}) async {
    try {
      // Load from cache first for immediate display
      final cachedArticles = repository.getCachedFavorites();
      if (cachedArticles.isNotEmpty) {
        emit(NewsLoaded(cachedArticles, hasMore: false)); // Favorites usually don't paginate in this app's logic yet
      } else {
        emit(NewsLoading());
      }

      final articles = await repository.fetchFavoriteArticles(limit: limit);
      
      // Update cache with fresh data
      await repository.cacheFavorites(articles);
      
      emit(NewsLoaded(articles, hasMore: false));
    } catch (e) {
      debugPrint('[ERROR] Fetch favorite news error: $e');
      // If we already have cached data, don't emit error
      if (state is! NewsLoaded) {
        emit(NewsError("Unable to load favorites"));
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