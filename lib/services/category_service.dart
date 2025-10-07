// lib/services/category_service.dart

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';

class CategoryService {
  // --- OPTIMIZATIONS: Use maps for instant lookups instead of looping ---
  static final Map<String, MainCategory> _mainCategoryMap = {
    for (var cat in allCategories) cat.firestoreName: cat
  };

  static final Map<String, SubCategory> _subCategoryMap = {
    for (var mainCat in allCategories)
      for (var subCat in mainCat.subcategories) subCat.name: subCat
  };

  // --- METHOD ADDED BACK TO FIX THE FIRST ERROR ---
  /// Returns the complete list of all main category definitions.
  static List<MainCategory> getAllCategories() {
    return allCategories;
  }

  /// --- THE CENTRAL TRANSLATION HUB ---
  static String getLocalizedCategoryName(String key, AppLocalizations l10n) {
    switch (key) {
    // Main Categories
      case 'beverages': return l10n.categoryBeverages;
      case 'alcoholic-beverages': return l10n.categoryAlcoholicBeverages;
      case 'bread-bakery': return l10n.categoryBreadBakery;
    // ... (all your other main categories) ...
      case 'pantry': return l10n.categoryPantry;
      case 'other': return l10n.categoryOther;

    // --- CASE ADDED TO FIX THE SECOND ERROR ---
      case 'custom': return l10n.categoryCustom;

    // Subcategories
      case 'categoryCoffeeTeaCocoa': return l10n.categoryCoffeeTeaCocoa;
    // ... (all your other subcategories) ...
      case 'categoryUncategorized': return l10n.categoryUncategorized;
      default: return key;
    }
  }

  static CategoryStyle getLocalizedStyleForGroupingName(String firestoreName, AppLocalizations l10n) {
    final mainCat = _mainCategoryMap[firestoreName] ?? _mainCategoryMap['other']!;
    final originalStyle = mainCat.style;
    final localizedName = getLocalizedCategoryName(firestoreName, l10n);
    return originalStyle.copyWith(displayName: localizedName);
  }

  static CategoryStyle getStyleForCategory(String categoryKey) {
    if (_mainCategoryMap.containsKey(categoryKey)) {
      return _mainCategoryMap[categoryKey]!.style;
    }
    for (var mainCat in allCategories) {
      if (mainCat.subcategories.any((sub) => sub.name == categoryKey)) {
        final subCatIcon = _subCategoryMap[categoryKey]!.iconAssetPath;
        return mainCat.style.copyWith(iconAssetPath: subCatIcon);
      }
    }
    return defaultCategoryStyle;
  }

  static bool isSubCategory(String categoryKey) {
    return _subCategoryMap.containsKey(categoryKey);
  }
}