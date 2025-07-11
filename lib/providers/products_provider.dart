import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ProductCount class is unchanged
class ProductCount {
  final int filtered;
  final int total;
  ProductCount({required this.filtered, required this.total});
}

final _firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// --- THE SINGLE SOURCE OF TRUTH ---
// This provider fetches ALL products from Firestore ONCE and caches them.
// All other providers will now get their data from here.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  print("🔄 [allProductsProvider] Fetching ALL products from Firestore... (Should run once per session)");
  final snapshot = await ref.watch(_firestoreProvider).collection('products').get();
  final products = snapshot.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
  print("✅ [allProductsProvider] Fetched ${products.length} products.");
  return products;
});

// --- REFACTORED filteredProductsProvider ---
// This provider now filters the list from allProductsProvider IN-MEMORY.
// It's a simple Provider, not a StreamProvider, making it fast and synchronous.
final filteredProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  final filter = ref.watch(filterStateProvider);
  final allProductsAsync = ref.watch(allProductsProvider);

  return allProductsAsync.when(
    loading: () => [], // Return empty list while the main provider is loading
    error: (err, stack) => [], // Return empty list on error
    data: (allProducts) {
      // Start with the full list and apply filters sequentially.
      List<Product> filteredList = allProducts;

      // Filter by stores
      if (filter.selectedStores.isNotEmpty) {
        filteredList = filteredList.where((p) => filter.selectedStores.contains(p.store)).toList();
      }
      // Filter by categories
      if (filter.selectedCategories.isNotEmpty) {
        filteredList = filteredList.where((p) => filter.selectedCategories.contains(p.category)).toList();
      }
      // Filter by subcategories
      if (filter.selectedSubcategories.isNotEmpty) {
        filteredList = filteredList.where((p) => filter.selectedSubcategories.contains(p.subcategory)).toList();
      }

      // *** THE CRITICAL SEARCH LOGIC FIX ***
      // This logic now works because it searches the Product object directly.
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        filteredList = filteredList.where((p) {
          // It will match if the full name contains the query (e.g., when a suggestion is clicked)
          final nameMatch = p.name.toLowerCase().contains(query);
          // OR if any of its keywords start with the query (for partial typing)
          final keywordMatch = p.searchKeywords.any((k) => k.startsWith(query));
          return nameMatch || keywordMatch;
        }).toList();
      }

      // Sort the already filtered list
      // This is identical to your original sorting logic.
      switch (filter.sortOption) {
        case SortOption.storeAlphabetical:
          filteredList.sort((a, b) => a.store.compareTo(b.store));
          break;
        case SortOption.productAlphabetical:
          filteredList.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.priceHighToLow:
          filteredList.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
          break;
        case SortOption.priceLowToHigh:
          filteredList.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
          break;
        default:
          filteredList.sort((a, b) => a.store.compareTo(b.store));
      }

      return filteredList;
    },
  );
});

// --- REFACTORED productCountProvider ---
// This also no longer talks to Firestore. It just gets counts from other providers.
final productCountProvider = Provider.autoDispose<ProductCount>((ref) {
  final totalCount = ref.watch(allProductsProvider).asData?.value.length ?? 0;
  final filteredCount = ref.watch(filteredProductsProvider).length;
  return ProductCount(filtered: filteredCount, total: totalCount);
});