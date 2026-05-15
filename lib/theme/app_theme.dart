import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFC1D591);      // Vetiver 원색
  static const Color primaryLight = Color(0xFFEEF4DC); // Vetiver 연한 버전
  static const Color secondary = Color(0xFFF1B8D9);
  static const Color accent = Color(0xFFFFBF47);
  static const Color background = Color(0xFFFFFFFF);   // 흰색
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF5F9EE);       // Vetiver 연한 버전
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFB0B0B0);
  static const Color divider = Color(0xFFE8EFD8);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);

  // 원색 (아이콘/텍스트/버튼용)
  static const Color buyColor = Color(0xFFD4789A);      // Strawberry Shake 진하게
  static const Color exchangeColor = Color(0xFF5A8DC4); // Hydrangea 진하게
  static const Color reviewColor = Color(0xFF6B6BBF);   // Grape Soda 진하게
  static const Color gatherColor = Color(0xFFEFAB82);   // Peach Cream 진하게

  // 연한 버전 (배경용)
  static const Color buyColorLight = Color(0xFFFDE8F2);      // Strawberry Shake 연하게
  static const Color exchangeColorLight = Color(0xFFF0F5FF); // Hydrangea 연하게
  static const Color reviewColorLight = Color(0xFFEEEEFF);   // Grape Soda 연하게
  static const Color gatherColorLight = Color(0xFFFDF5EF);   // Peach Cream 연하게
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'sans-serif',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}