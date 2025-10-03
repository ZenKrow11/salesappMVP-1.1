// lib/models/category_definitions.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/category_style.dart';

const String _iconBasePath = 'assets/images/category_icons/';

// THIS LIST NOW USES THE DATABASE NAMES, NOT DISPLAY NAMES
const List<String> categoryDisplayOrder = [
  'Alkoholfreie Getränke',
  'Alkoholische Getränke',
  'Brot und Backwaren',
  'Fisch und Fleisch',
  'Früchte und Gemüse',
  'Milchprodukte und Eier',
  'Salzige Snacks und Süsswaren',
  'Spezifische Ernährung',
  'Vorräte',
  'Sonstiges',
];

class SubCategory {
  final String name; // This is now a localization KEY
  final String iconAssetPath;
  const SubCategory({required this.name, required this.iconAssetPath});
}

class MainCategory {
  final String firestoreName; // This is the ID from the database
  final CategoryStyle style;
  final List<SubCategory> subcategories;
  const MainCategory({
    required this.firestoreName,
    required this.style,
    this.subcategories = const [],
  });
}

// THE ENTIRE LIST NOW USES LOCALIZATION KEYS FOR USER-FACING TEXT
final List<MainCategory> allCategories = [
  MainCategory(
    firestoreName: 'Alkoholfreie Getränke',
    style: const CategoryStyle(displayName: 'categoryNonAlcoholicBeverages', color: Color(0xFF27CBFD), iconAssetPath: '${_iconBasePath}bottle.svg'),
    subcategories: const [
      SubCategory(name: 'categoryCoffeeTeaCocoa', iconAssetPath: '${_iconBasePath}coffee_cup.svg'),
      SubCategory(name: 'categorySoftDrinksEnergyDrinks', iconAssetPath: '${_iconBasePath}bottle.svg'),
      SubCategory(name: 'categoryWaterJuices', iconAssetPath: '${_iconBasePath}water_bottle.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Alkoholische Getränke',
    style: const CategoryStyle(displayName: 'categoryAlcoholicBeverages', color: Color(0xFF8141FF), iconAssetPath: '${_iconBasePath}alcohol.svg'),
    subcategories: const [
      SubCategory(name: 'categoryBeer', iconAssetPath: '${_iconBasePath}beer_mug.svg'),
      SubCategory(name: 'categorySpiritsAssorted', iconAssetPath: '${_iconBasePath}alcohol.svg'),
      SubCategory(name: 'categoryWinesSparklingWines', iconAssetPath: '${_iconBasePath}wine_bottle.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Brot und Backwaren',
    style: const CategoryStyle(displayName: 'categoryBreadBakery', color: Color(0xFFFFB347), iconAssetPath: '${_iconBasePath}bread.svg'),
    subcategories: const [
      SubCategory(name: 'categoryBakingIngredients', iconAssetPath: '${_iconBasePath}flour.svg'),
      SubCategory(name: 'categoryBread', iconAssetPath: '${_iconBasePath}bread.svg'),
      SubCategory(name: 'categoryPastriesDesserts', iconAssetPath: '${_iconBasePath}cake_slice.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Fisch und Fleisch',
    style: const CategoryStyle(displayName: 'categoryFishMeat', color: Color(0xFFF891A8), iconAssetPath: '${_iconBasePath}meat_slice.svg'),
    subcategories: const [
      SubCategory(name: 'categoryMeatMixesAssorted', iconAssetPath: '${_iconBasePath}meat_slice.svg'),
      SubCategory(name: 'categoryFishSeafood', iconAssetPath: '${_iconBasePath}fish.svg'),
      SubCategory(name: 'categoryPoultry', iconAssetPath: '${_iconBasePath}chicken.svg'),
      SubCategory(name: 'categoryBeefVeal', iconAssetPath: '${_iconBasePath}cow.svg'),
      SubCategory(name: 'categoryPork', iconAssetPath: '${_iconBasePath}pig.svg'),
      SubCategory(name: 'categorySausagesColdCuts', iconAssetPath: '${_iconBasePath}sliced_sausage.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Früchte und Gemüse',
    style: const CategoryStyle(displayName: 'categoryFruitsVegetables', color: Color(0xFF63FB63), iconAssetPath: '${_iconBasePath}fruits.svg'),
    subcategories: const [
      SubCategory(name: 'categoryFruits', iconAssetPath: '${_iconBasePath}fruits.svg'),
      SubCategory(name: 'categoryVegetables', iconAssetPath: '${_iconBasePath}carrot.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Milchprodukte und Eier',
    style: const CategoryStyle(displayName: 'categoryDairyEggs', color: Color(0xFFFFFACD), iconAssetPath: '${_iconBasePath}eggs.svg'),
    subcategories: const [
      SubCategory(name: 'categoryButterEggs', iconAssetPath: '${_iconBasePath}eggs.svg'),
      SubCategory(name: 'categoryCheese', iconAssetPath: '${_iconBasePath}cheese.svg'),
      SubCategory(name: 'categoryMilkDairyProducts', iconAssetPath: '${_iconBasePath}milk.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Salzige Snacks und Süsswaren',
    style: const CategoryStyle(displayName: 'categorySaltySnacksSweets', color: Color(0xFFFF9133), iconAssetPath: '${_iconBasePath}chips_bag.svg'),
    subcategories: const [
      SubCategory(name: 'categorySnacksAppetizers', iconAssetPath: '${_iconBasePath}sandwich.svg'),
      SubCategory(name: 'categoryChipsNuts', iconAssetPath: '${_iconBasePath}chips_bag.svg'),
      SubCategory(name: 'categoryIceCreamSweets', iconAssetPath: '${_iconBasePath}ice_cream.svg'),
      SubCategory(name: 'categoryChocolateCookies', iconAssetPath: '${_iconBasePath}chocolate.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Spezifische Ernährung',
    style: const CategoryStyle(displayName: 'categorySpecialDiet', color: Color(0xFF0A4A0A), iconAssetPath: '${_iconBasePath}fast_food.svg'),
    subcategories: const [
      SubCategory(name: 'categoryConvenienceReadyMeals', iconAssetPath: '${_iconBasePath}pizza_slice.svg'),
      SubCategory(name: 'categoryVeganProducts', iconAssetPath: '${_iconBasePath}vegan_icon.svg'),
    ],
  ),
  MainCategory(
    firestoreName: 'Vorräte',
    style: const CategoryStyle(displayName: 'categoryPantry', color: Color(0xFF2A3D43), iconAssetPath: '${_iconBasePath}food_can.svg'),
    subcategories: const [
      SubCategory(name: 'categoryCerealsGrains', iconAssetPath: '${_iconBasePath}cereals.svg'),
      SubCategory(name: 'categoryCannedGoodsOilsSaucesSpices', iconAssetPath: '${_iconBasePath}food_can.svg'),
      SubCategory(name: 'categoryHoneyJamSpreads', iconAssetPath: '${_iconBasePath}honey.svg'),
      SubCategory(name: 'categoryRicePasta', iconAssetPath: '${_iconBasePath}rice_bowl.svg'),
      SubCategory(name: 'categoryFrozenProductsSoups', iconAssetPath: '${_iconBasePath}soup_bowl.svg'),
    ],
  ),
  MainCategory(
      firestoreName: 'Sonstiges',
      style: defaultCategoryStyle,
      subcategories: const [
        SubCategory(name: 'categoryUncategorized', iconAssetPath: '${_iconBasePath}default_icon.svg')
      ]
  )
];

const CategoryStyle defaultCategoryStyle = CategoryStyle(displayName: 'categoryOther', color: Color(0xFF757575), iconAssetPath: '${_iconBasePath}default_icon.svg');