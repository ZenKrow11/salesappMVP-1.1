import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';

// --- NEW CODE: ProductCount Data Class ---
class ProductCount {
  final int filtered;
  final int total;
  ProductCount({required this.filtered, required this.total});
}
// ------------------------------------------

final _firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final snapshot = await ref.watch(_firestoreProvider).collection('products').get();
  // V-- FIX #1 IS HERE --V
  return snapshot.docs.map((doc) {
    return Product.fromFirestore(doc.id, doc.data());
  }).toList();
  // ^----------------------^
});

// Helper function to build a Firestore query based on the current filter state.
Query _buildFilteredQuery({required Query query, required FilterState filter}) {
  if (filter.selectedStores.isNotEmpty) {
    query = query.where('store', whereIn: filter.selectedStores);
  }
  if (filter.selectedCategories.isNotEmpty) {
    query = query.where('category', whereIn: filter.selectedCategories);
  }
  if (filter.selectedSubcategories.isNotEmpty) {
    query = query.where('subcategory', whereIn: filter.selectedSubcategories);
  }
  if (filter.searchQuery.isNotEmpty) {
    query = query.where('searchKeywords', arrayContains: filter.searchQuery.toLowerCase());
  }
  return query;
}

// --- NEW CODE: Provider for getting product counts ---
final productCountProvider = FutureProvider.autoDispose<ProductCount>((ref) async {
  final filter = ref.watch(filterStateProvider);
  final collection = ref.watch(_firestoreProvider).collection('products');

  final totalCountQuery = collection.count();
  final filteredQueryWithWheres = _buildFilteredQuery(query: collection, filter: filter);
  final filteredCountQuery = filteredQueryWithWheres.count();

  final results = await Future.wait([
    totalCountQuery.get(),
    filteredCountQuery.get(),
  ]);

  final totalSnapshot = results[0];
  final filteredSnapshot = results[1];

  return ProductCount(
    total: totalSnapshot.count ?? 0,
    filtered: filteredSnapshot.count ?? 0,
  );
});

// --- CORRECTED: Provider for the filtered list of products. ---
final filteredProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final filter = ref.watch(filterStateProvider);
  final firestore = ref.watch(_firestoreProvider);
  Query query = firestore.collection('products');

  query = _buildFilteredQuery(query: query, filter: filter);

  switch (filter.sortOption) {
    case SortOption.storeAlphabetical:
      query = query.orderBy('store').orderBy('name');
      break;
    case SortOption.productAlphabetical:
      query = query.orderBy('name');
      break;
    case SortOption.priceHighToLow:
      query = query.orderBy('currentPrice', descending: true);
      break;
    case SortOption.priceLowToHigh:
      query = query.orderBy('currentPrice', descending: false);
      break;
    default:
      query = query.orderBy('store');
  }

  return query.snapshots().map((snapshot) {
    // V-- FIX #2 IS HERE --V
    return snapshot.docs.map((doc) {
      return Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
    // ^----------------------^
  });
});