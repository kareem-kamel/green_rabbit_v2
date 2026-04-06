import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Spacing & Radius Tokens (شغل شربيني اللي بيظبط المسافات)
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 14.0;
  static const double paddingM = 16.0;

  // Dark Theme
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      // بنستخدم ألوان الـ main اللي أنت عرفتها
      scaffoldBackground: AppColors.scaffoldBg,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: defaultRadius,
        inputDecoratorRadius: inputRadius,
        cardRadius: cardRadius,
        bottomSheetRadius: 24.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      // 1. الخط الأساسي من الـ main
      fontFamily: 'Urbanist', 
    ).copyWith(
      // 2. دمج الـ TextTheme اللي أنت صممته في الـ main
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textGrey,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textGrey,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
        ),
      ),
      // 3. الحفاظ على الـ Bottom Nav بتاع شربيني عشان الـ UI ميبوظش
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Urbanist'),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: defaultRadius,
        inputDecoratorRadius: inputRadius,
        cardRadius: cardRadius,
        bottomSheetRadius: 24.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: 'Urbanist',
    ).copyWith(
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        bodySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black54),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
      ),
    );
  }
}