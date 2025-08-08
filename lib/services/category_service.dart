// lib/services/category_service.dart

import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';

class CategoryService {
  static final Map<String, CategoryStyle> _styleMap = _createStyleMap();
  static final Set<String> _mainCategoryNames = allCategories.map((c) => c.firestoreName).toSet();
  static final Set<String> _subCategoryNames = allCategories.expand((c) => c.subcategories).map((sc) => sc.name).toSet();

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

  static CategoryStyle getStyleForCategory(String categoryName) {
    return _styleMap[categoryName] ?? defaultCategoryStyle;
  }

  static bool isMainCategory(String categoryName) => _mainCategoryNames.contains(categoryName);
  static bool isSubCategory(String categoryName) => _subCategoryNames.contains(categoryName);
}