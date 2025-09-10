// lib/services/category_service.dart

import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/models/product.dart';

class CategoryService {
  // 1. Original map for getting the style of ANY category (main or sub)
  static final Map<String, CategoryStyle> _styleMap = _createStyleMap();

  // 2. NEW: A map to find the main category's DISPLAY NAME for any given category name.
  static final Map<String, String> _categoryToGroupingNameMap = _createGroupingMap();

  // 3. NEW: A map to get the MAIN CATEGORY's style directly from its DISPLAY NAME.
  static final Map<String, CategoryStyle> _groupingNameToStyleMap = _createGroupingStyleMap();

  // --- MAP CREATION (LOGIC IS CONSOLIDATED HERE) ---

  static Map<String, CategoryStyle> _createStyleMap() {
    final map = <String, CategoryStyle>{};
    for (var mainCat in allCategories) {
      map[mainCat.firestoreName] = mainCat.style;
      for (var subCat in mainCat.subcategories) {
        map[subCat.name] = CategoryStyle(
          displayName: mainCat.style.displayName,
          color: mainCat.style.color,
          iconAssetPath: subCat.iconAssetPath,
        );
      }
    }
    return map;
  }

  static Map<String, String> _createGroupingMap() {
    final map = <String, String>{};
    for (var mainCat in allCategories) {
      map[mainCat.firestoreName] = mainCat.style.displayName;
      for (var subCat in mainCat.subcategories) {
        map[subCat.name] = mainCat.style.displayName;
      }
    }
    return map;
  }

  static Map<String, CategoryStyle> _createGroupingStyleMap() {
    final map = <String, CategoryStyle>{};
    for (var mainCat in allCategories) {
      map[mainCat.style.displayName] = mainCat.style;
    }
    return map;
  }

  // --- ADD THIS METHOD ---
  /// Returns the complete list of all main categories and their definitions.
  static List<MainCategory> getAllCategories() {
    return allCategories;
  }
  // --- END OF ADDITION ---

  // --- PUBLIC METHODS (TO BE USED BY THE APP) ---

  /// Gets the style for any specific category or subcategory name.
  /// Used for individual chips.
  static CategoryStyle getStyleForCategory(String categoryName) {
    return _styleMap[categoryName] ?? defaultCategoryStyle;
  }

  /// NEW: Gets the main category's style from the group's display name.
  /// Used for the group header in the UI.
  static CategoryStyle getStyleForGroupingName(String displayName) {
    return _groupingNameToStyleMap[displayName] ?? defaultCategoryStyle;
  }

  /// NEW, ROBUST METHOD FOR GROUPING
  /// Returns the main category's display name (e.g., 'Alkoholische Getränke') for a given product.
  /// It intelligently checks both the product's category and subcategory fields.
  static String getGroupingDisplayNameForProduct(Product product) {
    // Check the main category field first, then the subcategory as a fallback.
    return _categoryToGroupingNameMap[product.category] ??
        _categoryToGroupingNameMap[product.subcategory] ??
        defaultCategoryStyle.displayName;
  }

  // --- Unchanged Methods ---
  static final Set<String> _mainCategoryNames = allCategories.map((c) => c.firestoreName).toSet();
  static final Set<String> _subCategoryNames = allCategories.expand((c) => c.subcategories).map((sc) => sc.name).toSet();
  static bool isMainCategory(String categoryName) => _mainCategoryNames.contains(categoryName);
  static bool isSubCategory(String categoryName) => _subCategoryNames.contains(categoryName);
}