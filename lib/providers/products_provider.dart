// lib/providers/products_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/filter_state.dart'; // Import the model from its new file
import 'filter_state_provider.dart'; // Import the provider that holds the state

// This class holds our list and pagination state
class ProductState {
  final List<Product> products;
  final bool isLoadingMore;
  final bool hasMore;

  ProductState({
    this.products = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// This provider fetches ALL products ONCE and caches them. It is correct.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  // Ensure the fromFirestore method is called correctly and safely
  return snapshot.docs
      .map((doc) => Product.fromFirestore(doc.id, doc.data()))
      .toList();
});

// --- CRITICAL FIX: The missing provider definition ---
// This is the main provider your UI will watch.
final productsProvider =
StateNotifierProvider.autoDispose<ProductsNotifier, AsyncValue<ProductState>>((ref) {
  // Watch the filter state. If it changes, this provider will automatically be
  // re-created, thus re-fetching data with the new filters.
  final filterState = ref.watch(filterStateProvider);
  return ProductsNotifier(filterState);
});

class ProductsNotifier extends StateNotifier<AsyncValue<ProductState>> {
  final FilterState _filterState;
  DocumentSnapshot? _lastDoc;
  static const int _limit = 20;

  ProductsNotifier(this._filterState) : super(const AsyncValue.loading()) {
    _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    try {
      final snapshot = await _buildQuery().limit(_limit).get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }

      state = AsyncValue.data(ProductState(
        products: products,
        hasMore: products.length == _limit,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (state.value?.isLoadingMore == true || state.value?.hasMore == false) return;

    state = AsyncValue.data(state.value!.copyWith(isLoadingMore: true));

    try {
      final snapshot = await _buildQuery().startAfterDocument(_lastDoc!).limit(_limit).get();
      final newProducts = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }

      final currentProducts = state.value!.products;

      state = AsyncValue.data(state.value!.copyWith(
        products: [...currentProducts, ...newProducts],
        isLoadingMore: false,
        hasMore: newProducts.length == _limit,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoadingMore: false));
      print("Error loading more: $e");
    }
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (_filterState.selectedStores.isNotEmpty) {
      query = query.where('store', whereIn: _filterState.selectedStores);
    }
    if (_filterState.selectedCategories.isNotEmpty) {
      query = query.where('category', whereIn: _filterState.selectedCategories);
    }
    // ... add subcategory and search filters here if needed

    switch (_filterState.sortOption) {
      case SortOption.priceLowToHigh:
        query = query.orderBy('currentPrice', descending: false);
        break;
      case SortOption.discountHighToLow:
        query = query.orderBy('discountPercentage', descending: true);
        break;
      case SortOption.alphabetical:
        query = query.orderBy('name', descending: false);
        break;
    }
    return query;
  }
}