// lib/models/category_definitions.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/category_style.dart';

/// The base path for all category icon assets.
const String _iconBasePath = 'assets/images/category_icons/';

// --- DATA STRUCTURES ---

class SubCategory {
  final String name;
  final String iconAssetPath; // NEW: Each subcategory has its own icon.

  const SubCategory({required this.name, required this.iconAssetPath});
}

class MainCategory {
  final String firestoreName;
  final CategoryStyle style; // The style for the main group (header, etc.)
  final List<SubCategory> subcategories;

  const MainCategory({
    required this.firestoreName,
    required this.style,
    this.subcategories = const [],
  });
}

// --- CENTRALIZED CATEGORY DEFINITIONS ---

/// A complete list of all product categories and their associated styles and icons.
/// This is the single source of truth for the entire app.
final List<MainCategory> allCategories = [
  MainCategory(
    firestoreName: 'Alkoholische Getränke',
    style: const CategoryStyle(displayName: 'Getränke', color: Color(0xFF4FC3F7), iconAssetPath: '${_iconBasePath}alcohol.svg'),
    subcategories: const [
      SubCategory(name: 'Bier', iconAssetPath: '${_iconBasePath}beer_mug.svg'),
      SubCategory(name: 'Spirituosen und Diverses', iconAssetPath: '${_iconBasePath}alcohol.svg'),
      SubCategory(name: 'Weine und Schaumweine', iconAssetPath: '${_iconBasePath}wine_bottle.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Alkoholfreie Getränke',
    style: const CategoryStyle(displayName: 'Getränke', color: Color(0xFF4FC3F7), iconAssetPath: '${_iconBasePath}bottle.svg'),
    subcategories: const [
      SubCategory(name: 'Kaffe, Tee und Kakao', iconAssetPath: '${_iconBasePath}coffee_cup.svg'),
      SubCategory(name: 'Softdrinks und Alkoholfreies', iconAssetPath: '${_iconBasePath}bottle.svg'),
      SubCategory(name: 'Wasser und Säfte', iconAssetPath: '${_iconBasePath}water_bottle.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Brot und Backwaren',
    style: const CategoryStyle(displayName: 'Brot & Backwaren', color: Color(0xFFD35400), iconAssetPath: '${_iconBasePath}bread.svg'),
    subcategories: const [
      SubCategory(name: 'Brot', iconAssetPath: '${_iconBasePath}bread.svg'),
      SubCategory(name: 'Backzutaten', iconAssetPath: '${_iconBasePath}flour.svg'),
      SubCategory(name: 'Gebäcke und Desserts', iconAssetPath: '${_iconBasePath}cake_slice.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Fisch und Fleisch',
    style: const CategoryStyle(displayName: 'Fisch & Fleisch', color: Color(0xFFFA8072), iconAssetPath: '${_iconBasePath}meat_slice.svg'),
    subcategories: const [
      SubCategory(name: 'Fisch und Meeresfrüchte', iconAssetPath: '${_iconBasePath}fish.svg'),
      SubCategory(name: 'Geflügel', iconAssetPath: '${_iconBasePath}chicken.svg'),
      SubCategory(name: 'Diverse und Fleischmischungen', iconAssetPath: '${_iconBasePath}meat_slice.svg'),
      SubCategory(name: 'Rind und Kalb', iconAssetPath: '${_iconBasePath}cow.svg'),
      SubCategory(name: 'Schwein', iconAssetPath: '${_iconBasePath}pig.svg'),
      SubCategory(name: 'Wurstwaren und Aufschnitt', iconAssetPath: '${_iconBasePath}sliced_sausage.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Früchte und Gemüse',
    style: const CategoryStyle(displayName: 'Früchte & Gemüse', color: Color(0xFF27AE60), iconAssetPath: '${_iconBasePath}fruits.svg'),
    subcategories: const [
      SubCategory(name: 'Früchte', iconAssetPath: '${_iconBasePath}fruits.svg'),
      SubCategory(name: 'Gemüse', iconAssetPath: '${_iconBasePath}carrot.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Milchprodukte und Eier',
    style: const CategoryStyle(displayName: 'Milchprodukte & Eier', color: Color(0xFFF5F5F5), iconAssetPath: '${_iconBasePath}eggs.svg'),
    subcategories: const [
      SubCategory(name: 'Butter und Eier', iconAssetPath: '${_iconBasePath}eggs.svg'),
      SubCategory(name: 'Käse', iconAssetPath: '${_iconBasePath}cheese.svg'),
      SubCategory(name: 'Milch und Molkereiprodukte', iconAssetPath: '${_iconBasePath}milk.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Salzige Snacks und Süsswaren',
    style: const CategoryStyle(displayName: 'Snacks & Süsswaren', color: Color(0xFFE67E22), iconAssetPath: '${_iconBasePath}chips_bag.svg'),
    subcategories: const [
      SubCategory(name: 'Chips und Nüsse', iconAssetPath: '${_iconBasePath}chips_bag.svg'),
      SubCategory(name: 'Diverse Aperitive und Snacks', iconAssetPath: '${_iconBasePath}sandwich.svg'), // Note: Mapped to sandwich.svg per your file
      SubCategory(name: 'Eiscreme und Süssigkeiten', iconAssetPath: '${_iconBasePath}ice_cream.svg'),
      SubCategory(name: 'Schokolade und Kekse', iconAssetPath: '${_iconBasePath}chocolate.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Spezifische Ernährung',
    style: const CategoryStyle(displayName: 'Spezifische Ernährung', color: Color(0xFF607D3B), iconAssetPath: '${_iconBasePath}fast_food.svg'),
    subcategories: const [
      SubCategory(name: 'Vegane Produkte', iconAssetPath: '${_iconBasePath}vegan_icon.svg'),
      SubCategory(name: 'Convenience und Fertiggerichte', iconAssetPath: '${_iconBasePath}pizza_slice.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Vorräte',
    style: const CategoryStyle(displayName: 'Vorräte', color: Color(0xFF2C3E50), iconAssetPath: '${_iconBasePath}food_can.svg'),
    subcategories: const [
      SubCategory(name: 'Dosen, Öle, Saucen und Gewürze', iconAssetPath: '${_iconBasePath}food_can.svg'),
      SubCategory(name: 'Honig, Konfitüre und Brotaufstrich', iconAssetPath: '${_iconBasePath}honey.svg'),
      SubCategory(name: 'Tiefkühlprodukte und Suppen', iconAssetPath: '${_iconBasePath}soup_bowl.svg'),
      SubCategory(name: 'Cerealien und Getreide', iconAssetPath: '${_iconBasePath}cereals.svg'),
      SubCategory(name: 'Reis und Teigwaren', iconAssetPath: '${_iconBasePath}rice_bowl.svg'),
    ],
  ),
];

/// A fallback style for any category not found in the definitions.
const CategoryStyle defaultCategoryStyle = CategoryStyle(
  displayName: 'Sonstiges',
  color: Colors.grey,
  iconAssetPath: '${_iconBasePath}default_icon.svg',
);

// =========================================================================
// === DEFINITIONS FOR GROUPED UI ==========================================
// =========================================================================

/// The canonical visual style for each high-level product group.
/// This is used for headers in the main product list to ensure consistency.
final Map<String, CategoryStyle> groupHeaderStyles = {
  'Brot & Backwaren': const CategoryStyle(
    displayName: 'Brot & Backwaren',
    color: Color(0xFFD35400),
    iconAssetPath: '${_iconBasePath}bread.svg',
  ),
  'Fisch & Fleisch': const CategoryStyle(
    displayName: 'Fisch & Fleisch',
    color: Color(0xFFFA8072),
    iconAssetPath: '${_iconBasePath}meat_slice.svg',
  ),
  'Früchte & Gemüse': const CategoryStyle(
    displayName: 'Früchte & Gemüse',
    color: Color(0xFF27AE60),
    iconAssetPath: '${_iconBasePath}fruits.svg',
  ),
  'Getränke': const CategoryStyle(
    displayName: 'Getränke',
    color: Color(0xFF4FC3F7),
    iconAssetPath: '${_iconBasePath}water_bottle.svg', // Using a generic icon for the whole group
  ),
  'Milchprodukte & Eier': const CategoryStyle(
    displayName: 'Milchprodukte & Eier',
    color: Color(0xFFF5F5F5),
    iconAssetPath: '${_iconBasePath}eggs.svg',
  ),
  'Snacks & Süsswaren': const CategoryStyle(
    displayName: 'Snacks & Süsswaren',
    color: Color(0xFFE67E22),
    iconAssetPath: '${_iconBasePath}chips_bag.svg',
  ),
  'Spezifische Ernährung': const CategoryStyle(
    displayName: 'Spezifische Ernährung',
    color: Color(0xFF607D3B),
    iconAssetPath: '${_iconBasePath}fast_food.svg',
  ),
  'Vorräte': const CategoryStyle(
    displayName: 'Vorräte',
    color: Color(0xFF2C3E50),
    iconAssetPath: '${_iconBasePath}food_can.svg',
  ),
  'Sonstiges': defaultCategoryStyle, // Re-use the default style for the "misc" group
};

/// The desired order for displaying product groups on the homepage.
const List<String> categoryDisplayOrder = [
  'Brot & Backwaren',
  'Fisch & Fleisch',
  'Früchte & Gemüse',
  'Getränke',
  'Milchprodukte & Eier',
  'Snacks & Süsswaren',
  'Spezifische Ernährung',
  'Vorräte',
  'Sonstiges',
];