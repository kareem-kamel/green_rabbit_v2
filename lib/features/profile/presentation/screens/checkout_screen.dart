import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscriptions/presentation/cubit/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscription_state.dart';
import '../../../subscriptions/presentation/widgets/subscription_success_dialog.dart';

class CheckoutScreen extends StatelessWidget {
  final double amount;
  final bool isYearly;
  final String planId;

  const CheckoutScreen({
    super.key,
    required this.amount,
    required this.isYearly,
    this.planId = 'plan_pro_yearly',
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        if (state is PurchaseSuccess) {
          SubscriptionSuccessDialog.show(context, subscription: state.subscription);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Complete your purchase to unlock Pro features',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Summary Card
            _buildSummaryCard(context),
            const SizedBox(height: 32),

            // Quick Pay
            Text(
              'Quick pay',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuickPayButton(context, 'assets/apple_pay.png')),
                const SizedBox(width: 16),
                Expanded(child: _buildQuickPayButton(context, 'assets/google_pay.png')),
              ],
            ),
            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or pay with',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : Colors.black45, fontSize: 14),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              ],
            ),
            const SizedBox(height: 32),

            // Form
            _buildTextField(context, 'Card holer name', 'First abd second name'),
            const SizedBox(height: 24),
            _buildTextField(context, 'Card number', 'xxxx-xxxx-xxxx-xxxx'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildTextField(context, 'Exp. Date', 'mm/yy')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(context, 'CVV', 'xxx')),
              ],
            ),
            const SizedBox(height: 40),

            // Confirm Button
            _buildConfirmButton(context),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Your payment information is encrypted and secure',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.4) : Colors.black38, fontSize: 13),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(context, isYearly ? 'Pro yearly plan' : 'Pro monthly plan', '\$${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Discount', '20%', isGreen: true),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              'Total',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18),
            ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.premiumGold, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? Colors.greenAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            fontSize: 14,
            fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPayButton(BuildContext context, String assetPath) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      alignment: Alignment.center,
      child: assetPath.contains('apple') 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 28),
                Text('Pay', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.g_mobiledata,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  size: 40,
                ),
                const SizedBox(width: 8),
                Text('Pay', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextField(
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black26),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<SubscriptionCubit>().buyPlan(planId: planId);
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

