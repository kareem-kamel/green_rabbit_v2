import '../../data/models/news_model.dart';

abstract class NewsState {}

// 1. The initial state when the app first starts
class NewsInitial extends NewsState {}

// 2. The state when we are waiting for Apidog to respond
class NewsLoading extends NewsState {}

// 3. The state when the data is successfully fetched
class NewsLoaded extends NewsState {
  final List<NewsArticle> articles;
  NewsLoaded(this.articles);
}

// 4. The state if the API link fails or there is no internet
class NewsError extends NewsState {
  final String message;
  NewsError(this.message);
}