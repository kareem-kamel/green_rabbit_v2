import '../models/subscription_model.dart';
import '../models/transaction_model.dart';

class SubscriptionRepository {
  // In a real app, this would use Dio/ApiClient
  SubscriptionModel? _currentSubscription;
  final List<TransactionModel> _transactions = [];
  bool _hasUsedTrial = false;

  Future<List<TransactionModel>> fetchHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions;
  }

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allPlans = [
      {
        'id': 'plan_free',
        'name': 'Free Trial',
        'price': 0.0,
        'features': [
          'Limited AI access',
          'AI Chatbot (5 Free Credits / day)',
          'AI News Summaries',
          'Ads included',
        ],
        'trialDays': 7,
      },
      {
        'id': 'plan_pro_yearly',
        'name': 'Experience the full power of AI',
        'price': 9.99,
        'features': [
          'Priority customer support',
          'Real-time AI trading signals',
          'Custom alerts & notifications',
          'API access for automation',
          'Expert community access',
          'Unlimited watchlists',
          'Advanced charting tools',
          'Advanced portfolio tracking',
        ],
        'isPro': true,
      },
      {
        'id': 'plan_classic_yearly',
        'name': 'Classic Plan',
        'price': 4.99,
        'features': [
          'Remove Ads lifetime',
          'Limited AI access for 7 Day',
          'AI News Summaries for 7 Day',
        ],
      },
    ];

    // Remove Free Trial if user has already used it or has an active Pro sub
    if (_hasUsedTrial || (_currentSubscription != null && _currentSubscription!.status != 'none')) {
      allPlans.removeWhere((p) => p['id'] == 'plan_free');
    }

    return allPlans;
  }

  Future<SubscriptionModel?> fetchCurrentSubscription() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentSubscription;
  }

  Future<SubscriptionModel> startTrial() async {
    await Future.delayed(const Duration(seconds: 1));
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 3));
    final endDate = startDate.add(const Duration(days: 7));
    
    _hasUsedTrial = true;
    _currentSubscription = SubscriptionModel(
      id: 'sub_trial_123',
      planId: 'plan_pro_trial',
      planName: '7-Day Free Trial',
      status: 'active',
      currentPeriodStart: startDate,
      currentPeriodEnd: endDate,
      features: ['all_pro_features'],
    );
    
    return _currentSubscription!;
  }

  Future<SubscriptionModel> buyPlan({String planId = 'plan_pro_yearly'}) async {
    await Future.delayed(const Duration(seconds: 1));
    final startDate = DateTime.now();
    final nextBillingDate = DateTime(2026, 3, 28);
    
    final isPro = planId.contains('pro');
    
    _hasUsedTrial = true;
    _currentSubscription = SubscriptionModel(
      id: 'sub_${planId}_${DateTime.now().millisecondsSinceEpoch}',
      planId: planId,
      planName: isPro ? 'Yearly pro plan' : 'Yearly Classic plan',
      status: 'active',
      currentPeriodStart: startDate,
      currentPeriodEnd: nextBillingDate,
      isFullPro: isPro,
      paymentMethod: PaymentMethodModel(last4: '4242', brand: 'visa'),
      features: isPro ? ['all_pro_features_full'] : ['no_ads', 'limited_ai'],
    );

    // Record transaction
    _transactions.insert(
        0,
        TransactionModel(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          planName: isPro ? 'Premium yearly subscription' : 'Classic yearly subscription',
          date: startDate,
          amount: isPro ? 99.99 : 8.99,
          status: 'States',
          paymentMethod: 'visa .... 4242',
          transactionId: 'TXN-2026-${_transactions.length + 1}',
          discount: isPro ? 20.0 : 0.0,
        ));

    return _currentSubscription!;
  }

  Future<void> cancelSubscription({String reason = 'other'}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentSubscription = SubscriptionModel.none();
  }
}
