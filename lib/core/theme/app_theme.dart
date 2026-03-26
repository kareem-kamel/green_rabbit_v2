import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Spacing & Radius Tokens
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 14.0;
  static const double buttonRadius = 12.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;

  // Dark Theme
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: Color(0xFF4838D1),
        secondary: AppColors.secondary,
        secondaryContainer: Color(0xFF3B3B98),
        tertiary: AppColors.accent,
        tertiaryContainer: Color(0xFF1F1F1F),
        appBarColor: AppColors.background,
        error: AppColors.error,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: defaultRadius,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsSchemeColor: SchemeColor.primary,
        segmentedButtonSchemeColor: SchemeColor.primary,
        switchSchemeColor: SchemeColor.primary,
        checkboxSchemeColor: SchemeColor.primary,
        radioSchemeColor: SchemeColor.primary,

        inputDecoratorRadius: inputRadius,
        inputDecoratorUnfocusedHasBorder: false,
        fabUseShape: true,
        fabRadius: 16.0,
        chipRadius: 10.0,
        cardRadius: cardRadius,
        popupMenuRadius: 12.0,
        dialogRadius: 20.0,
        timePickerElementRadius: 12.0,
        snackBarRadius: 10.0,
        bottomSheetRadius: 24.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackground: AppColors.background,
    ).copyWith(
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  // Potential Light Theme
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      scheme: FlexScheme.deepBlue,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: defaultRadius,
        inputDecoratorRadius: inputRadius,
        fabRadius: 16.0,
        cardRadius: cardRadius,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}
