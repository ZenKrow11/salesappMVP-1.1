import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';

/// A simple data class to hold product counts.
class ProductCount {
  final int filtered;
  final int total;

  ProductCount({required this.filtered, required this.total});
}

// =========================================================================
// === FETCHING & SYNCING
// =========================================================================

/// Top-level function that fetches products from Firestore and syncs with Hive.
Future<List<Product>> _fetchAndSyncProducts() async {
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

  return products;
}

// =========================================================================
// === PRODUCTS NOTIFIER
// =========================================================================

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final productsBox = Hive.box<Product>('products');

    // Firestore fetch in background, don't await
    _runFetchInBackground();

    // Return cached data immediately
    return productsBox.values.toList();
  }

  Future<void> _runFetchInBackground() async {
    final result = await AsyncValue.guard(_fetchAndSyncProducts);
    state = result;
  }

  /// Public refresh method for pull-to-refresh or manual reload
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_fetchAndSyncProducts);
    state = result;
  }
}

final productsProvider =
AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

// =========================================================================
// === FILTERED PRODUCTS PROVIDER
// =========================================================================

final filteredProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  final allProducts = ref.watch(productsProvider).value ?? [];
  final filter = ref.watch(filterStateProvider);

  if (allProducts.isEmpty || filter.isDefault) {
    return allProducts;
  }

  return allProducts.where((product) {
    if (filter.selectedStores.isNotEmpty &&
        !filter.selectedStores.contains(product.store)) return false;
    if (filter.selectedCategories.isNotEmpty &&
        !filter.selectedCategories.contains(product.category)) return false;
    if (filter.selectedSubcategories.isNotEmpty &&
        !filter.selectedSubcategories.contains(product.subcategory)) return false;
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final nameMatch = product.name.toLowerCase().contains(query);
      final keywordMatch =
      product.searchKeywords.any((k) => k.startsWith(query));
      if (!nameMatch && !keywordMatch) return false;
    }
    return true;
  }).toList();
});

// =========================================================================
// === PRODUCT COUNT PROVIDER
// =========================================================================

final productCountProvider = Provider.autoDispose<ProductCount>((ref) {
  final totalCount = ref.watch(productsProvider).value?.length ?? 0;
  final filteredCount = ref.watch(filteredProductsProvider).length;
  return ProductCount(filtered: filteredCount, total: totalCount);
});
