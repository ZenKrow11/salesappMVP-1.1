import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart'; // Required for dynamic filtering

/// Helper function to get unique, sorted, non-empty strings from a list of products.
List<String> _getUniqueOptions(
    List<Product> products, // Takes a direct list, not an AsyncValue
    String Function(Product) getField,
    ) {
  final options =
  products.map(getField).where((value) => value.isNotEmpty).toSet().toList();
  options.sort();
  return options;
}

/// Provider for unique store names. This usually doesn't need to be dynamic.
final storeOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  return asyncProducts.when(
    data: (products) => _getUniqueOptions(products, (p) => p.store),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// DYNAMIC provider for category names.
/// It provides category options based on the currently selected stores.
final categoryOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  final filterState = ref.watch(filterStateProvider);

  return asyncProducts.when(
    data: (products) {
      List<Product> relevantProducts = products;

      // If stores are selected, only show categories from products in those stores.
      if (filterState.selectedStores.isNotEmpty) {
        relevantProducts = products
            .where((p) => filterState.selectedStores.contains(p.store))
            .toList();
      }

      return _getUniqueOptions(relevantProducts, (p) => p.category);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});


/// DYNAMIC provider for subcategory names.
/// It provides subcategory options based on currently selected stores AND categories.
final subcategoryOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  final filterState = ref.watch(filterStateProvider);

  return asyncProducts.when(
    data: (products) {
      List<Product> relevantProducts = products;

      // Filter by selected stores first.
      if (filterState.selectedStores.isNotEmpty) {
        relevantProducts = relevantProducts
            .where((p) => filterState.selectedStores.contains(p.store))
            .toList();
      }

      // Then, filter by selected categories.
      if (filterState.selectedCategories.isNotEmpty) {
        relevantProducts = relevantProducts
            .where((p) => filterState.selectedCategories.contains(p.category))
            .toList();
      }

      return _getUniqueOptions(relevantProducts, (p) => p.subcategory);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});