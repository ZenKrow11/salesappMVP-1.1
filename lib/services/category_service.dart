// lib/services/category_service.dart

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';

class CategoryService {
  // Optimizations: Use maps for instant lookups instead of looping.
  static final Map<String, MainCategory> _mainCategoryMap = {
    for (var cat in allCategories) cat.firestoreName: cat
  };

  static final Map<String, SubCategory> _subCategoryMap = {
    for (var mainCat in allCategories)
      for (var subCat in mainCat.subcategories) subCat.name: subCat
  };

  /// Returns the complete list of all main category definitions.
  static List<MainCategory> getAllCategories() {
    return allCategories;
  }

  /// --- THE CENTRAL TRANSLATION HUB ---
  /// Takes a localization key (e.g., "beverages" or "categoryCoffeeTeaCocoa")
  /// and returns the human-readable, translated string.
  static String getLocalizedCategoryName(String key, AppLocalizations l10n) {
    // This switch now contains ALL category and subcategory keys.
    switch (key) {
    // Main Categories
      case 'beverages': return l10n.categoryBeverages;
      case 'alcoholic-beverages': return l10n.categoryAlcoholicBeverages;
      case 'bread-bakery': return l10n.categoryBreadBakery;
      case 'fish-meat': return l10n.categoryFishMeat;
      case 'fruits-vegetables': return l10n.categoryFruitsVegetables;
      case 'dairy-eggs': return l10n.categoryDairyEggs;
      case 'salty-snacks-sweets': return l10n.categorySaltySnacksSweets;
      case 'special-diet': return l10n.categorySpecialDiet;
      case 'pantry': return l10n.categoryPantry;
      case 'custom': return l10n.categoryCustom;
      case 'other': return l10n.categoryOther;

    // Subcategories
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
      case 'categoryUncategorized': return l10n.categoryUncategorized;

      default:
      // Fallback for any key that might be missing in the future.
      // This helps in debugging.
        return key;
    }
  }

  /// Gets the style for a category, but replaces the display name key
  /// with the actual localized string. Useful for grouped lists.
  static CategoryStyle getLocalizedStyleForGroupingName(String firestoreName, AppLocalizations l10n) {
    final mainCat = _mainCategoryMap[firestoreName] ?? _mainCategoryMap['other']!;
    final originalStyle = mainCat.style;
    // Note: The key for the main category's display name is in `originalStyle.displayName`,
    // while the firestoreName is the key for the group itself. They might be different.
    // Assuming here the firestoreName can be used to look up the main category name.
    final localizedName = getLocalizedCategoryName(originalStyle.displayName, l10n);
    return originalStyle.copyWith(displayName: localizedName);
  }

  /// Gets the style for any category or subcategory key.
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