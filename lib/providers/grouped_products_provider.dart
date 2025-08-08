// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- UPDATED IMPORTS ---
import 'package:sales_app_mvp/models/category_definitions.dart'; // For display order and header styles
import 'package:sales_app_mvp/widgets/category_style.dart';       // The new CategoryStyle model
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';

// REMOVED: categoryDisplayOrder is now imported from category_definitions.dart

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

/// Groups products by category display name and then sorts them based on the filter.
List<ProductGroup> _groupAndSortProductsInBackground(_GroupAndSortInput input) {
  final products = input.products;
  final filter = input.filter;
  if (products.isEmpty) {
    return [];
  }

  // --- REFACTORED GROUPING LOGIC ---

  // 1. Group all products by their assigned display name from the service.
  final groupedByDisplayName = Map<String, List<Product>>.from(
    groupBy(
      products,
          (Product product) =>
      CategoryService.getStyleForCategory(product.category).displayName,
    ),
  );

  final categoryGroups = <ProductGroup>[];

  // 2. Process groups in the pre-defined order for a consistent UI.
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!;

      // **THE FIX**: Use the canonical style from our new map, not a random product's style.
      final style = groupHeaderStyles[displayName] ?? defaultCategoryStyle;

      categoryGroups.add(ProductGroup(style: style, products: productList));
      groupedByDisplayName.remove(displayName); // Remove so it's not processed again
    }
  }

  // 3. Add any remaining (unexpected) groups to the end to prevent data loss.
  for (final entry in groupedByDisplayName.entries) {
    categoryGroups.add(ProductGroup(style: defaultCategoryStyle, products: entry.value));
  }

  // 4. Sort the products within each group according to the current sort option.
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

// ... The rest of the file remains unchanged ...

class _FilterAndGroupInput {
  final List<Product> allProducts;
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}

List<ProductGroup> _filterAndGroupProductsInBackground(
    _FilterAndGroupInput input) {
  final allProducts = input.allProducts;
  final filter = input.filter;
  debugPrint("[ISOLATE-COMBO] Starting filter and group task...");
  List<Product> filteredProducts;
  if (allProducts.isEmpty || filter.isDefault) {
    filteredProducts = allProducts;
  } else {
    filteredProducts = allProducts.where((product) {
      if (filter.selectedStores.isNotEmpty &&
          !filter.selectedStores.contains(product.store)) return false;
      if (filter.selectedCategories.isNotEmpty &&
          !filter.selectedCategories.contains(product.category)) return false;
      if (filter.selectedSubcategories.isNotEmpty &&
          !filter.selectedSubcategories.contains(product.subcategory))
        return false;
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(query);
        final keywordMatch =
        product.searchKeywords.any((k) => k.startsWith(query));
        if (!nameMatch && !keywordMatch) return false;
      }
      return true;
    }).toList();
  }
  debugPrint(
      "[ISOLATE-COMBO] Filtering complete. ${filteredProducts.length} products remaining.");
  final groupingInput =
  _GroupAndSortInput(products: filteredProducts, filter: filter);
  final groupedAndSortedProducts =
  _groupAndSortProductsInBackground(groupingInput);
  debugPrint(
      "[ISOLATE-COMBO] Task complete. Returning ${groupedAndSortedProducts.length} groups.");
  return groupedAndSortedProducts;
}

final homePageProductsProvider =
FutureProvider.autoDispose<List<ProductGroup>>((ref) async {
  final stopwatch = Stopwatch()..start();
  debugPrint("[TIMER-COMBO] homePageProductsProvider: START");

  final allProductsAsync = ref.watch(initialProductsProvider);

  final allProducts = allProductsAsync.value ?? [];
  if (allProducts.isEmpty) {
    debugPrint(
        "[TIMER-COMBO] homePageProductsProvider: END (empty) in ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.stop();
    return [];
  }

  final filter = ref.watch(filterStateProvider);
  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();
  final input =
  _FilterAndGroupInput(allProducts: plainProducts, filter: filter);
  final result = await compute(_filterAndGroupProductsInBackground, input);

  debugPrint(
      "[TIMER-COMBO] homePageProductsProvider: END - Total time: ${stopwatch.elapsedMilliseconds}ms");
  stopwatch.stop();

  return result;
});