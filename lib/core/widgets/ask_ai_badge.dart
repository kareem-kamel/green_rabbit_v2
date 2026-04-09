import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AskAIBadge extends StatelessWidget {
  final EdgeInsets padding;
  final double iconSize;
  final String label;

  const AskAIBadge({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.iconSize = 20,
    this.label = 'Ask AI',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: const Color(0x7F161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Image.asset(
              'assets/icons/aitradingassistant.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 12,
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              height: 1.30,
            ),
          ),
        ],
      ),
    );
  }
}
