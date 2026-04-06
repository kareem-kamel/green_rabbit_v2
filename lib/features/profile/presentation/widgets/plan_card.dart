import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'gradient_button.dart';

class PlanCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final List<String> features;
  final String buttonText;
  final VoidCallback onButtonTap;
  final bool isPro;
  final bool isOutlinedButton;

  const PlanCard({
    super.key,
    required this.icon,
    required this.title,
    required this.features,
    required this.buttonText,
    required this.onButtonTap,
    this.isPro = false,
    this.isOutlinedButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPro ? null : Theme.of(context).cardColor,
        gradient: isPro ? AppColors.proGradient : null,
        borderRadius: BorderRadius.circular(20),
        border: isPro 
            ? Border.all(color: AppColors.premiumGold.withOpacity(0.3), width: 1.5) 
            : Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPro 
                    ? Colors.white.withOpacity(0.1) 
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isPro ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_box_outlined, color: AppColors.premiumGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: isPro ? Colors.white.withOpacity(0.85) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.85) : Colors.black87),
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          GradientButton(
            text: buttonText,
            onTap: onButtonTap,
            isOutlined: isOutlinedButton,
          ),
        ],
      ),
    );
  }
}
