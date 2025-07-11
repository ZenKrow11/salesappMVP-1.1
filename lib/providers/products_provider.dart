import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart'; // Correct import
import 'package:sales_app_mvp/providers/filter_state_provider.dart';

class ProductCount {
  final int filtered;
  final int total;
  ProductCount({required this.filtered, required this.total});
}

// =========================================================================
//  DATA & ACTION PROVIDERS
// =========================================================================

/// Synchronously provides the current list of products from the local Hive cache.
final productsProvider = Provider<List<Product>>((ref) {
  final box = Hive.box<Product>('products');
  return box.values.toList();
});

/// Handles the action of fetching products from Firestore and updating the local cache.
final productFetchProvider = FutureProvider<void>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final products = snapshot.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();

    final productsBox = Hive.box<Product>('products');
    await productsBox.clear();
    await productsBox.addAll(products);

    ref.invalidate(productsProvider);
  } catch (e) {
    throw Exception('Failed to load product data. Please check your connection.');
  }
});

// =========================================================================
//  DERIVED PROVIDERS
// =========================================================================

/// Filters the product list based on the current filter state.
final filteredProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  final filter = ref.watch(filterStateProvider);
  final allProducts = ref.watch(productsProvider);

  List<Product> filteredList = allProducts;

  if (filter.selectedStores.isNotEmpty) {
    filteredList = filteredList.where((p) => filter.selectedStores.contains(p.store)).toList();
  }
  if (filter.selectedCategories.isNotEmpty) {
    filteredList = filteredList.where((p) => filter.selectedCategories.contains(p.category)).toList();
  }
  if (filter.selectedSubcategories.isNotEmpty) {
    filteredList = filteredList.where((p) => filter.selectedSubcategories.contains(p.subcategory)).toList();
  }
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    filteredList = filteredList.where((p) {
      final nameMatch = p.name.toLowerCase().contains(query);
      final keywordMatch = p.searchKeywords.any((k) => k.startsWith(query));
      return nameMatch || keywordMatch;
    }).toList();
  }

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
});

/// Calculates the total and filtered product counts based on the current state.
final productCountProvider = Provider.autoDispose<ProductCount>((ref) {
  final totalCount = ref.watch(productsProvider).length;
  final filteredCount = ref.watch(filteredProductsProvider).length;
  return ProductCount(filtered: filteredCount, total: totalCount);
});