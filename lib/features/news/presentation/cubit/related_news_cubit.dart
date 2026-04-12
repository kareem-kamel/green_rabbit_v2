import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';

// States
abstract class RelatedNewsState {}
class RelatedNewsInitial extends RelatedNewsState {}
class RelatedNewsLoading extends RelatedNewsState {}
class RelatedNewsLoaded extends RelatedNewsState {
  final List<NewsArticle> articles;
  RelatedNewsLoaded(this.articles);
}
class RelatedNewsError extends RelatedNewsState {
  final String message;
  RelatedNewsError(this.message);
}

// Cubit
class RelatedNewsCubit extends Cubit<RelatedNewsState> {
  final NewsRepository repository;

  RelatedNewsCubit({required this.repository}) : super(RelatedNewsInitial());

  Future<void> fetchRelatedNews(String id) async {
    emit(RelatedNewsLoading());
    try {
      final articles = await repository.fetchRelatedNews(id);
      emit(RelatedNewsLoaded(articles));
    } catch (e) {
      emit(RelatedNewsError(e.toString()));
    }
  }
}
