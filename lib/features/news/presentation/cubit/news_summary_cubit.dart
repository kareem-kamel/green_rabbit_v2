import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../chatbot/data/services/ai_service.dart';
import 'news_summary_state.dart';

class NewsSummaryCubit extends Cubit<NewsSummaryState> {
  final AIService _aiService;

  NewsSummaryCubit(this._aiService) : super(NewsSummaryInitial());

  Future<void> summarizeNews(String targetId) async {
    emit(NewsSummaryLoading());
    try {
      final summary = await _aiService.summarizeContent(targetId, 'news');
      emit(NewsSummaryLoaded(summary));
    } catch (e) {
      emit(NewsSummaryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() {
    emit(NewsSummaryInitial());
  }
}
