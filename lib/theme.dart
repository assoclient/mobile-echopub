import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF4D869C);
  static const Color lightBlue = Color(0xFF7AB2B2);
  static const Color white = Color(0xFFEEF7FF);
  static const Color softGreen = Color(0xFFCDE8E5);
  static const Color darkGrey = Color(0xFF444444);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color alertRed = Color(0xFFFF5B5B);
  static const Color success = Color(0xFF43A047);
}

final ThemeData appTheme = ThemeData(
  fontFamily: 'Inter',
  scaffoldBackgroundColor: AppColors.white,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    secondary: AppColors.lightBlue,
    onSecondary: AppColors.darkGrey,
    error: AppColors.alertRed,
    onError: Colors.white,
    background: AppColors.white,
    onBackground: AppColors.darkGrey,
    surface: Colors.white,
    onSurface: AppColors.darkGrey,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.darkGrey, letterSpacing: 0.5),
    headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.darkGrey),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal, fontSize: 16, color: AppColors.darkGrey),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal, fontSize: 14, color: AppColors.darkGrey),
    labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.primaryBlue, letterSpacing: 1.2),
    labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primaryBlue, letterSpacing: 1.2),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.alertRed),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, letterSpacing: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      side: const BorderSide(color: AppColors.primaryBlue, width: 1),
      textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, letterSpacing: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, letterSpacing: 1.2),
    ),
  ),
);
