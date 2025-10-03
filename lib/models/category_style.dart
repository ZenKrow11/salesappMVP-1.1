// lib/models/category_style.dart

import 'package:flutter/material.dart';

/// Defines the visual style for a product category or group.
class CategoryStyle {
  final String displayName;
  final Color color;
  final String iconAssetPath;

  const CategoryStyle({
    required this.displayName,
    required this.color,
    required this.iconAssetPath,
  });

  CategoryStyle copyWith({
    String? displayName,
    Color? color,
    String? iconAssetPath,
  }) {
    return CategoryStyle(
      displayName: displayName ?? this.displayName,
      color: color ?? this.color,
      iconAssetPath: iconAssetPath ?? this.iconAssetPath,
    );
  }

}