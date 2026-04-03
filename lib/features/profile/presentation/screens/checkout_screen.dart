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
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Complete your purchase to unlock Pro features',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Summary Card
            _buildSummaryCard(),
            const SizedBox(height: 32),

            // Quick Pay
            const Text(
              'Quick pay',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuickPayButton('assets/apple_pay.png')),
                const SizedBox(width: 16),
                Expanded(child: _buildQuickPayButton('assets/google_pay.png')),
              ],
            ),
            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or pay with',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              ],
            ),
            const SizedBox(height: 32),

            // Form
            _buildTextField('Card holer name', 'First abd second name'),
            const SizedBox(height: 24),
            _buildTextField('Card number', 'xxxx-xxxx-xxxx-xxxx'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildTextField('Exp. Date', 'mm/yy')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('CVV', 'xxx')),
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
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(isYearly ? 'Pro yearly plan' : 'Pro monthly plan', '\$${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Discount', '20%', isGreen: true),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Colors.white, fontSize: 18),
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

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? Colors.greenAccent : Colors.white,
            fontSize: 14,
            fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPayButton(String assetPath) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      alignment: Alignment.center,
      child: assetPath.contains('apple') 
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, color: Colors.white, size: 28),
                Text('Pay', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.g_mobiledata,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 8),
                const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  Widget _buildTextField(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
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

