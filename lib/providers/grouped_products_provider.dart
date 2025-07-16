// groupedProductsProvider.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';

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

final groupedProductsProvider = Provider.autoDispose<List<ProductGroup>>((ref) {
  final filter = ref.watch(filterStateProvider);
  final products = ref.watch(filteredProductsProvider);

  debugPrint("[GroupedProvider] Running... Input: ${products.length} filtered products.");

  if (products.isEmpty) {
    return [];
  }

  final groupedByDisplayName = groupBy(
    products,
        (Product product) =>
    CategoryService.getStyleForCategory(product.category).displayName,
  );

  debugPrint("[GroupedProvider] After groupBy: ${groupedByDisplayName.keys.length} groups found: ${groupedByDisplayName.keys}");

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
    debugPrint("[GroupedProvider] Sorting group '${group.style.displayName}' with ${group.products.length} items by ${filter.sortOption}.");
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

      // --- CORRECTED LOGIC USING THE NEW GETTER ---
      // This now sorts by the actual percentage discount, which is what users expect.
        case SortOption.discountHighToLow:
          return b.discountRate.compareTo(a.discountRate);
        case SortOption.discountLowToHigh:
          return a.discountRate.compareTo(b.discountRate);
      }
    });
  }

  debugPrint("[GroupedProvider] Output: Returning ${categoryGroups.length} sorted groups.\n");

  return categoryGroups;
});