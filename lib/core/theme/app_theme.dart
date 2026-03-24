import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Urbanist', // ده هيخلي التطبيق كله يقلب Urbanist أوتوماتيك
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBg,   // الخلفية الأساسية
    
    textTheme: const TextTheme(
      // تطبيق المواصفات اللي في الصورة بالظبط
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500, // Medium
        color: AppColors.textGrey,
      ),
      // تقدر تضيف أحجام تانية للعناوين بناءً على باقي التصميم
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
      fontFamily: 'Urbanist',
      fontSize: 16,
      fontWeight: FontWeight.w400, // Regular
      color: Colors.white,
    ),

    // 2. للنصوص الصغيرة أو الـ Hint (Regular 14)
    bodyMedium: TextStyle(
      fontFamily: 'Urbanist',
      fontSize: 14,
      fontWeight: FontWeight.w400, // Regular
      color: AppColors.textGrey, // اللون الرمادي من فيجما
    ),

    // 3. للعناوين الفرعية أو الزراير (SemiBold 16)
    titleMedium: TextStyle(
      fontFamily: 'Urbanist',
      fontSize: 16,
      fontWeight: FontWeight.w600, // SemiBold
      color: AppColors.primaryPurple, // البنفسجي للـ Sign Up
    ),
    ),
  );
}