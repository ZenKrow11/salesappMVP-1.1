// lib/services/category_service.dart

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';

/// A service class to provide centralized logic for handling category data.
///
/// This service acts as an intelligent interpreter for the static data defined
/// in `category_definitions.dart`. It ensures that any changes to the data
/// are automatically reflected in the app's logic without needing to manually
/// update this file.
class CategoryService {
  // Use maps for efficient, O(1) lookups instead of iterating through lists.
  static final Map<String, MainCategory> _mainCategoryMap = {
    for (var cat in allCategories) cat.firestoreName: cat
  };

  static final Map<String, SubCategory> _subCategoryMap = {
    for (var mainCat in allCategories)
      for (var subCat in mainCat.subcategories) subCat.name: subCat
  };

  /// Returns a filtered list of main categories suitable for user selection.
  ///
  /// This method intentionally excludes internal or system-level categories
  /// like 'custom' and 'other', which users should not be able to select directly
  /// when creating an item.
  static List<MainCategory> getAllCategoriesForDropdown() {
    return allCategories
        .where((cat) =>
    cat.firestoreName != 'custom' && cat.firestoreName != 'other')
        .toList();
  }

  /// The single, central hub for translating a display name KEY into a
  /// human-readable, localized string.
  ///
  /// To add a new translation, you only need to add a case here and in your
  /// .arb files. The rest of the service will handle it automatically.
  static String _getTranslationForKey(String key, AppLocalizations l10n) {
    switch (key) {
    // Main Category Display Name Keys
      case 'categoryBeverages': return l10n.categoryBeverages;
      case 'categoryAlcoholicBeverages': return l10n.categoryAlcoholicBeverages;
      case 'categoryBreadBakery': return l10n.categoryBreadBakery;
      case 'categoryFishMeat': return l10n.categoryFishMeat;
      case 'categoryFruitsVegetables': return l10n.categoryFruitsVegetables;
      case 'categoryDairyEggs': return l10n.categoryDairyEggs;
      case 'categorySaltySnacksSweets': return l10n.categorySaltySnacksSweets;
      case 'categorySpecialDiet': return l10n.categorySpecialDiet;
      case 'categoryPantry': return l10n.categoryPantry;
      case 'categoryCustom': return l10n.categoryCustom;
      case 'categoryUncategorized': return l10n.categoryUncategorized;
      case 'categoryOther': return l10n.categoryOther;

    // Subcategory Display Name Keys (which are the same as their 'name')
      case 'categoryCoffeeTeaCocoa': return l10n.categoryCoffeeTeaCocoa;
      case 'categorySoftDrinksEnergyDrinks': return l10n.categorySoftDrinksEnergyDrinks;
      case 'categoryWaterJuices': return l10n.categoryWaterJuices;
      case 'categoryBeer': return l10n.categoryBeer;
      case 'categorySpiritsAssorted': return l10n.categorySpiritsAssorted;
      case 'categoryWinesSparklingWines': return l10n.categoryWinesSparklingWines;
      case 'categoryBakingIngredients': return l10n.categoryBakingIngredients;
      case 'categoryBread': return l10n.categoryBread;
      case 'categoryPastriesDesserts': return l10n.categoryPastriesDesserts;
      case 'categoryMeatMixesAssorted': return l10n.categoryMeatMixesAssorted;
      case 'categoryFishSeafood': return l10n.categoryFishSeafood;
      case 'categoryPoultry': return l10n.categoryPoultry;
      case 'categoryBeefVeal': return l10n.categoryBeefVeal;
      case 'categoryPork': return l10n.categoryPork;
      case 'categorySausagesColdCuts': return l10n.categorySausagesColdCuts;
      case 'categoryFruits': return l10n.categoryFruits;
      case 'categoryVegetables': return l10n.categoryVegetables;
      case 'categoryButterEggs': return l10n.categoryButterEggs;
      case 'categoryCheese': return l10n.categoryCheese;
      case 'categoryMilkDairyProducts': return l10n.categoryMilkDairyProducts;
      case 'categorySnacksAppetizers': return l10n.categorySnacksAppetizers;
      case 'categoryChipsNuts': return l10n.categoryChipsNuts;
      case 'categoryIceCreamSweets': return l10n.categoryIceCreamSweets;
      case 'categoryChocolateCookies': return l10n.categoryChocolateCookies;
      case 'categoryConvenienceReadyMeals': return l10n.categoryConvenienceReadyMeals;
      case 'categoryVeganProducts': return l10n.categoryVeganProducts;
      case 'categoryCerealsGrains': return l10n.categoryCerealsGrains;
      case 'categoryCannedGoodsOilsSaucesSpices': return l10n.categoryCannedGoodsOilsSaucesSpices;
      case 'categoryHoneyJamSpreads': return l10n.categoryHoneyJamSpreads;
      case 'categoryRicePasta': return l10n.categoryRicePasta;
      case 'categoryFrozenProductsSoups': return l10n.categoryFrozenProductsSoups;

      default:
      // A safe fallback that helps with debugging if a key is missed.
        return key;
    }
  }

  /// Dynamically gets the localized display name for any category or subcategory key.
  static String getLocalizedCategoryName(String key, AppLocalizations l10n) {
    if (_mainCategoryMap.containsKey(key)) {
      final displayNameKey = _mainCategoryMap[key]!.style.displayName;
      return _getTranslationForKey(displayNameKey, l10n);
    }
    if (_subCategoryMap.containsKey(key)) {
      // For subcategories, their 'name' is the translation key.
      return _getTranslationForKey(key, l10n);
    }
    // Fallback if the key is not found in any map.
    return _getTranslationForKey(key, l10n);
  }

  /// Gets the style for a category, but with the display name already localized.
  /// This is ideal for UI components like grouped list headers.
  static CategoryStyle getLocalizedStyleForGroupingName(String firestoreName, AppLocalizations l10n) {
    // Default to the 'uncategorized' style if the name is not found.
    final mainCat = _mainCategoryMap[firestoreName] ?? _mainCategoryMap['categoryUncategorized']!;
    final originalStyle = mainCat.style;
    final localizedName = getLocalizedCategoryName(firestoreName, l10n);

    return originalStyle.copyWith(displayName: localizedName);
  }

  /// Gets the base style for any category or subcategory key.
  /// For subcategories, it returns the parent's style but with the subcategory's specific icon.
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

  /// Checks if a given key corresponds to a subcategory.
  static bool isSubCategory(String categoryKey) {
    return _subCategoryMap.containsKey(categoryKey);
  }
}