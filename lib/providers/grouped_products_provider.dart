// lib/providers/grouped_products_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart'; // We DO need this again
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/models/category_style.dart';

// This model is correct and does not need to change.
class ProductGroup {
  final String firestoreName;
  final CategoryStyle style; // This style will now contain the final, translated name.
  final List<PlainProduct> products;
  ProductGroup({required this.firestoreName, required this.style, required this.products});
}

// This input class is correct.
class _FilterAndGroupInput {
  final List<PlainProduct> allProducts;
  final FilterState filter;
  _FilterAndGroupInput({required this.allProducts, required this.filter});
}

// This isolate function is correct. It should work with raw, non-localized data.
Map<String, List<PlainProduct>> _processProductDataInBackground(_FilterAndGroupInput input) {
  // --- NO CHANGES NEEDED HERE ---
  // This function correctly filters, sorts, and groups by the raw firestoreName.
  // This is efficient and correct.
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

  final groupedByFirestoreName = groupBy<PlainProduct, String>(
    filteredProducts, (p) => p.category.isEmpty ? 'other' : p.category,
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

// We bring this back, but it will be provided correctly this time.
final localizationProvider = Provider<AppLocalizations>((ref) {
  throw UnimplementedError('localizationProvider must be overridden with the AppLocalizations object from the UI.');
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

  if (groupedByFirestoreName.isEmpty) {
    return [];
  }

  final categoryGroups = <ProductGroup>[];
  for (final firestoreName in categoryDisplayOrder) {
    if (groupedByFirestoreName.containsKey(firestoreName)) {
      final productList = groupedByFirestoreName[firestoreName]!;
      final translatedStyle = CategoryService.getLocalizedStyleForGroupingName(firestoreName, l10n);

      categoryGroups.add(ProductGroup(
        firestoreName: firestoreName,
        style: translatedStyle,
        products: productList,
      ));
    }
  }

  return categoryGroups;
},
  // --- THIS IS THE FIX ---
  // Explicitly list the providers that this provider depends on, especially
  // the one that is being overridden.
  dependencies: [localizationProvider, appDataProvider, filterStateProvider],
);