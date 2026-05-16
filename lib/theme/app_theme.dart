import 'package:flutter/material.dart';

class AppTheme {
  // === PALETA CLARA (Angular) ===
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0088CC); 
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextMuted = Color(0xFF6B6B6B);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // === PALETA OSCURA (Angular) ===
  static const Color darkBg = Color(0xFF141414);       
  static const Color darkCard = Color(0xFF1E1E1E);     
  static const Color darkPrimary = Color(0xFFFF7A00);  
  static const Color darkText = Color(0xFFF7F7F7);
  static const Color darkTextMuted = Color(0xFF9F9F9F);
  static const Color darkBorder = Color(0xFF2D2D2D);

  // Variables estáticas de compatibilidad
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color veryLightGrey = Color(0xFFF5F5F5);
  static const Color primaryColor = darkPrimary;
  static const Color secondaryColor = lightTextMuted;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.redAccent;
  static const Color warningColor = Colors.orange;

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double radiusMd = 8.0;

  static final shadow1 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  // ==========================================
  // CONFIGURACIÓN TEMA CLARO
  // ==========================================
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      dividerColor: lightBorder,
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder), 
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        surface: lightCard,
        onSurface: lightText,
        error: Colors.redAccent,
      ),
      
      // LO NUEVO: Estilo unificado para TODOS los Inputs en modo Claro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        hintStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
        prefixIconColor: lightTextMuted,
        suffixIconColor: lightTextMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
      ),

      textTheme: const TextTheme(
        titleMedium: TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: lightText),
        bodySmall: TextStyle(color: lightTextMuted),
      ),
    );
  }

  // ==========================================
  // CONFIGURACIÓN TEMA OSCURO
  // ==========================================
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      dividerColor: darkBorder,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder), 
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        surface: darkCard,
        onSurface: darkText,
        error: Colors.redAccent,
      ),

      // LO NUEVO: Estilo unificado para TODOS los Inputs en modo Oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard, // Mismo color gris obscuro de las tarjetas de Angular
        hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
        prefixIconColor: darkTextMuted,
        suffixIconColor: darkTextMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
      ),

      textTheme: const TextTheme(
        titleMedium: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: darkTextMuted),
      ),
    );
  }
}