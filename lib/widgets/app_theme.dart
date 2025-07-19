// lib/widgets/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppThemeData {
  final Color primary;       // Darkest color for UI chrome (bars, etc.)
  final Color secondary;     // Main interactive/highlight color (turquoise)
  final Color background;    // Lighter gray for content tiles
  final Color accent;        // A secondary accent color for special cases
  final Color inactive;      // A lighter, less prominent version of the secondary color

  // NEW: A color for the main page background, between primary and background.
  final Color pageBackground;

  const AppThemeData({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.accent,
    required this.inactive,
    required this.pageBackground, // NEW: Add to constructor
  });
}

final AppThemeData defaultTheme = AppThemeData(
  primary: const Color(0xFF222831),        // Darkest
  secondary: const Color(0xFF30D1DA),
  background: const Color(0xFF3D485A),      // Lightest gray
  accent: const Color(0xFFFF6F61),
  inactive: const Color(0xFFB2F8FB),
  // NEW: An intermediate gray. You can easily tweak this hex value.
  pageBackground: const Color(0xFF313846), // In-between color
);

final themeProvider = Provider<AppThemeData>((ref) {
  return defaultTheme;
});