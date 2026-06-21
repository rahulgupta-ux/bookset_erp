import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0D1117);
  static const Color card = Color(0xFF161B22);
  static const Color surface = Color(0xFF1C2128);

  static const Color primary = Color(0xFF10A37F);

  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);

  static const success = Colors.green;
  static const info = Colors.blue;
  static const warning = Colors.orange;
  static const danger = Colors.red;

  static const Color border = Color(0xFF21262D);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,

    cardColor: card,

    primaryColor: primary,

    colorScheme: const ColorScheme.dark(primary: primary, surface: card),

    appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0),
  );
}
