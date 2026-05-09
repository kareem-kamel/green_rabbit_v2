import 'package:flutter_bloc/flutter_bloc.dart';
import 'news_state.dart';
import '../../data/repositories/news_repository.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;

  NewsCubit({required this.repository}) : super(NewsInitial());

  // THIS NAME MUST MATCH WHAT YOU TYPE IN MAIN.DART
  Future<void> fetchNewsFeed() async {
    try {
      emit(NewsLoading());
      final articles = await repository.fetchNewsFeed();
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError("Error: ${e.toString()}"));
    }
  }

  void toggleFavoriteLocally(String articleId, bool isBookmarked) {
    if (state is NewsLoaded) {
      final currentState = state as NewsLoaded;
      final updatedArticles = currentState.articles.map((article) {
        if (article.id == articleId) {
          return article.copyWith(isBookmarked: isBookmarked);
        }
        return article;
      }).toList();
      emit(NewsLoaded(updatedArticles));
    }
  }
}