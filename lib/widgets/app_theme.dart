// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds all the colors for a specific theme.
/// This class is NOT static. We will create instances of it.
@immutable // It's good practice to make data classes like this immutable.
class AppThemeData {
  final Color primary;       // Dark background for elements like buttons
  final Color secondary;     // Main interactive/highlight color (turquoise)
  final Color background;    // Overall page background color
  final Color accent;        // A secondary accent color for special cases (e.g., alerts)
  final Color inactive;      // A lighter, less prominent version of the secondary color

  const AppThemeData({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.accent,
    required this.inactive,
  });
}

/// The default theme for the application.
/// We are creating an INSTANCE of our theme data class.
final AppThemeData defaultTheme = AppThemeData(
  primary: const Color(0xFF222831),
  secondary: const Color(0xFF30D1DA),
  background: const Color(0xFF3D485A),
  accent: const Color(0xFFFF6F61),
  inactive: const Color(0xFFB2F8FB),
);

// To add a new theme later, you would just create another instance:
/*
final AppThemeData darkTheme = AppThemeData(
  primary: const Color(0xFF121212),
  secondary: const Color(0xFFBB86FC),
  background: const Color(0xFF1F1F1F),
  accent: const Color(0xFF03DAC6),
  inactive: const Color(0xFF777777),
);
*/

/// A Riverpod provider that exposes the currently active theme.
/// For now, it always returns the defaultTheme.
/// Later, you can add logic here to return a different theme based on user settings.
final themeProvider = Provider<AppThemeData>((ref) {
  // In the future, you could read from SharedPreferences or another state provider here
  // to decide whether to return defaultTheme, darkTheme, blueTheme, etc.
  return defaultTheme;
});