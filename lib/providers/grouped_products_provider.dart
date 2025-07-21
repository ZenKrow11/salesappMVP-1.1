// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
// UPDATED: Import the new provider file
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';

// --- All the top-level constants, classes, and background functions remain exactly the same ---
// const List<String> categoryDisplayOrder = ...
// class ProductGroup { ... }
// class _GroupAndSortInput { ... }
// List<ProductGroup> _groupAndSortProductsInBackground(...) { ... }
// class _FilterAndGroupInput { ... }
// List<ProductGroup> _filterAndGroupProductsInBackground(...) { ... }
// --- No changes needed for the code above this line ---

const List<String> categoryDisplayOrder = [
  'Brot & Backwaren',
  'Fisch & Fleisch',
  'Früchte & Gemüse',
  'Getränke',
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
List<ProductGroup> _groupAndSortProductsInBackground(_GroupAndSortInput input) {
  final products = input.products;
  final filter = input.filter;
  if (products.isEmpty) {
    return [];
  }
  final groupedByDisplayName = groupBy(
    products,
        (Product product) =>
    CategoryService.getStyleForCategory(product.category).displayName,
  );
  final categoryGroups = <ProductGroup>[];
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!.toList();
      final style =
      CategoryService.getStyleForCategory(productList.first.category);
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
          return b.discountRate.compareTo(a.discountRate);
        case SortOption.discountLowToHigh:
          return a.discountRate.compareTo(b.discountRate);
      }
    });
  }
  return categoryGroups;
}
class _FilterAndGroupInput {
  final List<Product> allProducts; // The full, plain list
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}
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
        final keywordMatch = product.searchKeywords.any((k) => k.startsWith(query));
        if (!nameMatch && !keywordMatch) return false;
      }
      return true;
    }).toList();
  }
  debugPrint("[ISOLATE-COMBO] Filtering complete. ${filteredProducts.length} products remaining.");
  final groupingInput = _GroupAndSortInput(products: filteredProducts, filter: filter);
  final groupedAndSortedProducts = _groupAndSortProductsInBackground(groupingInput);
  debugPrint("[ISOLATE-COMBO] Task complete. Returning ${groupedAndSortedProducts.length} groups.");
  return groupedAndSortedProducts;
}

// =========================================================================
// === HOMEPAGE PROVIDER - UPDATED
// =========================================================================

/// The ONLY provider your homepage should watch. It's more efficient.
final homePageProductsProvider =
FutureProvider.autoDispose<List<ProductGroup>>((ref) async {

  final stopwatch = Stopwatch()..start();
  debugPrint("[TIMER-COMBO] homePageProductsProvider: START");

  // A. Get the full product list from our NEW STABLE provider
  //    This is the only change needed in this provider.
  final allProductsAsync = ref.watch(initialProductsProvider);

  final allProducts = allProductsAsync.value ?? [];
  if (allProducts.isEmpty) {
    debugPrint("[TIMER-COMBO] homePageProductsProvider: END (empty) in ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.stop();
    return [];
  }

  // B. Get the current filter
  final filter = ref.watch(filterStateProvider);

  // C. Convert to plain objects
  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();

  // D. Bundle and run the SINGLE background task
  final input =
  _FilterAndGroupInput(allProducts: plainProducts, filter: filter);
  final result = await compute(_filterAndGroupProductsInBackground, input);

  debugPrint("[TIMER-COMBO] homePageProductsProvider: END - Total time: ${stopwatch.elapsedMilliseconds}ms");
  stopwatch.stop();

  return result;
});