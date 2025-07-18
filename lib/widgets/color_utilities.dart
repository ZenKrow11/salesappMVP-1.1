// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

/// Determines a readable foreground color (black or white) for a given background color.
Color getContrastColor(Color backgroundColor) {
  // A luminance value of 0.5 is a common threshold.
  // Colors with a luminance greater than 0.5 are considered "light".
  // Colors with a luminance less than or equal to 0.5 are considered "dark".
  // This ensures, for example, that your "eggwhite" color gets black text.
  return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}