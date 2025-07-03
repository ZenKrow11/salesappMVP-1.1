// lib/providers/products_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/filter_state.dart';
import 'filter_state_provider.dart';

// 1. This provider fetches ALL products from Firestore ONCE and caches the result.
//    This is now our single source of truth for product data. It remains unchanged.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  return snapshot.docs
      .map((doc) => Product.fromFirestore(doc.id, doc.data()))
      .toList();
});


// 2. --- NEW and IMPROVED ---
//    This is the main provider your UI will watch. It takes all products, applies
//    filters and sorting, and provides the final list to the UI.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  // Watch the provider that fetches all data
  final asyncAllProducts = ref.watch(allProductsProvider);
  // Watch the provider that holds the current filter/sort state
  final filterState = ref.watch(filterStateProvider);

  // Handle the loading/error/data states from the initial fetch
  return asyncAllProducts.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (allProducts) {
      // --- Filtering and Sorting Logic (Client-Side) ---

      // Start with the full list of products
      List<Product> filteredList = List.from(allProducts);

      // A. Apply FILTERS
      // Filter by Search Query
      if (filterState.searchQuery.isNotEmpty) {
        final query = filterState.searchQuery.toLowerCase();
        filteredList = filteredList.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.store.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query);
        }).toList();
      }

      // Filter by Store
      if (filterState.selectedStores.isNotEmpty) {
        filteredList = filteredList
            .where((p) => filterState.selectedStores.contains(p.store))
            .toList();
      }

      // Filter by Category
      if (filterState.selectedCategories.isNotEmpty) {
        filteredList = filteredList
            .where((p) => filterState.selectedCategories.contains(p.category))
            .toList();
      }

      // Filter by Subcategory
      if (filterState.selectedSubcategories.isNotEmpty) {
        filteredList = filteredList
            .where((p) => filterState.selectedSubcategories.contains(p.subcategory))
            .toList();
      }


      // B. Apply SORTING
      // This is where you add all your sorting logic!
      filteredList.sort((a, b) {
        switch (filterState.sortOption) {
          case SortOption.storeAlphabetical:
            return a.store.toLowerCase().compareTo(b.store.toLowerCase());
          case SortOption.productAlphabetical:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.priceLowToHigh:
            return a.currentPrice.compareTo(b.currentPrice);
          case SortOption.priceHighToLow:
            return b.currentPrice.compareTo(a.currentPrice);
          case SortOption.discountHighToLow:
            return _parseDiscount(b.discountPercentage).compareTo(_parseDiscount(a.discountPercentage));
          case SortOption.discountLowToHigh:
            return _parseDiscount(a.discountPercentage).compareTo(_parseDiscount(b.discountPercentage));

        // Add sorting by date if you have the field in your Product model
        // case SortOption.dateAddedNewest:
        //   return b.dateAdded.compareTo(a.dateAdded);
        // case SortOption.dateAddedOldest:
        //   return a.dateAdded.compareTo(b.dateAdded);
        }
      });

      // Return the final, filtered, and sorted list
      return AsyncValue.data(filteredList);
    },
  );
});


// Helper function to safely parse the discount string to a number for sorting
double _parseDiscount(String discountStr) {
  final cleanStr = discountStr.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleanStr.isEmpty) return 0.0;
  return double.tryParse(cleanStr) ?? 0.0;
}