import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_provider.dart';

/// --- FILTER STATE PROVIDERS ---
/// These providers now hold a list of selected filters to support multi-selection.
/// An empty list means no filter is applied for that category.

// Store filter
final storeFilterProvider = StateProvider<List<String>>((ref) => []);

// Category filter
final categoryFilterProvider = StateProvider<List<String>>((ref) => []);

// Subcategory filter
final subcategoryFilterProvider = StateProvider<List<String>>((ref) => []);


/// --- FILTER OPTION LIST PROVIDERS ---
/// These providers generate the list of available choices for the filters.
/// They dynamically update based on other active filters for a better UX.

// Store options: Provides a list of all unique stores from the dataset.
final storeListProvider = Provider<List<String>>((ref) {
  return ref.watch(paginatedProductsProvider).maybeWhen(
    data: (products) {
      final stores = products.map((p) => p.store).toSet().toList()..sort();
      return stores;
    },
    orElse: () => [],
  );
});

// Category options: Filtered by the selected store(s).
final categoryListProvider = Provider<List<String>>((ref) {
  final selectedStores = ref.watch(storeFilterProvider);

  return ref.watch(paginatedProductsProvider).maybeWhen(
    data: (products) {
      final categories = products
          .where((p) =>
      // If no stores are selected, include all. Otherwise, check if product's store is in the selected list.
      selectedStores.isEmpty || selectedStores.contains(p.store))
          .map((p) => p.category)
          .toSet()
          .toList()
        ..sort();
      return categories;
    },
    orElse: () => [],
  );
});

// Subcategory options: Filtered by the selected store(s) and category(s).
final subcategoryListProvider = Provider<List<String>>((ref) {
  final selectedStores = ref.watch(storeFilterProvider);
  final selectedCategories = ref.watch(categoryFilterProvider);

  // If no category is selected, it doesn't make sense to show any subcategories.
  if (selectedCategories.isEmpty) {
    return [];
  }

  return ref.watch(paginatedProductsProvider).maybeWhen(
    data: (products) {
      final subcategories = products
          .where((p) =>
      // Check against selected stores (if any)
      (selectedStores.isEmpty || selectedStores.contains(p.store)) &&
          // Check against selected categories (must have at least one)
          (selectedCategories.contains(p.category)))
          .map((p) => p.subcategory)
          .toSet()
          .toList()
        ..sort();
      return subcategories;
    },
    orElse: () => [],
  );
});