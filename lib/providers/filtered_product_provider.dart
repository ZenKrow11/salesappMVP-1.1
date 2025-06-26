import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_provider.dart';
import 'filter_providers.dart';
import 'search_state.dart';
import '../models/product.dart';
import 'sort_provider.dart';

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(paginatedProductsProvider);
  final selectedStore = ref.watch(storeFilterProvider);
  final selectedCategory = ref.watch(categoryFilterProvider);
  final selectedSubcategory = ref.watch(subcategoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final sortOption = ref.watch(sortOptionProvider);


  return productsAsync.when(
    data: (products) {
      var filtered = products;

      if (selectedStore != null) {
        filtered = filtered
            .where((p) => p.store.toLowerCase() == selectedStore.toLowerCase())
            .toList();
      }
      if (selectedCategory != null) {
        filtered = filtered
            .where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase())
            .toList();
      }
      if (selectedSubcategory != null) {
        filtered = filtered
            .where((p) => p.subcategory.toLowerCase() == selectedSubcategory.toLowerCase())
            .toList();
      }
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((p) => p.name.toLowerCase().contains(searchQuery))
            .toList();
      }

      // Apply sorting
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
