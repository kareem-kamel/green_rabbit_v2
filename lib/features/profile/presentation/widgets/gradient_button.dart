import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isOutlined;
  final Widget? icon;
  final Gradient? gradient;
  final Color? textColor;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isOutlined = false,
    this.icon,
    this.gradient,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.goldGradient;
    
    if (isOutlined) {
      return InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5), // Border thickness
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: _buildContent(textColor ?? Colors.white),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (effectiveGradient.colors.first).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _buildContent(textColor ?? Colors.black),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
