import 'package:flutter/material.dart';

class AppColors {
  // --- خلفيات الشاشات (Backgrounds) ---
  static const Color scaffoldBg = Color(0xFF0E1117);   // الخلفية الأساسية
  static const Color cardBg = Color(0xFF1C2128);
  static const Color border = Color(0xFF4072FF);     // خلفية الكروت (AI Trading Assistant)
  static const Color navBarBg = Color(0xFF0F131A);     // خلفية شريط التنقل السفلي
  static const Color searchBarBg = Color(0xFF0E1117);  // خلفية شريط البحث (الجديد)

  // --- ألوان الهوية والأكشن (Brand & Actions) ---
  static const Color primaryPurple = Color(0xFF8B5CF6); 
  static const Color secondaryBlue = Color(0xFF4285F4);

  // --- ألوان الحالة (Status Colors - من الصورة الجديدة) ---
  static const Color profitGreen = Color(0xFF16A34A);  // للربح +17.03%
  static const Color lossRed = Color(0xFFFD3D3D);    // للخسارة -17.03%

  // --- النصوص والرماديات (Typography & Greys) ---
  static const Color textWhite = Color(0xFFFFFFFF);    // نصوص العناوين
  static const Color textOffWhite = Color(0xFFF8F8F8); // نصوص فرعية فاتحة
  static const Color textGrey = Color(0xFF9CA3AF);     // نصوص مساعدة (Secondary)
  static const Color dividerGrey = Color(0xFFC5C5C5);  // للخطوط الفاصلة
  static const Color borderGrey = Color(0xFFE5E7EB);   // للحدود الرفيعة

  // --- التدرجات (Gradients) ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF1E1D3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}