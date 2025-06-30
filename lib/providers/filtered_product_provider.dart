import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import 'filter_provider.dart';
import 'search_state.dart';
import '../models/product.dart';
import 'sort_provider.dart';

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(paginatedProductsProvider);
  // These are now lists of strings: List<String>
  final selectedStores = ref.watch(storeFilterProvider);
  final selectedCategories = ref.watch(categoryFilterProvider);
  final selectedSubcategories = ref.watch(subcategoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final sortOption = ref.watch(sortOptionProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products;

      // --- NEW FILTERING LOGIC ---
      // If the list of selected stores is not empty, filter by it.
      if (selectedStores.isNotEmpty) {
        filtered = filtered
            .where((p) => selectedStores.contains(p.store))
            .toList();
      }
      // If the list of selected categories is not empty, filter by it.
      if (selectedCategories.isNotEmpty) {
        filtered = filtered
            .where((p) => selectedCategories.contains(p.category))
            .toList();
      }
      // If the list of selected subcategories is not empty, filter by it.
      if (selectedSubcategories.isNotEmpty) {
        filtered = filtered
            .where((p) => selectedSubcategories.contains(p.subcategory))
            .toList();
      }
      // Search query logic remains the same.
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((p) => p.name.toLowerCase().contains(searchQuery))
            .toList();
      }

      // Apply sorting (no changes needed here)
      switch (sortOption) {
        case SortOption.alphabeticalStore:
          filtered.sort((a, b) => a.store.compareTo(b.store));
          break;
        case SortOption.alphabetical:
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.priceLowToHigh:
          filtered.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
          break;
        case SortOption.discountHighToLow:
          filtered.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
          break;
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});