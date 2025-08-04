// lib/services/category_service.dart

import 'package:flutter/material.dart';


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
class SubCategory {
  final String name;
  const SubCategory({required this.name});
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


// --- CHANGE 1: Make this list public by removing the underscore ---
final List<MainCategory> allCategories = [
  // ... all your MainCategory definitions remain here ...
  MainCategory(firestoreName: 'Alkoholische Getränke', style: const CategoryStyle(displayName: 'Getränke', color: Color(0xFF4FC3F7), icon: Icons.local_bar,), subcategories: const [SubCategory(name: 'Bier'), SubCategory(name: 'Spirituosen und Diverses'), SubCategory(name: 'Weine und Schaumweine'),],), // CHANGED: Light Blue
  MainCategory(firestoreName: 'Alkoholfreie Getränke', style: const CategoryStyle(displayName: 'Getränke', color: Color(0xFF4FC3F7), icon: Icons.local_bar,), subcategories: const [SubCategory(name: 'Kaffe, Tee und Kakao'), SubCategory(name: 'Softdrinks und Alkoholfreies'), SubCategory(name: 'Wasser und Säfte'),],), // CHANGED: Light Blue
  MainCategory(firestoreName: 'Brot und Backwaren', style: const CategoryStyle(displayName: 'Brot & Backwaren', color: Color(0xFFD35400), icon: Icons.bakery_dining,), subcategories: const [SubCategory(name: 'Brot'), SubCategory(name: 'Backzutaten'), SubCategory(name: 'Gebäcke und Desserts'),],),
  MainCategory(firestoreName: 'Fisch und Fleisch', style: const CategoryStyle(displayName: 'Fisch & Fleisch', color: Color(0xFFFA8072), icon: Icons.set_meal,), subcategories: const [SubCategory(name: 'Fisch und Meeresfrüchte'), SubCategory(name: 'Geflügel'), SubCategory(name: 'Diverse und Fleischmischungen'), SubCategory(name: 'Rind und Kalb'), SubCategory(name: 'Schwein'), SubCategory(name: 'Wurstwaren und Aufschnitt'),],), // CHANGED: Salmon Color
  MainCategory(firestoreName: 'Früchte und Gemüse', style: const CategoryStyle(displayName: 'Früchte & Gemüse', color: Color(0xFF27AE60), icon: Icons.eco,), subcategories: const [SubCategory(name: 'Früchte'), SubCategory(name: 'Gemüse'),],),
  MainCategory(firestoreName: 'Milchprodukte und Eier', style: const CategoryStyle(displayName: 'Milchprodukte & Eier', color: Color(0xFFF5F5F5), icon: Icons.egg,), subcategories: const [SubCategory(name: 'Butter und Eier'), SubCategory(name: 'Käse'), SubCategory(name: 'Milch und Molkereiprodukte'),],), // CHANGED: Egg-white Color
  MainCategory(firestoreName: 'Salzige Snacks und Süsswaren', style: const CategoryStyle(displayName: 'Snacks & Süsswaren', color: Color(0xFFE67E22), icon: Icons.icecream,), subcategories: const [SubCategory(name: 'Chips und Nüsse'), SubCategory(name: 'Diverse Aperitive und Snacks'), SubCategory(name: 'Eiscreme und Süssigkeiten'), SubCategory(name: 'Schokolade und Kekse'),],),
  MainCategory(firestoreName: 'Spezifische Ernährung', style: const CategoryStyle(displayName: 'Spezifische Ernährung', color: Color(0xFF607D3B), icon: Icons.restaurant_menu,), subcategories: const [SubCategory(name: 'Vegane Produkte'), SubCategory(name: 'Convenience und Fertiggerichte'),],), // CHANGED: Moss Green
  MainCategory(firestoreName: 'Vorräte', style: const CategoryStyle(displayName: 'Vorräte', color: Color(0xFF2C3E50), icon: Icons.inventory_2,), subcategories: const [SubCategory(name: 'Dosen, Öle, Saucen und Gewürze'), SubCategory(name: 'Honig, Konfitüre und Brotaufstrich'), SubCategory(name: 'Tiefkühlprodukte und Suppen'), SubCategory(name: 'Cerealien und Getreide'), SubCategory(name: 'Reis und Teigwaren'),],),
];

// --- CHANGE 2: Make this style public by removing the underscore ---
const CategoryStyle defaultCategoryStyle = CategoryStyle(displayName: 'Sonstiges', color: Colors.grey, icon: Icons.category,);

// ... (The CategoryService class is unchanged) ...
class CategoryService {
  static final Map<String, CategoryStyle> _styleMap = _createStyleMap();
  static final Set<String> _mainCategoryNames = allCategories.map((c) => c.firestoreName).toSet();
  static final Set<String> _subCategoryNames = allCategories.expand((c) => c.subcategories).map((sc) => sc.name).toSet();

  static Map<String, CategoryStyle> _createStyleMap() {
    final map = <String, CategoryStyle>{};
    for (var mainCat in allCategories) {
      map[mainCat.firestoreName] = mainCat.style;
      for (var subCat in mainCat.subcategories) {
        map[subCat.name] = mainCat.style;
      }
    }
    return map;
  }
  static CategoryStyle getStyleForCategory(String categoryName) {
    return _styleMap[categoryName] ?? defaultCategoryStyle;
  }
  static bool isMainCategory(String categoryName) {
    return _mainCategoryNames.contains(categoryName);
  }
  static bool isSubCategory(String categoryName) {
    return _subCategoryNames.contains(categoryName);
  }
}