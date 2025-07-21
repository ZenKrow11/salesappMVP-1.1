// lib/models/products_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'; // Add this import
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';

// You will need this part for the @riverpod annotation to work
part 'products_provider.g.dart';

// =========================================================================
// === DATA CLASS AND FETCH LOGIC (UNCHANGED)
// =========================================================================

class ProductCount {
  final int filtered;
  final int total;
  ProductCount({required this.filtered, required this.total});
}

// This function is now used by both the initial fetch and the refresher.
Future<List<Product>> _fetchAndSyncProducts() async {
  debugPrint("[SYNC] Starting Firestore fetch and Hive sync...");
  final snapshot = await FirebaseFirestore.instance.collection('products').get();

  final products = snapshot.docs
      .map((doc) => Product.fromFirestore(doc.id, doc.data()))
      .toList();

  final productsBox = Hive.box<Product>('products');
  final newProductsMap = {for (var p in products) p.id: p};

  final oldKeys = productsBox.keys.toSet();
  final keysToDelete = oldKeys.difference(newProductsMap.keys.toSet());

  await productsBox.deleteAll(keysToDelete);
  await productsBox.putAll(newProductsMap);

  debugPrint("[SYNC] Completed. Synced ${products.length} products.");
  return products;
}

// =========================================================================
// === NEW: STABLE "ONE-TIME" PRODUCT PROVIDER
// =========================================================================

/// This provider is responsible for the INITIAL fetch of products.
/// It fetches data once and then stays in the `data` state.
/// This prevents the "double load" flicker in the UI.
/// We use `keepAlive` so it doesn't get disposed and re-run needlessly.
@Riverpod(keepAlive: true)
Future<List<Product>> initialProducts(InitialProductsRef ref) async {
  // On first run, check if Hive has data. If so, return it immediately
  // to make the startup feel instant.
  final productsBox = Hive.box<Product>('products');
  if (productsBox.isNotEmpty) {
    debugPrint("[initialProducts] Returning ${productsBox.length} products from Hive cache immediately.");
    // Trigger a background sync, but don't wait for it. The user sees the
    // cached data instantly. The refresh logic will update the provider later.
    ref.read(productsRefresherProvider.notifier).refresh();
    return productsBox.values.toList();
  }

  // If Hive is empty (first-ever launch), perform the full fetch and wait for it.
  debugPrint("[initialProducts] Hive is empty. Performing first-time sync...");
  return _fetchAndSyncProducts();
}


// =========================================================================
// === NEW: ASYNC NOTIFIER for REFRESHING
// =========================================================================

/// This notifier is now ONLY for handling background refreshes.
/// The UI will not watch it directly. Its job is to perform an action.
@riverpod
class ProductsRefresher extends _$ProductsRefresher {
  @override
  Future<void> build() async {
    // No initial work needed here. It's an action-only provider.
    return;
  }

  /// Public refresh method for pull-to-refresh or background sync.
  Future<void> refresh() async {
    // Prevent multiple refreshes from running at the same time.
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    // When refreshing, re-run the fetch logic...
    await AsyncValue.guard(_fetchAndSyncProducts);

    // ...and then we invalidate the STABLE provider to make it re-fetch
    // and update the entire app with the new data. This is the key to a clean update.
    ref.invalidate(initialProductsProvider);

    // Set state back to data when done.
    state = const AsyncValue.data(null);
  }
}


// =========================================================================
// === DEPENDENT PROVIDERS (UPDATED)
// =========================================================================

// --- The helpers for background filtering are unchanged ---
class _FilterInput {
  final List<Product> products;
  final FilterState filter;
  _FilterInput({required this.products, required this.filter});
}
List<Product> _filterProductsInBackground(_FilterInput input) {
  // ... (this function's implementation is exactly the same)
  final allProducts = input.products;
  final filter = input.filter;
  debugPrint("[ISOLATE] Filtering running in background... Input: ${allProducts.length} products.");
  if (allProducts.isEmpty || filter.isDefault) {
    return allProducts;
  }
  return allProducts.where((product) {
    if (filter.selectedStores.isNotEmpty && !filter.selectedStores.contains(product.store)) return false;
    if (filter.selectedCategories.isNotEmpty && !filter.selectedCategories.contains(product.category)) return false;
    if (filter.selectedSubcategories.isNotEmpty && !filter.selectedSubcategories.contains(product.subcategory)) return false;
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final nameMatch = product.name.toLowerCase().contains(query);
      final keywordMatch = product.searchKeywords.any((k) => k.startsWith(query));
      if (!nameMatch && !keywordMatch) return false;
    }
    return true;
  }).toList();
}

// --- `filteredProductsProvider` is updated to use the new stable provider ---
final filteredProductsProvider =
FutureProvider.autoDispose<List<Product>>((ref) async {

  final stopwatch = Stopwatch()..start();
  debugPrint("[TIMER] filteredProductsProvider: START");

  // WATCH THE NEW STABLE PROVIDER
  final allProductsAsyncValue = ref.watch(initialProductsProvider);
  final filter = ref.watch(filterStateProvider);

  // When the stable provider is loading (only on first-ever app launch)
  if (allProductsAsyncValue.isLoading) {
    debugPrint("[TIMER] filteredProductsProvider: END (master list not ready) - took ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.stop();
    return [];
  }
  // If the stable provider has an error
  if (allProductsAsyncValue.hasError) {
    throw allProductsAsyncValue.error!;
  }

  final allProducts = allProductsAsyncValue.value!;

  if (allProducts.isEmpty) {
    debugPrint("[TIMER] filteredProductsProvider: END (empty) - took ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.stop();
    return [];
  }

  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();
  final input = _FilterInput(products: plainProducts, filter: filter);
  final result = await compute(_filterProductsInBackground, input);

  debugPrint("[TIMER] filteredProductsProvider: END - returned ${result.length} products in ${stopwatch.elapsedMilliseconds}ms");
  stopwatch.stop();

  return result;
});


// --- `productCountProvider` is updated to use the new stable provider ---
final productCountProvider = Provider.autoDispose<ProductCount>((ref) {
  // Use the new stable provider
  final totalCount = ref.watch(initialProductsProvider).value?.length ?? 0;
  final filteredCount = ref.watch(filteredProductsProvider).value?.length ?? 0;
  return ProductCount(filtered: filteredCount, total: totalCount);
});