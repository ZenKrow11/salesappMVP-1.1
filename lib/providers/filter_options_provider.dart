// lib/providers/filter_options.dart

import 'package:flutter/foundation.dart'; // IMPORTANT: Import for `compute`
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';

// --- HELPER FUNCTION (UNCHANGED) ---
// This function is fine, it will be called inside the isolate.
List<String> _getUniqueOptions(
    List<Product> products,
    String Function(Product) getField,
    ) {
  final options =
  products.map(getField).where((value) => value.isNotEmpty).toSet().toList();
  options.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return options;
}

// =========================================================================
// === NEW: HELPERS FOR BACKGROUND OPTION GENERATION
// =========================================================================

/// A single input class can be used for all option types.
/// This bundles the data needed for the background isolate.
class _OptionsInput {
  final List<Product> products;
  final FilterState filterState;

  _OptionsInput({required this.products, required this.filterState});
}

/// Top-level function to generate STORE options in an isolate.
List<String> _generateStoreOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating store options...");
  return _getUniqueOptions(input.products, (p) => p.store);
}

/// Top-level function to generate CATEGORY options in an isolate.
List<String> _generateCategoryOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating category options...");
  List<Product> relevantProducts = input.products;
  // Filter products by selected stores before generating category options
  if (input.filterState.selectedStores.isNotEmpty) {
    relevantProducts = input.products
        .where((p) => input.filterState.selectedStores.contains(p.store))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.category);
}

/// Top-level function to generate SUBCATEGORY options in an isolate.
List<String> _generateSubcategoryOptionsInBackground(_OptionsInput input) {
  debugPrint("[ISOLATE] Generating subcategory options...");
  List<Product> relevantProducts = input.products;
  // Filter products by stores first
  if (input.filterState.selectedStores.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => input.filterState.selectedStores.contains(p.store))
        .toList();
  }
  // Then filter by categories
  if (input.filterState.selectedCategories.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => input.filterState.selectedCategories.contains(p.category))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.subcategory);
}

// =========================================================================
// === REFACTORED ASYNC PROVIDERS
// =========================================================================

/// A private helper provider to get the plain product list once.
/// This avoids repeating the `map` operation in every option provider.
final _plainProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  // Watch the master list of products
  final productsAsyncValue = ref.watch(initialProductsProvider);
  // Get the list of products, or an empty list if loading/error
  final products = productsAsyncValue.value ?? [];
  // Convert HiveObjects to plain objects, ready for the isolate
  return products.map((p) => p.toPlainObject()).toList();
});

/// Provides a list of unique store names asynchronously.
final storeOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  // We don't need the filter state for store options, so we pass a default one.
  final input = _OptionsInput(
    products: plainProducts,
    filterState: const FilterState(),
  );

  return compute(_generateStoreOptionsInBackground, input);
});

/// Provides the current list of category options asynchronously.
final categoryOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  // Watch the global filter state to react to changes
  final filterState = ref.watch(filterStateProvider);
  final input = _OptionsInput(products: plainProducts, filterState: filterState);

  return compute(_generateCategoryOptionsInBackground, input);
});

/// Provides the current list of subcategory options asynchronously.
final subcategoryOptionsProvider =
FutureProvider.autoDispose<List<String>>((ref) {
  final plainProducts = ref.watch(_plainProductsProvider);
  if (plainProducts.isEmpty) return [];

  // Watch the global filter state to react to changes
  final filterState = ref.watch(filterStateProvider);
  final input = _OptionsInput(products: plainProducts, filterState: filterState);

  return compute(_generateSubcategoryOptionsInBackground, input);
});

// The old family providers are no longer needed and can be deleted.
// The three providers above are the complete replacement.