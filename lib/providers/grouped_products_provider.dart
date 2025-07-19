// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';

// Your existing const list remains unchanged.
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

// Your existing class remains unchanged.
class ProductGroup {
  final CategoryStyle style;
  final List<Product> products;
  ProductGroup({required this.style, required this.products});
}

// =========================================================================
// === STEP 1 OF 3: THE HELPER CLASS FOR ISOLATE INPUT                  ===
// =========================================================================

/// A helper class to bundle the data needed for the background isolate.
/// The compute() function can only accept a single argument.
class _GroupAndSortInput {
  final List<Product> products;
  final FilterState filter;

  _GroupAndSortInput({required this.products, required this.filter});
}


// =========================================================================
// === STEP 2 OF 3: THE TOP-LEVEL FUNCTION FOR THE ISOLATE             ===
// =========================================================================

/// This function will be executed in a separate isolate to avoid blocking the UI thread.
/// It contains all the heavy grouping and sorting logic.
List<ProductGroup> _groupAndSortProductsInBackground(_GroupAndSortInput input) {
  // Unpack the input data
  final products = input.products;
  final filter = input.filter;

  debugPrint("[ISOLATE] Grouping and sorting running in background... Input: ${products.length} products.");

  if (products.isEmpty) {
    return [];
  }

  // --- All your existing logic is copied here ---
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

  debugPrint("[ISOLATE] Background work complete. Returning ${categoryGroups.length} sorted groups.\n");

  return categoryGroups;
}


// =========================================================================
// === STEP 3 OF 3: THE NEW ASYNCHRONOUS PROVIDER                      ===
// =========================================================================

/// This provider is now a FutureProvider. It watches for changes in filters
/// or products and re-runs the expensive grouping/sorting logic in a
/// background isolate, preventing any UI freezes.
final groupedProductsProvider = FutureProvider.autoDispose<List<ProductGroup>>((ref) async {
  // Watch the dependencies as before.
  final filter = ref.watch(filterStateProvider);
  final products = ref.watch(filteredProductsProvider);

  // An optimization: if there's nothing to process, return immediately.
  if (products.isEmpty) {
    return [];
  }

  // THIS IS THE FIX: Convert live HiveObjects to plain objects
  final plainProducts = products.map((p) => p.toPlainObject()).toList();

  // Bundle the NEW plain data into our helper class.
  final input = _GroupAndSortInput(products: plainProducts, filter: filter);

  // Call compute() to run our function in the background. This will now succeed.
  return compute(_groupAndSortProductsInBackground, input);
});