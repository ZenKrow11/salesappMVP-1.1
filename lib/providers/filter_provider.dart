// lib/providers/filter_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'products_provider.dart';
import 'filter_state_provider.dart';

// ...

final storeOptionsProvider = Provider<List<String>>((ref) {
  final allProductsAsync = ref.watch(allProductsProvider);

  // --- FIX: Replaced 'orElse' with explicit 'loading' and 'error' handlers ---
  return allProductsAsync.when(
    data: (products) {
      return products.map((p) => p.store).toSet().toList()..sort();
    },
    loading: () => [], // Return empty list while loading
    error: (e, st) => [], // Return empty list on error
  );
});

final categoryOptionsProvider = Provider<List<String>>((ref) {
  final allProductsAsync = ref.watch(allProductsProvider);
  final selectedStores = ref.watch(filterStateProvider).selectedStores;

  // --- FIX: Replaced 'orElse' ---
  return allProductsAsync.when(
    data: (products) {
      return products
          .where((p) =>
      selectedStores.isEmpty || selectedStores.contains(p.store))
          .map((p) => p.category)
          .toSet()
          .toList()
        ..sort();
    },
    loading: () => [],
    error: (e, st) => [],
  );
});

final subcategoryOptionsProvider = Provider<List<String>>((ref) {
  final allProductsAsync = ref.watch(allProductsProvider);
  final filterState = ref.watch(filterStateProvider);
  final selectedStores = filterState.selectedStores;
  final selectedCategories = filterState.selectedCategories;

  if (selectedCategories.isEmpty) {
    return [];
  }

  // --- FIX: Replaced 'orElse' ---
  return allProductsAsync.when(
    data: (products) {
      return products
          .where((p) =>
      (selectedStores.isEmpty || selectedStores.contains(p.store)) &&
          (selectedCategories.contains(p.category)))
          .map((p) => p.subcategory)
          .toSet()
          .toList()
        ..sort();
    },
    loading: () => [],
    error: (e, st) => [],
  );
});