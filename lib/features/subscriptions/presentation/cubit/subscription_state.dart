import 'package:equatable/equatable.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/transaction_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<Map<String, dynamic>> plans;
  final SubscriptionModel? currentSubscription;
  final List<TransactionModel> history;

  const SubscriptionLoaded({
    required this.plans,
    required this.history,
    this.currentSubscription,
  });

  @override
  List<Object?> get props => [plans, currentSubscription, history];
}

class TrialStartingSuccess extends SubscriptionState {
  final SubscriptionModel subscription;

  const TrialStartingSuccess({required this.subscription});

  @override
  List<Object?> get props => [subscription];
}

class PurchaseSuccess extends SubscriptionState {
  final SubscriptionModel subscription;

  const PurchaseSuccess({required this.subscription});

  @override
  List<Object?> get props => [subscription];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError({required this.message});

  @override
  List<Object?> get props => [message];
}
