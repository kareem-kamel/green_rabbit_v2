import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/gradient_button.dart';

import 'checkout_screen.dart';

class UpgradePlansScreen extends StatefulWidget {
  final bool isClassic;
  const UpgradePlansScreen({super.key, this.isClassic = false});

  @override
  State<UpgradePlansScreen> createState() => _UpgradePlansScreenState();
}

class _UpgradePlansScreenState extends State<UpgradePlansScreen> {
  bool isYearly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = constraints.maxWidth > 900 
              ? (constraints.maxWidth - 800) / 2 
              : 24.0;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan Icon Header
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.isClassic ? Icons.shield : Icons.auto_awesome, 
                          color: AppColors.premiumGold, 
                          size: 30
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Choose Your Plan',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: January 2026',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // Toggle Monthly/Yearly
                      _buildBillingToggle(),
                      const SizedBox(height: 40),

                      // Main Plan Card
                      _buildPlanCard(context),
                      
                      const SizedBox(height: 40),
                      
                      // Footer Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFooterItem(context, 'Cancel anytime'),
                          _buildFooterItem(context, 'Secure payment'),
                          _buildFooterItem(context, 'Instant access'),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Center(
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.tabBackground : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isYearly = false),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isYearly ? Colors.white.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Monthly',
                        style: TextStyle(
                          color: !isYearly 
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) 
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45),
                          fontWeight: !isYearly ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isYearly = true),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isYearly ? Colors.white.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Yearly',
                        style: TextStyle(
                          color: isYearly 
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) 
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45),
                          fontWeight: isYearly ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Save Badge
            Positioned(
              top: -4,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.premiumGold.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Save 20%',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context) {
    final title = widget.isClassic ? 'Classic' : 'Pro Plan';
    final yearlyPrice = widget.isClassic ? 8.99 : 99.99;
    final monthlyPrice = widget.isClassic ? 0.99 : 14.99;
    final price = isYearly ? yearlyPrice : monthlyPrice;
    
    final features = widget.isClassic 
      ? ['Remove Ads', 'Limited AI access free for 7 day', 'AI Chatbot (5 Free Credits)', 'AI News Summaries for 7 day']
      : ['Priority customer support', 'Real-time AI trading signals', 'Custom alerts & notifications', 'API access for automation', 'Expert community access', 'Unlimited watchlists', 'Advanced charting tools', 'Advanced portfolio tracking'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: !widget.isClassic ? null : Theme.of(context).cardColor,
        gradient: !widget.isClassic ? AppColors.proGradient : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.premiumGold, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.isClassic) ...[
                    const Icon(Icons.shield_outlined, color: AppColors.premiumGold, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: !widget.isClassic ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!widget.isClassic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.premiumGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$$price',
                style: const TextStyle(color: AppColors.premiumGold, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                isYearly ? '/ Yearly' : '/ monthly',
                style: TextStyle(
                  color: !widget.isClassic ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
            Text(
              widget.isClassic 
                ? (isYearly ? 'Only \$0.73/month · Save \$2.89/year' : 'Enjoy ad-free experience monthly')
                : (isYearly ? 'Only \$8.33/month · Save \$55.89/year' : 'Access all premium features monthly'),
              style: TextStyle(
                color: !widget.isClassic ? Colors.white54 : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 24),
          
          ...features.map((f) => _buildFeature(f)),
          
          const SizedBox(height: 32),
          
          GradientButton(
            text: widget.isClassic ? 'Upgrade To Classic' : 'Upgrade To Pro',
            textColor: widget.isClassic ? Colors.white : Colors.black,
            isOutlined: widget.isClassic,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    amount: price,
                    isYearly: isYearly,
                    planId: widget.isClassic 
                      ? (isYearly ? 'plan_classic_yearly' : 'plan_classic_monthly')
                      : (isYearly ? 'plan_pro_yearly' : 'plan_pro_monthly'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_box_outlined, color: AppColors.premiumGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: !widget.isClassic ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 13),
    );
  }
}
