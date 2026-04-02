import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class DotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double activeDotWidth;
  final double spacing;

  const DotsIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.activeColor = AppColors.primaryPurple,
    this.inactiveColor = Colors.white38,
    this.dotSize = 8,
    this.activeDotWidth = 24,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? activeDotWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(dotSize / 2),
          ),
        );
      }),
    );
  }
}