import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscriptions/data/models/subscription_model.dart';
import '../../../subscriptions/data/models/transaction_model.dart';
import '../../../subscriptions/presentation/cubit/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscription_state.dart';
import '../../../subscriptions/presentation/widgets/trial_success_dialog.dart';
import 'upgrade_plans_screen.dart';
import '../widgets/plan_card.dart';
import '../widgets/gradient_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _activeTab = 0; // 0 for plans, 1 for History
  bool _forceShowPlans = false; // To show plans even if active sub exists

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        if (state is TrialStartingSuccess) {
          TrialSuccessDialog.show(context);
        }
      },
      builder: (context, state) {
        SubscriptionModel? currentSub;
        List<TransactionModel> history = [];
        if (state is SubscriptionLoaded) {
          currentSub = state.currentSubscription;
          history = state.history;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Payment & Billing',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, size: 24),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              _buildTabSelector(currentSub != null),
              const SizedBox(height: 30),
              Expanded(
                child: _activeTab == 0
                    ? _buildPlansList(context, state, currentSub)
                    : _buildHistoryList(history),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabSelector(bool hasActiveSub) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.tabBackground : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(hasActiveSub ? 'My Plan' : 'plans', 0),
          ),
          Expanded(
            child: _buildTabItem('History', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
          if (index == 0) {
            _forceShowPlans = false;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.goldGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive 
                ? Colors.black 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54),
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, SubscriptionState state, SubscriptionModel? currentSub) {
    if (state is SubscriptionLoading && currentSub == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.premiumGold));
    }

    if (currentSub != null && currentSub.isActive && !_forceShowPlans) {
      return _buildActivePlanView(currentSub);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        if (currentSub == null) ...[
          PlanCard(
            icon: const Icon(Icons.rocket_launch, color: AppColors.premiumGold, size: 24),
            title: 'Free Trial',
            features: const [
              'Limited AI access',
              'AI Chatbot (5 Free Credits / day)',
              'AI News Summaries',
              'Ads included',
            ],
            buttonText: 'Start Free Trial',
            onButtonTap: () {
              context.read<SubscriptionCubit>().startTrial();
            },
            isOutlinedButton: true,
          ),
          const SizedBox(height: 24),
        ],
        PlanCard(
          icon: const Icon(Icons.auto_awesome, color: AppColors.premiumGold, size: 24),
          title: 'Experience the full power of AI',
          features: const [
            'Priority customer support',
            'Real-time AI trading signals',
            'Custom alerts & notifications',
            'API access for automation',
            'Expert community access',
            'Unlimited watchlists',
            'Advanced charting tools',
            'Advanced portfolio tracking',
          ],
          buttonText: 'Upgrade To Pro',
          onButtonTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePlansScreen()));
          },
          isPro: true,
          isOutlinedButton: false,
        ),
        const SizedBox(height: 24),
        PlanCard(
          icon: const Icon(Icons.shield, color: AppColors.premiumGold, size: 24),
          title: 'Classic Plan',
          features: const [
            'Remove Ads lifetime',
            'Limited AI access for 7 Day',
            'AI News Summaries for 7 Day',
          ],
          buttonText: 'Upgrade To Classic',
          onButtonTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePlansScreen(isClassic: true)));
          },
          isOutlinedButton: true,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActivePlanView(SubscriptionModel sub) {
    if (sub.isTrial) {
      // Trial View
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.premiumGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Free Trail',
                          style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Active', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(sub.planId.contains('classic') ? 'Classic Free Trial' : '7-Day Free Trail', 
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('You now have access to selected features',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : Colors.black54, fontSize: 14)),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sub.progress,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.premiumGold),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${sub.daysUsed} / ${sub.totalDays} day used',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black45, fontSize: 13)),
                    Text('\$0.00', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Upgrade Plan',
                  onTap: () {
                    setState(() => _forceShowPlans = true);
                  },
                  isOutlined: false,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final isClassic = sub.planId.contains('classic');
    final badgeColor = isClassic ? const Color(0xFFFFD700) : AppColors.premiumGold;
    final badgeText = isClassic ? 'Classic Member' : 'Pro Member';

    // Full Member View (Pro or Classic)
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isClassic 
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12) 
                  : AppColors.premiumGold.withOpacity(0.5), 
              width: 1
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badgeText,
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Active', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isClassic ? 'Yearly Classic plan' : 'Yearly pro plan', 
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 6),
              Text(
                isClassic ? 'No ads. Access to selected AI tools' : 'All premium features included',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black54, fontSize: 14)
              ),
              const SizedBox(height: 32),
              
              // Billing Data Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBillingRow(context, 'Next billing date', 'Mar 28, 2026'),
                    const SizedBox(height: 12),
                    _buildBillingRow(context, 'Payment method', '************4242'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              GestureDetector(
                onTap: () => _showCancelBottomSheet(context, sub),
                child: const Text(
                  'Cancel Plan',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelBottomSheet(BuildContext context, SubscriptionModel sub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131519) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            
            // Warning Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.premiumGold, size: 40),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Cancel ${sub.isClassic ? 'Classic' : 'Pro'} Membership',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Text(
              'You will lose your ${sub.isClassic ? 'Classic' : 'Pro'} badge and AI-powered insights on ${sub.currentPeriodEnd != null ? "${sub.currentPeriodEnd!.month}/${sub.currentPeriodEnd!.day}/${sub.currentPeriodEnd!.year}" : "the end of your period"}. Are you sure you want to downgrade to the Free plan?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : Colors.black54, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            GradientButton(
              text: 'Keep My Benefits',
              textColor: Colors.white,
              onTap: () => Navigator.pop(context),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () {
                context.read<SubscriptionCubit>().cancelSubscription();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Cancel Subscription',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.4) : Colors.black45, fontSize: 14)),
        Text(value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87, fontSize: 14)),
      ],
    );
  }

  Widget _buildHistoryList(List<TransactionModel> history) {
    if (history.isEmpty) {
      return Center(
        child: Text('Billing history will appear here.', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return TransactionItem(transaction: history[index]);
      },
    );
  }
}

class TransactionItem extends StatefulWidget {
  final TransactionModel transaction;
  const TransactionItem({super.key, required this.transaction});

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.transaction.id.hashCode % 2 == 0 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: widget.transaction.id.hashCode % 2 == 0 ? Colors.blue : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.planName,
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getMonth(t.date.month)} ${t.date.day}, ${t.date.year}',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(context, 'Transaction date', '${_getMonth(t.date.month)} ${t.date.day}, ${t.date.year}'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(context, 'States', t.status, isStatus: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(context, 'Payment method', t.paymentMethod),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(context, 'Transaction ID', t.transactionId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),
                  
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 15)),
                        const SizedBox(height: 20),
                        _buildSummaryRow(context, 'Subscription fees', '\$${t.amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Discount', '20%', isGreen: true),
                        const SizedBox(height: 16),
                        Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16)),
                            Text(
                              '\$${t.amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.premiumGold, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Download Button
                  GradientButton(
                    text: 'Download PDF Transaction',
                    textColor: Colors.black,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading transaction PDF...')),
                      );
                    },
                    isOutlined: false,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'For any questions about this transaction,\nplease contact our support team',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.black38, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, {bool isStatus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            if (isStatus) ...[
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87, fontSize: 14), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? Colors.greenAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
