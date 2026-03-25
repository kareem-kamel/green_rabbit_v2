import 'package:flutter_bloc/flutter_bloc.dart';

// ─── STATE ───
class NewsState {
  final String selectedCategory;
  final bool isExpanded;
  final List<Map<String, String>> comments;

  NewsState({
    required this.selectedCategory,
    required this.isExpanded,
    required this.comments,
  });

  NewsState copyWith({
    String? selectedCategory,
    bool? isExpanded,
    List<Map<String, String>>? comments,
  }) {
    return NewsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isExpanded: isExpanded ?? this.isExpanded,
      comments: comments ?? this.comments,
    );
  }
}

// ─── CUBIT ───
class NewsCubit extends Cubit<NewsState> {
  NewsCubit() : super(NewsState(
    selectedCategory: "Featured",
    isExpanded: false,
    comments: [
      {"name": "Mahmoud Ali", "text": "I expect a surge in this stock.", "time": "11h ago"},
    ],
  ));

  void selectCategory(String category) => emit(state.copyWith(selectedCategory: category));

  void toggleExpansion() => emit(state.copyWith(isExpanded: !state.isExpanded));

  void addComment(String text) {
    if (text.trim().isEmpty) return;
    final newComments = List<Map<String, String>>.from(state.comments);
    newComments.insert(0, {
      "name": "Guest User",
      "text": text,
      "time": "Just now",
    });
    emit(state.copyWith(comments: newComments));
  }
}