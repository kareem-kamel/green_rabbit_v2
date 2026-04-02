import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AITradingAssistantCard extends StatelessWidget {
  final VoidCallback? onTap;
  const AITradingAssistantCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.asset(
                    'assets/icons/aitradingassistant.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Trading Assistant',
                        style: TextStyle(
                          color: AppColors.textOffWhite,
                          fontSize: 16,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Understand prices, indicators, and news with AI-powered explanations',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(isActive: true),
                const SizedBox(width: 6),
                _dot(),
                const SizedBox(width: 6),
                _dot(),
                const SizedBox(width: 6),
                _dot(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _dot({bool isActive = false}) {
  return Container(
    width: isActive ? 12 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: isActive ? AppColors.textOffWhite : AppColors.textGrey,
      borderRadius: BorderRadius.circular(144),
    ),
  );
}
