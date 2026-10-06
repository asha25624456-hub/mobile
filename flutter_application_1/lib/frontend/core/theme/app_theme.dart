import 'package:flutter/material.dart';

/// สีหลักของแอป (อ้างอิงจากดีไซน์ "SmartRequisition"):
/// แถบบนสีน้ำเงินเข้ม + พื้นหลังครีม + การ์ดขาว + ป้ายสถานะสีตามความหมาย
class AppColors {
  AppColors._();

  static const paper = Color(0xFFF7F4EC);
  static const ink = Color(0xFF14213D);
  static const navy = ink;
  static const navyLight = Color(0xFF223259);
  static const tag = Color(0xFFFFC300);
  static const muted = Color(0xFF5B6577);
  static const line = Color(0xFFE1DDD0);
  static const errorBg = Color(0xFFFDECEA);
  static const errorText = Color(0xFFB3261E);
  static const okBg = Color(0xFFE1F5E9);
  static const okText = Color(0xFF1E8449);
  static const infoBg = Color(0xFFFFF3CD);
  static const infoText = Color(0xFF7A5B00);
  static const warnBg = Color(0xFFFEF0DC);
  static const warnText = Color(0xFFB5680A);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.tag,
    error: AppColors.errorText,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.line),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.errorText),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.errorText, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: AppColors.ink),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        selectedBackgroundColor: AppColors.ink,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: buttonShape,
      ),
    ),
  );
}
