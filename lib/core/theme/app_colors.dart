import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF6A5AE0); // Electric Purple
  static const Color primaryDark = Color(0xFF3B28C2);
  static const Color secondary = Color(0xFF5E5CE6); // Indigo
  static const Color accent = Color(0xFFBB86FC); // Light Purple accent

  // Background & Surfaces
  static const Color background = Color(0xFF0F111A); // Deep Navy Black
  static const Color surface = Color(0xFF1B1E2B); // Darker Blue Card
  static const Color surfaceLight = Color(0xFF25293C);
  static const Color backgroundSubtle = Color(0xFF0E1117);
  static const Color searchBarBackground = Color(0xFF1C1F26);

  // Status Colors
  static const Color success = Color(0xFF34D399); // Emeral Green
  static const Color error = Color(0xFFF87171); // Soft Red
  static const Color warning = Color(0xFFFBBF24); // Amber

  // Specific UI Colors (from reference)
  static const Color cardBackground = Color(0xFF161922);
  static const Color tabUnselected = Color(0xFF1E222D);
  static const Color tabIndicatorBorder = Color(0xFF2D5CFF);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF4C3BC9);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // white70 approx
  static const Color textMuted = Color(0x3DFFFFFF); // white24 approx

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient bannerGradient = LinearGradient(
    colors: [
      primary.withOpacity(0.8),
      surface,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Divider / Border Colors
  static Color border = Colors.white.withOpacity(0.1);
  static Color borderSubtle = Colors.white.withOpacity(0.05);

  // Technical Signal Backgrounds
  static const Color technicalBullishRoot = Color(0xFF064E3B);
  static const Color technicalBearishRoot = Color(0xFF450A0A);

  // Premium / Badge Colors
  static const Color premiumGold = Color(0xFFFBBF24);
  static const Color unlockBlue = Color(0xFF2D5CFF);

  // Popup / Overlay Colors
  static const Color popupBackground = Color(0xFF0F111A);

  // Action / Share Gradients
  static const LinearGradient shareGradient = LinearGradient(
    colors: [primary, Color(0xFF4A3BC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
