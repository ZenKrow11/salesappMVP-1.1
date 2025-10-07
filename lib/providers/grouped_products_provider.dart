// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart'; // Import this
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/models/category_style.dart';

// 1. UPDATED PRODUCT GROUP MODEL
class ProductGroup {
  final String firestoreName;
  final CategoryStyle style;
  final List<PlainProduct> products;
  ProductGroup({required this.firestoreName, required this.style, required this.products});
}

class _FilterAndGroupInput {
  final List<PlainProduct> allProducts;
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}

// 2. ISOLATE FUNCTION (GROUPS BY RAW, NON-TRANSLATED ID)
Map<String, List<PlainProduct>> _processProductDataInBackground(_FilterAndGroupInput input) {
  debugPrint("[ISOLATE] Starting background processing task...");
  final plainProducts = input.allProducts;
  final filter = input.filter;

  List<PlainProduct> filteredProducts;
  if (filter.isSearchActive || filter.isFilterActive) {
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
  } else {
    filteredProducts = plainProducts;
  }
  debugPrint("[ISOLATE] Filtering complete. ${filteredProducts.length} products remaining.");

  if (filteredProducts.isEmpty) return {};

  // Group by the raw 'category' field (the firestoreName). This is stable and non-localized.
  final groupedByFirestoreName = groupBy<PlainProduct, String>(
    filteredProducts, (p) => (p.category == null || p.category.isEmpty) ? 'Sonstige' : p.category,
  );

  for (final productList in groupedByFirestoreName.values) {
    productList.sort((a, b) {
      switch (filter.sortOption) {
        case SortOption.storeAlphabetical: return a.store.toLowerCase().compareTo(b.store.toLowerCase());
        case SortOption.productAlphabetical: return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.priceHighToLow: return b.currentPrice.compareTo(a.currentPrice);
        case SortOption.priceLowToHigh: return a.currentPrice.compareTo(b.currentPrice);
        case SortOption.discountHighToLow: return b.discountRate.compareTo(a.discountRate);
        case SortOption.discountLowToHigh: return a.discountRate.compareTo(b.discountRate);
      }
    });
  }

  debugPrint("[ISOLATE] Task complete. Returning ${groupedByFirestoreName.length} groups keyed by firestoreName.");
  return groupedByFirestoreName;
}

// 3. PROVIDER TO EXPOSE LOCALIZATIONS TO OTHER PROVIDERS
final localizationProvider = Provider<AppLocalizations>((ref) {
  throw UnimplementedError();
});

/// Provider that returns grouped products for the home page.
final homePageProductsProvider =
FutureProvider.autoDispose<List<ProductGroup>>((ref) async {

  final l10n = ref.watch(localizationProvider);
  final appData = ref.watch(appDataProvider);
  final filter = ref.watch(filterStateProvider);

  if (appData.status != InitializationStatus.loaded || appData.allProducts.isEmpty) {
    return [];
  }

  final plainList = appData.allProducts.map((p) => p.toPlainObject()).toList();
  final input = _FilterAndGroupInput(allProducts: plainList, filter: filter);

  final Map<String, List<PlainProduct>> groupedByFirestoreName =
  await compute(_processProductDataInBackground, input);

  // ==================== INSERT LOGGING CODE HERE ====================
  // This code will find and print the details of any products that are being ignored.

  final Set<String> foundCategories = groupedByFirestoreName.keys.toSet();
  final Set<String> expectedCategories = categoryDisplayOrder.toSet(); // Assumes categoryDisplayOrder is accessible
  final Set<String> unhandledCategories = foundCategories.difference(expectedCategories);

  if (unhandledCategories.isNotEmpty) {
    int totalMissingCount = 0;

    print('--- UNHANDLED PRODUCTS DETECTED ---');
    for (final unhandledCategory in unhandledCategories) {
      final missingProducts = groupedByFirestoreName[unhandledCategory]!;
      totalMissingCount += missingProducts.length;
      print("Category: '$unhandledCategory' (${missingProducts.length} items)");
      for (final product in missingProducts) {
        // Log the key details of each missing product
        print('  -> ID: ${product.id}, Name: ${product.name}, Category: ${product.category}');
      }
    }
    print('Total missing products found in logs: $totalMissingCount');
    print('--- END OF UNHANDLED PRODUCTS ---');
  }
  // ======================== END OF LOGGING CODE ========================


  if (groupedByFirestoreName.isEmpty) {
    return [];
  }

  final categoryGroups = <ProductGroup>[];
  for (final firestoreName in categoryDisplayOrder) {
    if (groupedByFirestoreName.containsKey(firestoreName)) {
      final productList = groupedByFirestoreName[firestoreName]!;
      final style = CategoryService.getLocalizedStyleForGroupingName(firestoreName, l10n);

      categoryGroups.add(ProductGroup(
        firestoreName: firestoreName,
        style: style,
        products: productList,
      ));
    }
  }

  return categoryGroups;
},
  dependencies: [localizationProvider],
);