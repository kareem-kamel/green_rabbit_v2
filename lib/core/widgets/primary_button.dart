import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final double height;
  final double width;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 56.0,
    this.width = double.infinity,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // مهم
          shadowColor: Colors.transparent,     // نشيل الشادو
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.zero, // عشان الContainer يملى كله
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading
                ? LinearGradient( // شكل أخف وقت اللودينج
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.6),
                      AppColors.primaryPurple.withOpacity(0.4),
                    ],
                  )
                : AppColors.primaryGradient1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}