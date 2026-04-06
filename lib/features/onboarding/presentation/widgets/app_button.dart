import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
 
enum AppButtonStyle { primary, outline }
 
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final AppButtonStyle style;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
 
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.width = double.infinity,
    this.height = 56,
    this.borderRadius = 16,
    this.textStyle,
  });
 
  @override
  Widget build(BuildContext context) {
    final isPrimary = style == AppButtonStyle.primary;
 
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.primaryPurple : Colors.transparent,
          foregroundColor: Colors.white,
          elevation: isPrimary ? 4 : 0,
          shadowColor:
              isPrimary ? AppColors.primaryPurple.withOpacity(0.4) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Colors.white54, width: 1.5),
          ),
        ),
        child: Text(
          label,
          style: textStyle ??
              const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
        ),
      ),
    );
  }
}
 