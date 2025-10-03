// lib/services/category_service.dart

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/models/categorizable.dart';

class CategoryService {
  /// The central translation hub for all category and subcategory names.
  static String _getLocalizedName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'categoryNonAlcoholicBeverages': return l10n.categoryNonAlcoholicBeverages;
      case 'categoryCoffeeTeaCocoa': return l10n.categoryCoffeeTeaCocoa;
      case 'categorySoftDrinksEnergyDrinks': return l10n.categorySoftDrinksEnergyDrinks;
      case 'categoryWaterJuices': return l10n.categoryWaterJuices;
      case 'categoryAlcoholicBeverages': return l10n.categoryAlcoholicBeverages;
      case 'categoryBeer': return l10n.categoryBeer;
      case 'categorySpiritsAssorted': return l10n.categorySpiritsAssorted;
      case 'categoryWinesSparklingWines': return l10n.categoryWinesSparklingWines;
      case 'categoryBreadBakery': return l10n.categoryBreadBakery;
      case 'categoryBakingIngredients': return l10n.categoryBakingIngredients;
      case 'categoryBread': return l10n.categoryBread;
      case 'categoryPastriesDesserts': return l10n.categoryPastriesDesserts;
      case 'categoryFishMeat': return l10n.categoryFishMeat;
      case 'categoryMeatMixesAssorted': return l10n.categoryMeatMixesAssorted;
      case 'categoryFishSeafood': return l10n.categoryFishSeafood;
      case 'categoryPoultry': return l10n.categoryPoultry;
      case 'categoryBeefVeal': return l10n.categoryBeefVeal;
      case 'categoryPork': return l10n.categoryPork;
      case 'categorySausagesColdCuts': return l10n.categorySausagesColdCuts;
      case 'categoryFruitsVegetables': return l10n.categoryFruitsVegetables;
      case 'categoryFruits': return l10n.categoryFruits;
      case 'categoryVegetables': return l10n.categoryVegetables;
      case 'categoryDairyEggs': return l10n.categoryDairyEggs;
      case 'categoryButterEggs': return l10n.categoryButterEggs;
      case 'categoryCheese': return l10n.categoryCheese;
      case 'categoryMilkDairyProducts': return l10n.categoryMilkDairyProducts;
      case 'categorySaltySnacksSweets': return l10n.categorySaltySnacksSweets;
      case 'categorySnacksAppetizers': return l10n.categorySnacksAppetizers;
      case 'categoryChipsNuts': return l10n.categoryChipsNuts;
      case 'categoryIceCreamSweets': return l10n.categoryIceCreamSweets;
      case 'categoryChocolateCookies': return l10n.categoryChocolateCookies;
      case 'categorySpecialDiet': return l10n.categorySpecialDiet;
      case 'categoryConvenienceReadyMeals': return l10n.categoryConvenienceReadyMeals;
      case 'categoryVeganProducts': return l10n.categoryVeganProducts;
      case 'categoryPantry': return l10n.categoryPantry;
      case 'categoryCerealsGrains': return l10n.categoryCerealsGrains;
      case 'categoryCannedGoodsOilsSaucesSpices': return l10n.categoryCannedGoodsOilsSaucesSpices;
      case 'categoryHoneyJamSpreads': return l10n.categoryHoneyJamSpreads;
      case 'categoryRicePasta': return l10n.categoryRicePasta;
      case 'categoryFrozenProductsSoups': return l10n.categoryFrozenProductsSoups;
      case 'categoryOther': return l10n.categoryOther;
      case 'categoryUncategorized': return l10n.categoryUncategorized;
      default: return key;
    }
  }

  // --- NEW UNIFIED & CORRECTED PUBLIC METHODS ---

  /// Returns the complete list of all main category definitions.
  static List<MainCategory> getAllCategories() {
    return allCategories;
  }

  /// Takes a category KEY and returns the translated string.
  static String getLocalizedCategoryName(String key, AppLocalizations l10n) {
    return _getLocalizedName(key, l10n);
  }

  /// Returns a `CategoryStyle` for a given category KEY.
  /// The `displayName` in the returned style will still be a KEY.
  static CategoryStyle getStyleForCategory(String categoryKey) {
    for (var mainCat in allCategories) {
      if (mainCat.firestoreName == categoryKey || mainCat.style.displayName == categoryKey) {
        return mainCat.style;
      }
      for (var subCat in mainCat.subcategories) {
        if (subCat.name == categoryKey) {
          return CategoryStyle(
            displayName: mainCat.style.displayName,
            color: mainCat.style.color,
            iconAssetPath: subCat.iconAssetPath,
          );
        }
      }
    }
    return defaultCategoryStyle;
  }

  /// Checks if a given category KEY corresponds to a subcategory.
  static bool isSubCategory(String categoryNameKey) {
    for (var mainCat in allCategories) {
      if (mainCat.subcategories.any((sub) => sub.name == categoryNameKey)) {
        return true;
      }
    }
    return false;
  }

  /// Takes a stable Firestore name and returns a `CategoryStyle` with the `displayName` already translated.
  static CategoryStyle getLocalizedStyleForGroupingName(String firestoreName, AppLocalizations l10n) {
    final mainCat = allCategories.firstWhere(
            (cat) => cat.firestoreName == firestoreName,
        orElse: () => allCategories.last
    );
    // Return a *new* style object with the translated name
    return mainCat.style.copyWith(displayName: _getLocalizedName(mainCat.style.displayName, l10n));
  }
}