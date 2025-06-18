import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_provider.dart';

/// --- FILTER STATE PROVIDERS ---

// Store filter (can be expanded later if you want cascading logic from store)
final storeFilterProvider = StateNotifierProvider<StoreFilterNotifier, String?>((ref) {
  return StoreFilterNotifier(ref);
});

class StoreFilterNotifier extends StateNotifier<String?> {
  final Ref ref;
  StoreFilterNotifier(this.ref) : super(null);

  @override
  set state(String? value) {
    super.state = value;

    // When store changes, check if current subcategory is still valid
    _validateSubcategory();
  }

  void _validateSubcategory() {
    final allProducts = ref.read(productsProvider).maybeWhen(
      data: (products) => products,
      orElse: () => [],
    );
    final selectedCategory = ref.read(categoryFilterProvider);
    final validSubcategories = allProducts
        .where((p) =>
    (state == null || p.store == state) &&
        (selectedCategory == null || p.category == selectedCategory))
        .map((p) => p.subcategory)
        .toSet();

    final selectedSub = ref.read(subcategoryFilterProvider);
    if (selectedSub != null && !validSubcategories.contains(selectedSub)) {
      ref.read(subcategoryFilterProvider.notifier).state = null;
    }
  }
}

// Category filter with automatic subcategory validation
final categoryFilterProvider = StateNotifierProvider<CategoryFilterNotifier, String?>((ref) {
  return CategoryFilterNotifier(ref);
});

class CategoryFilterNotifier extends StateNotifier<String?> {
  final Ref ref;
  CategoryFilterNotifier(this.ref) : super(null);

  @override
  set state(String? value) {
    super.state = value;

    // When category changes, validate subcategory
    _validateSubcategory();
  }

  void _validateSubcategory() {
    final allProducts = ref.read(productsProvider).maybeWhen(
      data: (products) => products,
      orElse: () => [],
    );
    final selectedStore = ref.read(storeFilterProvider);
    final validSubcategories = allProducts
        .where((p) =>
    (selectedStore == null || p.store == selectedStore) &&
        (state == null || p.category == state))
        .map((p) => p.subcategory)
        .toSet();

    final selectedSub = ref.read(subcategoryFilterProvider);
    if (selectedSub != null && !validSubcategories.contains(selectedSub)) {
      ref.read(subcategoryFilterProvider.notifier).state = null;
    }
  }
}

// Subcategory filter (passive)
final subcategoryFilterProvider = StateProvider<String?>((ref) => null);


/// --- FILTER OPTION LIST PROVIDERS ---

// Store options
final storeListProvider = Provider<List<String>>((ref) {
  return ref.watch(productsProvider).maybeWhen(
    data: (products) {
      final stores = products.map((p) => p.store).toSet().toList()..sort();
      return stores;
    },
    orElse: () => [],
  );
});

// Category options
final categoryListProvider = Provider<List<String>>((ref) {
  return ref.watch(productsProvider).maybeWhen(
    data: (products) {
      final categories = products.map((p) => p.category).toSet().toList()..sort();
      return categories;
    },
    orElse: () => [],
  );
});

// Subcategory options filtered by selected category and store
final subcategoryListProvider = Provider<List<String>>((ref) {
  final selectedStore = ref.watch(storeFilterProvider);
  final selectedCategory = ref.watch(categoryFilterProvider);

  return ref.watch(productsProvider).maybeWhen(
    data: (products) {
      final subcategories = products
          .where((p) =>
      (selectedCategory == null || p.category == selectedCategory) &&
          (selectedStore == null || p.store == selectedStore))
          .map((p) => p.subcategory)
          .toSet()
          .toList()
        ..sort();
      return subcategories;
    },
    orElse: () => [],
  );
});
