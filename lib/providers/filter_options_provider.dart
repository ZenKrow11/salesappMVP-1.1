// lib/providers/filter_options_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
// import 'package:sales_app_mvp/models/product.dart'; // No longer needed
import 'package:sales_app_mvp/models/plain_product.dart'; // <-- IMPORT PlainProduct
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';

// --- FIX E: Update helper functions to accept `PlainProduct` ---
List<String> _getUniqueOptions(
    List<PlainProduct> products,
    String Function(PlainProduct) getField,
    ) {
  final options =
  products.map(getField).where((value) => value.isNotEmpty).toSet().toList();
  options.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return options;
}

class _OptionsInput {
  final List<PlainProduct> products; // <-- TYPE CHANGE
  final FilterState filterState;
  _OptionsInput({required this.products, required this.filterState});
}

List<String> _generateStoreOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating store options...");
  return _getUniqueOptions(input.products, (p) => p.store);
}

List<String> _generateCategoryOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating category options...");
  List<PlainProduct> relevantProducts = input.products; // <-- TYPE CHANGE
  if (input.filterState.selectedStores.isNotEmpty) {
    relevantProducts = input.products
        .where((p) => input.filterState.selectedStores.contains(p.store))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.category);
}

List<String> _generateSubcategoryOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating subcategory options...");
  List<PlainProduct> relevantProducts = input.products; // <-- TYPE CHANGE
  if (input.filterState.selectedStores.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => input.filterState.selectedStores.contains(p.store))
        .toList();
  }
  if (input.filterState.selectedCategories.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => input.filterState.selectedCategories.contains(p.category))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.subcategory);
}

// --- FIX F: (Error at line 77) Update the private provider to return `List<PlainProduct>` ---
final _plainProductsProvider = Provider.autoDispose<List<PlainProduct>>((ref) { // <-- TYPE CHANGE
  final appData = ref.watch(appDataProvider);
  final products = appData.allProducts;
  return products.map((p) => p.toPlainObject()).toList();
});

/// Provides a list of unique store names asynchronously. (UNCHANGED)
final storeOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  final input = _OptionsInput(
    products: plainProducts,
    filterState: const FilterState(),
  );

  return compute(_generateStoreOptionsInBackground, input);
});

/// Provides the current list of category options asynchronously. (UNCHANGED)
final categoryOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  final filterState = ref.watch(filterStateProvider);
  final input = _OptionsInput(products: plainProducts, filterState: filterState);

  return compute(_generateCategoryOptionsInBackground, input);
});

/// Provides the current list of subcategory options asynchronously. (UNCHANGED)
final subcategoryOptionsProvider =
FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  final filterState = ref.watch(filterStateProvider);
  final input = _OptionsInput(products: plainProducts, filterState: filterState);

  return compute(_generateSubcategoryOptionsInBackground, input);
});