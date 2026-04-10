import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/gradient_button.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionSuccessDialog extends StatelessWidget {
  final SubscriptionModel? subscription;
  const SubscriptionSuccessDialog({super.key, this.subscription});

  static Future<void> show(BuildContext context, {SubscriptionModel? subscription}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionSuccessDialog(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClassic = subscription?.planId.contains('classic') ?? false;
    
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon in Gradient Circle
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isClassic 
                  ? const Icon(Icons.shield_outlined, color: Colors.black, size: 50)
                  : Image.asset(
                      'assets/crown_black.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.black, size: 50),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              isClassic ? 'Welcome to Classic!' : 'Welcome to the Inner Circle!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              isClassic 
                  ? 'Enjoy an ad-free experience with limited AI features'
                  : 'Your Pro features are now unlocked. Start exploring your AI insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Button
            GradientButton(
              text: 'Start Exploring',
              textColor: Colors.white,
              onTap: () {
                Navigator.pop(context); // Dismiss dialog
                Navigator.pop(context); // Pop CheckoutScreen
                Navigator.pop(context); // Pop UpgradePlansScreen
              },
              isOutlined: false,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
