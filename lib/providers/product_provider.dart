import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart'; // Make sure this path is correct

// This is the only provider your UI needs to interact with now.
final paginatedProductsProvider =
AsyncNotifierProvider<PaginatedProductsNotifier, List<Product>>(() {
  return PaginatedProductsNotifier();
});

class PaginatedProductsNotifier extends AsyncNotifier<List<Product>> {
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  static const int _limit = 250;

  // `build` is called automatically to get the first page.
  // Riverpod handles showing a loading spinner while this Future is running.
  @override
  Future<List<Product>> build() async {
    // We pass `fromInitialBuild: true` to reset the last document.
    return _fetchProducts(fromInitialBuild: true);
  }

  Future<List<Product>> _fetchProducts({DocumentSnapshot? lastDoc, bool fromInitialBuild = false}) async {
    if (fromInitialBuild) {
      _lastDoc = null;
    }

    // This is the core query logic from your old provider.
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('name') // It's crucial to have a consistent order for pagination
        .limit(_limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();

    // Update the last document reference for the next page.
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    } else {
      _lastDoc = null; // Reached the end
    }

    final products = snapshot.docs
        .map((doc) => Product.fromFirestore(doc.id, doc.data()))
        .toList();

    return products;
  }

  Future<void> loadMoreProducts() async {
    // If we're already loading or have reached the end, do nothing.
    if (_isLoadingMore || _lastDoc == null) {
      print("Skipping loadMore: isLoading=$_isLoadingMore, lastDocIsNull=${_lastDoc == null}");
      return;
    }

    _isLoadingMore = true;
    print("Loading more products...");

    // Get the currently displayed products.
    final currentProducts = state.value ?? [];

    // Fetch the next page.
    final newProducts = await _fetchProducts(lastDoc: _lastDoc);

    // Add the new products to the existing list and update the state.
    // This will cause the UI to rebuild with the full list.
    state = AsyncData([...currentProducts, ...newProducts]);

    _isLoadingMore = false;
    print("Finished loading more products. Total: ${state.value?.length}");
  }
}