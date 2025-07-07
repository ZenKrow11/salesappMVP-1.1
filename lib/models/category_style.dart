import 'package:flutter/material.dart';

// No changes to the class itself.
class CategoryStyle {
  final String displayName;
  final Color color;
  final IconData icon;

  const CategoryStyle({
    required this.displayName,
    required this.color,
    required this.icon,
  });
}

// =========================================================================
// === FIX: ALL DEFINITIONS ARE NOW TOP-LEVEL AND TRULY CONSTANT ===========
// =========================================================================

/// The central map linking data categories to their display styles.
/// The KEY is the category name exactly as it appears in your Firestore data.
/// The VALUE is the style to be used in the UI.
final Map<String, CategoryStyle> categoryStyles = {
  // We explicitly define the style for each, removing the problematic self-reference.
  'Alkoholische Getränke': const CategoryStyle(
    displayName: 'Getränke',
    color: Color(0xFF8E44AD),
    icon: Icons.local_bar,
  ),
  'Alkoholfreie Getränke': const CategoryStyle(
    displayName: 'Getränke',
    color: Color(0xFF8E44AD),
    icon: Icons.local_bar,
  ),

  'Brot und Backwaren': const CategoryStyle(
    displayName: 'Brot & Backwaren',
    color: Color(0xFFD35400),
    icon: Icons.bakery_dining,
  ),

  'Fisch und Fleisch': const CategoryStyle(
    displayName: 'Fisch & Fleisch',
    color: Color(0xFFC0392B),
    icon: Icons.set_meal,
  ),

  'Früchte und Gemüse': const CategoryStyle(
    displayName: 'Früchte & Gemüse',
    color: Color(0xFF27AE60),
    icon: Icons.eco,
  ),

  'Milchprodukte und Eier': const CategoryStyle(
    displayName: 'Milchprodukte & Eier',
    color: Color(0xFFF1C40F),
    icon: Icons.egg,
  ),

  'Salzige Snacks und Süsswaren': const CategoryStyle(
    displayName: 'Snacks & Süsswaren',
    color: Color(0xFFE67E22),
    icon: Icons.icecream,
  ),

  'Spezifische Ernährung': const CategoryStyle(
    displayName: 'Spezifische Ernährung',
    color: Color(0xFF7F8C8D),
    icon: Icons.restaurant_menu,
  ),

  'Vorräte': const CategoryStyle(
    displayName: 'Vorräte',
    color: Color(0xFF2C3E50),
    icon: Icons.inventory_2,
  ),
};

/// A fallback style for any product whose category is not found in the map.
const CategoryStyle defaultCategoryStyle = CategoryStyle(
  displayName: 'Sonstiges', // "Miscellaneous"
  color: Colors.grey,
  icon: Icons.category, // A generic category icon
);