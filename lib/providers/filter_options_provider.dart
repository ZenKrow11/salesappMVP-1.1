import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart'; // Ensure path is correct
import 'package:sales_app_mvp/providers/products_provider.dart'; // Ensure path is correct

// Helper function to robustly get unique, non-empty strings from a list of products.
List<String> _getUniqueOptions(
    AsyncValue<List<Product>> asyncProducts, // Using the correct type <List<Product>>
    String Function(Product) getField,
    ) {
  // When the product list is loading or has an error, return an empty list.
  return asyncProducts.when(
    data: (products) {
      final options = products
          .map(getField)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      options.sort();
      return options;
    },
    loading: () => [],
    error: (err, stack) => [],
  );
}

// Provider for unique store names.
final storeOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  return _getUniqueOptions(asyncProducts, (product) => product.store);
});

// Provider for unique category names.
final categoryOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  return _getUniqueOptions(asyncProducts, (product) => product.category);
});

// Provider for unique subcategory names.
final subcategoryOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  return _getUniqueOptions(asyncProducts, (product) => product.subcategory);
});