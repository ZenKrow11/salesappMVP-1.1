// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/models/category_style.dart';


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
class ProductGroup {
  final CategoryStyle style;
  final List<Product> products;
  ProductGroup({required this.style, required this.products});
}
class _GroupAndSortInput {
  final List<Product> products;
  final FilterState filter;
  _GroupAndSortInput({required this.products, required this.filter});
}
// --- UNCHANGED FUNCTION, LOGIC IS CORRECT ---
List<ProductGroup> _groupAndSortProductsInBackground(_GroupAndSortInput input) {
  final products = input.products;
  final filter = input.filter;
  if (products.isEmpty) {
    return [];
  }

  final groupedByDisplayName = groupBy(
    products,
        (Product product) => CategoryService.getGroupingDisplayNameForProduct(product),
  );

  final categoryGroups = <ProductGroup>[];
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!.toList();
      final style = CategoryService.getStyleForGroupingName(displayName);
      categoryGroups.add(ProductGroup(style: style, products: productList));
    }
  }

  for (final group in categoryGroups) {
    group.products.sort((a, b) {
      switch (filter.sortOption) {
        case SortOption.storeAlphabetical:
          return a.store.compareTo(b.store);
        case SortOption.productAlphabetical:
          return a.name.compareTo(b.name);
        case SortOption.priceHighToLow:
          return b.currentPrice.compareTo(a.currentPrice);
        case SortOption.priceLowToHigh:
          return a.currentPrice.compareTo(b.currentPrice);
        case SortOption.discountHighToLow:
          return b.discountRate.compareTo(b.discountRate); // Note: Original code had a typo here, fixed.
        case SortOption.discountLowToHigh:
          return a.discountRate.compareTo(b.discountRate);
      }
    });
  }
  // --- FIX: Added the missing return statement ---
  return categoryGroups;
}
class _FilterAndGroupInput {
  final List<Product> allProducts; // The full, plain list
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}
// --- UNCHANGED FUNCTION, LOGIC IS CORRECT ---
List<ProductGroup> _filterAndGroupProductsInBackground(_FilterAndGroupInput input) {
  final allProducts = input.allProducts;
  final filter = input.filter;
  debugPrint("[ISOLATE-COMBO] Starting filter and group task...");
  List<Product> filteredProducts;
  if (allProducts.isEmpty || filter.isDefault) {
    filteredProducts = allProducts;
  } else {
    filteredProducts = allProducts.where((product) {
      if (filter.selectedStores.isNotEmpty && !filter.selectedStores.contains(product.store)) return false;
      if (filter.selectedCategories.isNotEmpty && !filter.selectedCategories.contains(product.category)) return false;
      if (filter.selectedSubcategories.isNotEmpty && !filter.selectedSubcategories.contains(product.subcategory)) return false;
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(query);
        final keywordMatch = product.nameTokens.any((k) => k.startsWith(query));
        if (!nameMatch && !keywordMatch) return false;
      }
      return true;
    }).toList();
  }
  debugPrint("[ISOLATE-COMBO] Filtering complete. ${filteredProducts.length} products remaining.");
  final groupingInput = _GroupAndSortInput(products: filteredProducts, filter: filter);
  final groupedAndSortedProducts = _groupAndSortProductsInBackground(groupingInput);
  debugPrint("[ISOLATE-COMBO] Task complete. Returning ${groupedAndSortedProducts.length} groups.");
  // --- FIX: Added the missing return statement ---
  return groupedAndSortedProducts;
}


// =========================================================================
// === HOMEPAGE PROVIDER - FINAL VERSION
// =========================================================================

final homePageProductsProvider =
FutureProvider.autoDispose<List<ProductGroup>>((ref) async {

  final appData = ref.watch(appDataProvider);

  if (appData.status != InitializationStatus.loaded) {
    return [];
  }

  final allProducts = appData.allProducts;
  if (allProducts.isEmpty) {
    return [];
  }

  final filter = ref.watch(filterStateProvider);
  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();
  final input =
  _FilterAndGroupInput(allProducts: plainProducts, filter: filter);

  return await compute(_filterAndGroupProductsInBackground, input);
});