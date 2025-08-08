// lib/services/category_service.dart

import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/widgets/category_style.dart';

/// A service to provide consistent styling and information for product categories.
class CategoryService {
  // A map that holds the final, computed style for ANY category name (main or sub).
  static final Map<String, CategoryStyle> _styleMap = _createStyleMap();

  // Sets for quick lookups.
  static final Set<String> _mainCategoryNames = allCategories.map((c) => c.firestoreName).toSet();
  static final Set<String> _subCategoryNames = allCategories.expand((c) => c.subcategories).map((sc) => sc.name).toSet();

  /// Builds the central style map from the definitions list.
  static Map<String, CategoryStyle> _createStyleMap() {
    final map = <String, CategoryStyle>{};
    for (var mainCat in allCategories) {
      // The main category uses its own defined style directly.
      map[mainCat.firestoreName] = mainCat.style;

      // Subcategories get a new style object.
      // They inherit the parent's color and display name, but use their OWN icon.
      for (var subCat in mainCat.subcategories) {
        map[subCat.name] = CategoryStyle(
          displayName: mainCat.style.displayName,
          color: mainCat.style.color,
          iconAssetPath: subCat.iconAssetPath, // The crucial part!
        );
      }
    }
    return map;
  }

  /// Gets the appropriate style for any category name (main or sub).
  /// Falls back to a default style if the name is not found.
  static CategoryStyle getStyleForCategory(String categoryName) {
    return _styleMap[categoryName] ?? defaultCategoryStyle;
  }

  /// Checks if a given name is a main category.
  static bool isMainCategory(String categoryName) {
    return _mainCategoryNames.contains(categoryName);
  }

  /// Checks if a given name is a subcategory.
  static bool isSubCategory(String categoryName) {
    return _subCategoryNames.contains(categoryName);
  }
}