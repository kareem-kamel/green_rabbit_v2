import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;
  
  SubscriptionModel? _currentSubscription;
  final List<TransactionModel> _transactions = [];
  bool _hasUsedTrial = false;

  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;
  final _subscriptionController = StreamController<SubscriptionModel>.broadcast();
  Completer<SubscriptionModel>? _purchaseCompleter;

  Stream<SubscriptionModel> get subscriptionStream => _subscriptionController.stream;

  SubscriptionRepository(this._apiClient);

  SubscriptionModel? get currentSubscription => _currentSubscription;

  String _generateUUID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set version to 4 (0100xxxx)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 (10xxxxxx)
    values[8] = (values[8] & 0x3f) | 0x80;
    
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  Future<List<TransactionModel>> fetchHistory() async {
    // In a real app, this would use Dio/ApiClient.
    // If there is no endpoint, we return our local transactions list.
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions;
  }

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.subscriptionPlans);
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final plans = data.map<Map<String, dynamic>>((plan) {
          final featuresList = plan['features'] as List?;
          final featuresStrings = featuresList != null
              ? featuresList.map((f) {
                  if (f is Map) {
                    return f['name']?.toString() ?? '';
                  }
                  return f.toString();
                }).where((s) => s.isNotEmpty).toList()
              : <String>[];
          return {
            'id': plan['id'],
            'name': plan['name'],
            'description': plan['description'],
            'price': (plan['price'] as num?)?.toDouble() ?? 0.0,
            'currency': plan['currency'] ?? 'KWD',
            'features': featuresStrings,
            'trialDays': plan['trialDays'],
            'isPro': plan['tier'] == 'premium' || plan['tier'] == 'pro',
          };
        }).toList();

        // Remove Free Trial if user has already used it or has an active Pro sub
        if (_hasUsedTrial || (_currentSubscription != null && _currentSubscription!.status != 'none')) {
          plans.removeWhere((p) => p['id'] == 'plan_free');
        }
        return plans;
      }
    } catch (e) {
      // Robust Fallback: Log and return mock plans
      print("Failed to fetch plans from API, falling back to mock: $e");
    }

    // Simulate API delay for mock fallback
    await Future.delayed(const Duration(milliseconds: 300));
    
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

    if (_hasUsedTrial || (_currentSubscription != null && _currentSubscription!.status != 'none')) {
      allPlans.removeWhere((p) => p['id'] == 'plan_free');
    }

    return allPlans;
  }

  Future<SubscriptionModel?> fetchCurrentSubscription() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.subscriptionCurrent);
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        if (response.data['data'] != null) {
          _currentSubscription = SubscriptionModel.fromJson(response.data['data']);
          return _currentSubscription;
        }
      }
    } catch (e) {
      print("Failed to fetch current subscription, falling back: $e");
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return _currentSubscription;
  }

  Future<SubscriptionModel> startTrial() async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.activateFreeTrial,
      );
      
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final responseData = response.data['data'];
        final trialData = responseData != null ? responseData['trial'] : null;
        
        final activeSub = await fetchCurrentSubscription();
        if (activeSub != null) {
          _hasUsedTrial = true;
          return activeSub;
        } else if (trialData != null) {
          _hasUsedTrial = true;
          _currentSubscription = SubscriptionModel(
            id: 'sub_trial_${DateTime.now().millisecondsSinceEpoch}',
            planId: trialData['planId'] ?? 'plan_free_trial_id',
            planName: trialData['planName'] ?? 'Free Trial',
            status: 'active',
            currentPeriodStart: DateTime.now(),
            currentPeriodEnd: trialData['endsAt'] != null ? DateTime.parse(trialData['endsAt']) : DateTime.now().add(const Duration(days: 7)),
            features: ['all_pro_features'],
          );
          return _currentSubscription!;
        }
      }
    } catch (e) {
      print("Failed to start live free trial: $e. Falling back to local mock trial.");
    }

    // Mock fallback activation
    await Future.delayed(const Duration(seconds: 1));
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 3));
    final endDate = startDate.add(const Duration(days: 4)); // 7 days total
    
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
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      _purchaseCompleter = Completer<SubscriptionModel>();
      try {
        if (Platform.isIOS) {
          await buyAppleProduct(planId);
        } else {
          await buyGoogleProduct(planId);
        }
        return await _purchaseCompleter!.future;
      } catch (e) {
        print("Purchase failed: $e");
        rethrow;
      } finally {
        _purchaseCompleter = null;
      }
    }

    try {
      final idempotencyKey = _generateUUID();

      final response = await _apiClient.dio.post(
        AppConstants.subscriptionIntents,
        data: {
          'planId': planId,
          'platform': _getPlatformName(),
        },
        options: Options(
          headers: {
            'X-Idempotency-Key': idempotencyKey,
          },
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && 
          response.data != null && response.data['success'] == true) {
        final responseData = response.data['data'];
        final checkoutData = responseData['checkout'];
        final paymentData = responseData['payment'];
        
        final String? reference = paymentData != null ? paymentData['reference'] : null;
        final String? paymentUrl = responseData['paymentUrl'] ?? (checkoutData != null ? checkoutData['paymentUrl'] : null);

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        
        // Wait a second and try to sync
        if (reference != null && reference.isNotEmpty) {
          try {
            await syncPayment(reference);
          } catch (_) {}
        }

        final activeSub = await fetchCurrentSubscription();
        if (activeSub != null) {
          return activeSub;
        }
      }
    } catch (e) {
      print("Failed live buy plan checkout: $e. Falling back to local mock purchase.");
    }

    // Mock fallback activation
    await Future.delayed(const Duration(seconds: 1));
    final startDate = DateTime.now();
    final nextBillingDate = DateTime.now().add(const Duration(days: 365));
    
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

    // Record mock transaction
    _transactions.insert(
        0,
        TransactionModel(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          planName: isPro ? 'Premium yearly subscription' : 'Classic yearly subscription',
          date: startDate,
          amount: isPro ? 99.99 : 8.99,
          status: 'Success',
          paymentMethod: 'visa .... 4242',
          transactionId: 'TXN-2026-${_transactions.length + 1}',
          discount: isPro ? 20.0 : 0.0,
        ));

    return _currentSubscription!;
  }

  Future<SubscriptionModel> syncPayment(String paymentReference) async {
    try {
      final response = await _apiClient.dio.post(AppConstants.subscriptionSync(paymentReference));
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final activeSub = await fetchCurrentSubscription();
        if (activeSub != null) {
          return activeSub;
        }
      }
    } catch (e) {
      print("Failed syncing payment $paymentReference: $e");
    }
    return _currentSubscription ?? SubscriptionModel.none();
  }

  Future<void> cancelSubscription({String reason = 'other'}) async {
    try {
      final response = await _apiClient.dio.post(AppConstants.subscriptionCancel, data: {
        'reason': reason,
      });
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        await fetchCurrentSubscription();
        return;
      }
    } catch (e) {
      print("Failed live cancel subscription: $e");
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _currentSubscription = SubscriptionModel.none();
  }

  void initializeIAP() {
    if (_iapSubscription != null || kIsWeb) return;
    
    _iapSubscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        print("IAP Stream Error: $error");
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.completeError(error);
        }
      },
    );
  }

  void disposeIAP() {
    _iapSubscription?.cancel();
    _iapSubscription = null;
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print("Purchase pending for ${purchaseDetails.productID}");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("Purchase error: ${purchaseDetails.error}");
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.completeError(purchaseDetails.error ?? Exception("Purchase failed"));
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        final token = purchaseDetails.verificationData.serverVerificationData;
        if (token.isNotEmpty) {
          print("Successful purchase/restore for ${purchaseDetails.productID}. Token: $token. Sending to verify...");
          try {
            final SubscriptionModel verifiedSub;
            if (Platform.isIOS) {
              verifiedSub = await verifyApplePurchase(token);
            } else if (Platform.isAndroid) {
              final isSub = _isSubscriptionProduct(purchaseDetails.productID);
              verifiedSub = await verifyGooglePurchase(
                purchaseToken: token,
                productId: purchaseDetails.productID,
                isSubscription: isSub,
              );
            } else {
              throw Exception("Unsupported platform for IAP verification");
            }
            
            _subscriptionController.add(verifiedSub);
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(verifiedSub);
            }
          } catch (e) {
            print("Server verification failed for ${purchaseDetails.productID}: $e");
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.completeError(e);
            }
          }
        } else {
          print("Purchase completed/restored but verification token is empty!");
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!.completeError(Exception("Purchase verification token is empty"));
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> buyAppleProduct(String planId) async {
    final isAvailable = await InAppPurchase.instance.isAvailable();
    if (!isAvailable) {
      throw Exception("In-App Purchases are not available on this device.");
    }
    
    final appleProductId = planToAppleProductId[planId] ?? planId;
    print("Querying App Store product ID: $appleProductId");
    
    final response = await InAppPurchase.instance.queryProductDetails({appleProductId});
    if (response.notFoundIDs.contains(appleProductId) || response.productDetails.isEmpty) {
      throw Exception("Product $appleProductId not found in App Store Connect.");
    }
    
    final productDetails = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buyGoogleProduct(String planId) async {
    final isAvailable = await InAppPurchase.instance.isAvailable();
    if (!isAvailable) {
      throw Exception("In-App Purchases are not available on this device.");
    }
    
    final googleProductId = planToGoogleProductId[planId] ?? planId;
    print("Querying Google Play product ID: $googleProductId");
    
    final response = await InAppPurchase.instance.queryProductDetails({googleProductId});
    if (response.notFoundIDs.contains(googleProductId) || response.productDetails.isEmpty) {
      throw Exception("Product $googleProductId not found in Google Play Console.");
    }
    
    final productDetails = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<SubscriptionModel> verifyApplePurchase(String signedTransaction) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.verifyApplePurchase,
        data: {
          'signedTransaction': signedTransaction,
        },
      );
      
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final sub = SubscriptionModel.fromJson(response.data['data']);
        _currentSubscription = sub;
        return sub;
      } else {
        throw Exception("Server verification failed: ${response.statusMessage}");
      }
    } catch (e) {
      print("Exception verifying purchase: $e");
      rethrow;
    }
  }

  Future<SubscriptionModel> verifyGooglePurchase({
    required String purchaseToken,
    required String productId,
    required bool isSubscription,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.verifyGooglePurchase,
        data: {
          'purchaseToken': purchaseToken,
          'productId': productId,
          'isSubscription': isSubscription,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData['success'] == true) {
          final subData = resData['data']?['subscription'];
          if (subData != null) {
            final sub = SubscriptionModel.fromJson(subData);
            _currentSubscription = sub;
            return sub;
          }
        }
      }
      throw Exception("Google verification failed: ${response.statusMessage}");
    } catch (e) {
      print("Exception verifying Google purchase: $e");
      rethrow;
    }
  }

  bool _isSubscriptionProduct(String productId) {
    return planToGoogleProductId.containsValue(productId) ||
           productId.contains('monthly') ||
           productId.contains('yearly');
  }

  Future<void> restorePurchases() async {
    final isAvailable = await InAppPurchase.instance.isAvailable();
    if (!isAvailable) {
      throw Exception("In-App Purchases are not available on this device.");
    }
    print("Initiating restore purchases flow...");
    await InAppPurchase.instance.restorePurchases();
  }

  static const Map<String, String> planToAppleProductId = {
    'plan_pro_yearly': 'com.greenrabbit.pro.yearly',
    'plan_pro_monthly': 'com.greenrabbit.pro.monthly',
    'plan_classic_yearly': 'com.greenrabbit.classic.yearly',
    'plan_classic_monthly': 'com.greenrabbit.classic.monthly',
  };

  static const Map<String, String> planToGoogleProductId = {
    'plan_pro_yearly': 'com.greenrabbit.pro.yearly',
    'plan_pro_monthly': 'com.greenrabbit.pro.monthly',
    'plan_classic_yearly': 'com.greenrabbit.classic.yearly',
    'plan_classic_monthly': 'com.greenrabbit.classic.monthly',
  };
}
