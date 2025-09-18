// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/models/category_style.dart';

/// Group model returned to UI (contains plain product objects).
class ProductGroup {
  final CategoryStyle style;
  final List<PlainProduct> products;
  ProductGroup({required this.style, required this.products});
}

/// Input object passed to compute() - NOTE: contains only sendable data
class _FilterAndGroupInput {
  final List<PlainProduct> allProducts;
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}

/// This function runs inside the isolate. It MUST only handle sendable objects
List<ProductGroup> _processProductDataInBackground(_FilterAndGroupInput input) {
  debugPrint("[ISOLATE] Starting background processing task...");

  final plainProducts = input.allProducts;
  debugPrint("[ISOLATE] Received ${plainProducts.length} plain products.");

  final filter = input.filter;

  // Filtering
  List<PlainProduct> filteredProducts;
  if (filter.isDefault) {
    filteredProducts = plainProducts;
  } else {
    filteredProducts = plainProducts.where((product) {
      if (filter.selectedStores.isNotEmpty && !filter.selectedStores.contains(product.store)) return false;
      if (filter.selectedCategories.isNotEmpty && !filter.selectedCategories.contains(product.category)) return false;
      if (filter.selectedSubcategories.isNotEmpty && !filter.selectedSubcategories.contains(product.subcategory)) return false;
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) && !product.nameTokens.any((k) => k.startsWith(query))) {
          return false;
        }
      }
      return true;
    }).toList();
  }
  debugPrint("[ISOLATE] Filtering complete. ${filteredProducts.length} products remaining.");

  if (filteredProducts.isEmpty) {
    return [];
  }

  final groupedByDisplayName = groupBy<PlainProduct, String>(
    filteredProducts,
        (PlainProduct product) => CategoryService.getGroupingDisplayNameForProduct(product),
  );

  final categoryGroups = <ProductGroup>[];
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!;
      final style = CategoryService.getStyleForGroupingName(displayName);
      categoryGroups.add(ProductGroup(style: style, products: productList));
    }
  }

  // Sorting within groups
  for (final group in categoryGroups) {
    group.products.sort((a, b) {
      switch (filter.sortOption) {
        case SortOption.storeAlphabetical:
          return a.store.toLowerCase().compareTo(b.store.toLowerCase());
        case SortOption.productAlphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.priceHighToLow:
          return b.currentPrice.compareTo(a.currentPrice);
        case SortOption.priceLowToHigh:
          return a.currentPrice.compareTo(b.currentPrice);
        case SortOption.discountHighToLow:
          return b.discountRate.compareTo(a.discountRate);
        case SortOption.discountLowToHigh:
          return a.discountRate.compareTo(b.discountRate);
      }
      return 0;
    });
  }

  debugPrint("[ISOLATE] Task complete. Returning ${categoryGroups.length} groups.");
  return categoryGroups;
}

/// Provider that returns grouped products for the home page.
/// IMPORTANT: convert Hive Product -> PlainProduct BEFORE calling compute().
final homePageProductsProvider =
FutureProvider.autoDispose<List<ProductGroup>>((ref) async {
  final appData = ref.watch(appDataProvider);
  final filter = ref.watch(filterStateProvider);

  if (appData.status != InitializationStatus.loaded || appData.allProducts.isEmpty) {
    return [];
  }

  // Convert the Hive-backed Product objects into plain, sendable PlainProduct objects BEFORE compute.
  final plainList = appData.allProducts.map((p) => p.toPlainObject()).toList();

  final input = _FilterAndGroupInput(allProducts: plainList, filter: filter);

  // Run background processing on sendable data only.
  return await compute(_processProductDataInBackground, input);
});
