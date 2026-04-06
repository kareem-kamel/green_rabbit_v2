import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/subscription_repository.dart';
import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionCubit({required this.repository}) : super(SubscriptionInitial());

  Future<void> init() async {
    try {
      emit(SubscriptionLoading());
      final plans = await repository.fetchPlans();
      final currentSub = await repository.fetchCurrentSubscription();
      final history = await repository.fetchHistory();
      emit(SubscriptionLoaded(plans: plans, currentSubscription: currentSub, history: history));
    } catch (e) {
      emit(const SubscriptionError(message: 'Failed to load subscription data'));
    }
  }

  Future<void> startTrial() async {
    try {
      emit(SubscriptionLoading());
      final sub = await repository.startTrial();
      
      // We emit TrialStartingSuccess first so UI can show the success dialog
      emit(TrialStartingSuccess(subscription: sub));
      
      // Then we transition back to Loaded with the new active subscription
      final plans = await repository.fetchPlans();
      final history = await repository.fetchHistory();
      emit(SubscriptionLoaded(plans: plans, currentSubscription: sub, history: history));
    } catch (e) {
      emit(const SubscriptionError(message: 'Failed to start free trial'));
    }
  }

  Future<void> buyPlan({String planId = 'plan_pro_yearly'}) async {
    try {
      emit(SubscriptionLoading());
      final sub = await repository.buyPlan(planId: planId);
      
      // We emit PurchaseSuccess first so UI can show the success dialog
      emit(PurchaseSuccess(subscription: sub));
      
      // Then we transition back to Loaded with the new active subscription
      final plans = await repository.fetchPlans();
      final history = await repository.fetchHistory();
      emit(SubscriptionLoaded(plans: plans, currentSubscription: sub, history: history));
    } catch (e) {
      emit(const SubscriptionError(message: 'Failed to process purchase'));
    }
  }

  Future<void> cancelSubscription({String reason = 'other'}) async {
    try {
      emit(SubscriptionLoading());
      await repository.cancelSubscription(reason: reason);
      
      final plans = await repository.fetchPlans();
      final currentSub = await repository.fetchCurrentSubscription();
      final history = await repository.fetchHistory();
      emit(SubscriptionLoaded(plans: plans, currentSubscription: currentSub, history: history));
    } catch (e) {
      emit(const SubscriptionError(message: 'Failed to cancel subscription'));
    }
  }
}
