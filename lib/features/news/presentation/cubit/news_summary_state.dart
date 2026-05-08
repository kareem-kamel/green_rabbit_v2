import 'package:equatable/equatable.dart';
import '../../../chatbot/data/models/chat_message_model.dart';

abstract class NewsSummaryState extends Equatable {
  const NewsSummaryState();

  @override
  List<Object?> get props => [];
}

class NewsSummaryInitial extends NewsSummaryState {}

class NewsSummaryLoading extends NewsSummaryState {}

class NewsSummaryLoaded extends NewsSummaryState {
  final AISummary summary;

  const NewsSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class NewsSummaryError extends NewsSummaryState {
  final String message;

  const NewsSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
