// lib/models/category_style.dart

import 'package:flutter/material.dart';

/// Defines the visual style for a product category or group.
class CategoryStyle {
  final String displayName;
  final Color color;
  final String iconAssetPath; // CHANGED: from IconData to String asset path

  const CategoryStyle({
    required this.displayName,
    required this.color,
    required this.iconAssetPath,
  });
}