import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFFD84315); // Deep Orange
  static const Color secondaryColor = Color(0xFF1976D2); // Blue
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFF57C00); // Orange

  // Colores neutrales
  static const Color dark = Color(0xFF212121);
  static const Color darkGrey = Color(0xFF424242);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color veryLightGrey = Color(0xFFEEEEEE);
  static const Color white = Colors.white;

  // Espaciado
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  // Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  // Sombras
  static final shadow1 = BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 2,
      offset: const Offset(0, 1));
  static final shadow2 = BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 2));
  static final shadow3 = BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 12,
      offset: const Offset(0, 4));

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: white),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: veryLightGrey,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: md, vertical: md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: veryLightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: grey),
        hintStyle: const TextStyle(color: lightGrey),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: dark),
        displayMedium:
            TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: dark),
        displaySmall:
            TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: dark),
        headlineMedium:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: dark),
        headlineSmall:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: dark),
        titleLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: dark),
        titleMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark),
        bodyLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: dark),
        bodyMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: grey),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: lightGrey),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: white,
        scrimColor: Colors.black45,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(radiusLg)),
        ),
      ),
    );
  }
}
