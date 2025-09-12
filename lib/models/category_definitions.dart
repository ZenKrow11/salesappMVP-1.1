// lib/models/category_definitions.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/category_style.dart';

const String _iconBasePath = 'assets/images/category_icons/';

// No changes needed here
const List<String> categoryDisplayOrder = [
  'Alkoholfreie Getränke',
  'Alkoholische Getränke',
  'Brot & Backwaren',
  'Fisch & Fleisch',
  'Früchte & Gemüse',
  'Milchprodukte & Eier',
  'Snacks & Süsswaren',
  'Spezifische Ernährung',
  'Vorräte',
  'Sonstiges',
];

// --- DATA STRUCTURES ---
class SubCategory {
  final String name;
  final String iconAssetPath;
  const SubCategory({required this.name, required this.iconAssetPath});
}

class MainCategory {
  final String firestoreName;
  final CategoryStyle style;
  final List<SubCategory> subcategories;
  const MainCategory({
    required this.firestoreName,
    required this.style,
    this.subcategories = const [],
  });
}

// --- CATEGORY LIST ---
// NOTE: Main categories are now correctly sorted alphabetically.
// NOTE: Subcategories are alphabetically sorted.
// NOTE: Colors have been changed to pastel variants.
final List<MainCategory> allCategories = [
  // --- FIX: Corrected alphabetical order ---
  MainCategory(
    firestoreName: 'Alkoholfreie Getränke',
    style: const CategoryStyle(displayName: 'Alkoholfreie Getränke', color: Color(
        0xFF27CBFD), iconAssetPath: '${_iconBasePath}bottle.svg'),
    subcategories: const [
      SubCategory(name: 'Kaffe, Tee und Kakao', iconAssetPath: '${_iconBasePath}coffee_cup.svg'),
      SubCategory(name: 'Softdrinks und Energydrinks', iconAssetPath: '${_iconBasePath}bottle.svg'),
      SubCategory(name: 'Wasser und Säfte', iconAssetPath: '${_iconBasePath}water_bottle.svg'),
    ],
  ),
  // --- FIX: Corrected alphabetical order ---
  MainCategory(
    firestoreName: 'Alkoholische Getränke',
    style: const CategoryStyle(displayName: 'Alkoholische Getränke', color: Color(
        0xFF8141FF), iconAssetPath: '${_iconBasePath}alcohol.svg'),
    subcategories: const [
      SubCategory(name: 'Bier', iconAssetPath: '${_iconBasePath}beer_mug.svg'),
      SubCategory(name: 'Spirituosen und Diverses', iconAssetPath: '${_iconBasePath}alcohol.svg'),
      SubCategory(name: 'Weine und Schaumweine', iconAssetPath: '${_iconBasePath}wine_bottle.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Brot und Backwaren',
    style: const CategoryStyle(displayName: 'Brot & Backwaren', color: Color(0xFFFFB347), iconAssetPath: '${_iconBasePath}bread.svg'),
    subcategories: const [
      SubCategory(name: 'Backzutaten', iconAssetPath: '${_iconBasePath}flour.svg'),
      SubCategory(name: 'Brot', iconAssetPath: '${_iconBasePath}bread.svg'),
      SubCategory(name: 'Gebäcke und Desserts', iconAssetPath: '${_iconBasePath}cake_slice.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Fisch und Fleisch',
    style: const CategoryStyle(displayName: 'Fisch & Fleisch', color: Color(
        0xFFF891A8), iconAssetPath: '${_iconBasePath}meat_slice.svg'),
    subcategories: const [
      SubCategory(name: 'Diverse und Fleischmischungen', iconAssetPath: '${_iconBasePath}meat_slice.svg'),
      SubCategory(name: 'Fisch und Meeresfrüchte', iconAssetPath: '${_iconBasePath}fish.svg'),
      SubCategory(name: 'Geflügel', iconAssetPath: '${_iconBasePath}chicken.svg'),
      SubCategory(name: 'Rind und Kalb', iconAssetPath: '${_iconBasePath}cow.svg'),
      SubCategory(name: 'Schwein', iconAssetPath: '${_iconBasePath}pig.svg'),
      SubCategory(name: 'Wurstwaren und Aufschnitt', iconAssetPath: '${_iconBasePath}sliced_sausage.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Früchte und Gemüse',
    style: const CategoryStyle(displayName: 'Früchte & Gemüse', color: Color(
        0xFF63FB63), iconAssetPath: '${_iconBasePath}fruits.svg'),
    subcategories: const [
      SubCategory(name: 'Früchte', iconAssetPath: '${_iconBasePath}fruits.svg'),
      SubCategory(name: 'Gemüse', iconAssetPath: '${_iconBasePath}carrot.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Milchprodukte und Eier',
    style: const CategoryStyle(displayName: 'Milchprodukte & Eier', color: Color(0xFFFFFACD), iconAssetPath: '${_iconBasePath}eggs.svg'),
    subcategories: const [
      SubCategory(name: 'Butter und Eier', iconAssetPath: '${_iconBasePath}eggs.svg'),
      SubCategory(name: 'Käse', iconAssetPath: '${_iconBasePath}cheese.svg'),
      SubCategory(name: 'Milch und Molkereiprodukte', iconAssetPath: '${_iconBasePath}milk.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Salzige Snacks und Süsswaren',
    style: const CategoryStyle(displayName: 'Snacks & Süsswaren', color: Color(
        0xFFFF9133), iconAssetPath: '${_iconBasePath}chips_bag.svg'),
    subcategories: const [
      SubCategory(name: 'Aperitive und Antipasti', iconAssetPath: '${_iconBasePath}sandwich.svg'),
      SubCategory(name: 'Chips und Nüsse', iconAssetPath: '${_iconBasePath}chips_bag.svg'),
      SubCategory(name: 'Eiscreme und Süsses', iconAssetPath: '${_iconBasePath}ice_cream.svg'),
      SubCategory(name: 'Schokolade und Kekse', iconAssetPath: '${_iconBasePath}chocolate.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Spezifische Ernährung',
    style: const CategoryStyle(displayName: 'Spezifische Ernährung', color: Color(
        0xFF0A4A0A), iconAssetPath: '${_iconBasePath}fast_food.svg'),
    subcategories: const [
      SubCategory(name: 'Convenience und Fertiggerichte', iconAssetPath: '${_iconBasePath}pizza_slice.svg'),
      SubCategory(name: 'Vegane Produkte', iconAssetPath: '${_iconBasePath}vegan_icon.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Vorräte',
    style: const CategoryStyle(displayName: 'Vorräte', color: Color(0xFF2A3D43), iconAssetPath: '${_iconBasePath}food_can.svg'),
    subcategories: const [
      SubCategory(name: 'Cerealien und Getreide', iconAssetPath: '${_iconBasePath}cereals.svg'),
      SubCategory(name: 'Dosen, Öle, Saucen und Gewürze', iconAssetPath: '${_iconBasePath}food_can.svg'),
      SubCategory(name: 'Honig, Konfitüre und Brotaufstrich', iconAssetPath: '${_iconBasePath}honey.svg'),
      SubCategory(name: 'Reis und Teigwaren', iconAssetPath: '${_iconBasePath}rice_bowl.svg'),
      SubCategory(name: 'Tiefkühlprodukte und Suppen', iconAssetPath: '${_iconBasePath}soup_bowl.svg'),
    ],
  ),
  MainCategory(
      firestoreName: 'Sonstiges',
      style: defaultCategoryStyle,
      subcategories: const [
        SubCategory(name: 'Unkategorisiert', iconAssetPath: '${_iconBasePath}default_icon.svg')
      ]
  )
];

const CategoryStyle defaultCategoryStyle = CategoryStyle( displayName: 'Sonstiges', color: Color(
    0xFF757575), iconAssetPath: '${_iconBasePath}default_icon.svg');