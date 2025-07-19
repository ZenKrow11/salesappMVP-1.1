// lib/providers/filter_options.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

/// Helper function to extract and sort unique string values from a list of products.
List<String> _getUniqueOptions(
    List<Product> products,
    String Function(Product) getField,
    ) {
  final options =
  products.map(getField).where((value) => value.isNotEmpty).toSet().toList();
  options.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return options;
}

/// Provides a list of unique store names from the available products.
final storeOptionsProvider = Provider.autoDispose<List<String>>((ref) {
  // CHANGED: Read from the new central productsProvider.
  final products = ref.watch(productsProvider).value ?? [];
  return _getUniqueOptions(products, (p) => p.store);
});

/// A family provider that generates a list of category options based on a given filter state.
final categoryOptionsProviderFamily =
Provider.autoDispose.family<List<String>, FilterState>((ref, filterState) {
  // CHANGED: Read from the new central productsProvider.
  final products = ref.watch(productsProvider).value ?? [];
  List<Product> relevantProducts = products;

  if (filterState.selectedStores.isNotEmpty) {
    relevantProducts = products
        .where((p) => filterState.selectedStores.contains(p.store))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.category);
});

/// A family provider that generates a list of subcategory options based on a given filter state.
final subcategoryOptionsProviderFamily =
Provider.autoDispose.family<List<String>, FilterState>((ref, filterState) {
  // CHANGED: Read from the new central productsProvider.
  final products = ref.watch(productsProvider).value ?? [];
  List<Product> relevantProducts = products;

  if (filterState.selectedStores.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => filterState.selectedStores.contains(p.store))
        .toList();
  }
  if (filterState.selectedCategories.isNotEmpty) {
    relevantProducts = relevantProducts
        .where((p) => filterState.selectedCategories.contains(p.category))
        .toList();
  }
  return _getUniqueOptions(relevantProducts, (p) => p.subcategory);
});

/// Provides the current list of category options by watching the global filter state.
final categoryOptionsProvider = Provider.autoDispose<List<String>>((ref) {
  final filterState = ref.watch(filterStateProvider);
  return ref.watch(categoryOptionsProviderFamily(filterState));
});

/// Provides the current list of subcategory options by watching the global filter state.
final subcategoryOptionsProvider = Provider.autoDispose<List<String>>((ref) {
  final filterState = ref.watch(filterStateProvider);
  return ref.watch(subcategoryOptionsProviderFamily(filterState));
});