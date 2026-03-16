import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

class AdminTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.primary,
        primary: AdminColors.primary,
        secondary: AdminColors.success,
        surface: AdminColors.white,
        error: AdminColors.danger,
      ),
      scaffoldBackgroundColor: AdminColors.background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.sidebar,
        foregroundColor: AdminColors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AdminColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
