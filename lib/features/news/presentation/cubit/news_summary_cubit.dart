import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../chatbot/data/services/ai_service.dart';
import '../../data/models/news_model.dart';
import 'news_summary_state.dart';

class NewsSummaryCubit extends Cubit<NewsSummaryState> {
  final AIService _aiService;

  NewsSummaryCubit(this._aiService) : super(NewsSummaryInitial());

  Future<void> summarizeNews(NewsArticle article) async {
    emit(NewsSummaryLoading());
    try {
      final isNews = article.url.isNotEmpty;
      final target = isNews ? article.url : article.id;
      final type = isNews ? 'news' : 'article';
      final summary = await _aiService.summarizeContent(target, type);
      emit(NewsSummaryLoaded(summary));
    } catch (e) {
      emit(NewsSummaryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() {
    emit(NewsSummaryInitial());
  }
}
