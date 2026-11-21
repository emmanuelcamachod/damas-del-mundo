import 'package:flutter/material.dart';

/// Sistema de diseño unificado Neo-Tactile Studio (Opción F) para Damas del Mundo.
/// Proporciona la paleta cromática, superficies y componentes táctiles de estudio.
class NeoTactileTheme {
  // Paleta Cromática Base
  static const Color background = Color(0xFF181C24);
  static const Color surface = Color(0xFF20252E);
  static const Color surfaceBorder = Color(0xFF2D3440);
  static const Color surfaceElevated = Color(0xFF282F3A);

  // Acentos de Interacción
  static const Color terracotta = Color(0xFFB86B4B);
  static const Color terracottaDark = Color(0xFFA35C3E);
  static const Color sand = Color(0xFFE6C89C);
  static const Color cream = Color(0xFFECDCC9);

  // Tablero y Piezas Neo-Tactile
  static const Color boardFrame = Color(0xFF221A15);
  static const Color boardBorder = Color(0xFF3D2A1D);
  static const Color boardDarkCell = Color(0xFF1D222A);
  static const Color boardLightCell = Color(0xFF2E3543);
  static const Color pieceWhite = Color(0xFFECDCC9);
  static const Color pieceWhiteBorder = Color(0xFFDFCAA7);
  static const Color pieceBlack = Color(0xFFB86B4B);
  static const Color pieceBlackBorder = Color(0xFF8F4D32);

  // Textos y Contraste (Cumple WCAG AA)
  static const Color textHigh = Color(0xFFF8FAFC);
  static const Color textMedium = Color(0xFFECDCC9);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: terracotta,
        onPrimary: Colors.white,
        secondary: sand,
        onSecondary: Color(0xFF181C24),
        surface: surface,
        onSurface: textHigh,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textHigh,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textHigh,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
