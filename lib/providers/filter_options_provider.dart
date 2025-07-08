import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/models/filter_state.dart'; // <-- Add this import

/// Helper function (unchanged)
List<String> _getUniqueOptions(
    List<Product> products,
    String Function(Product) getField,
    ) {
  final options =
  products.map(getField).where((value) => value.isNotEmpty).toSet().toList();
  options.sort();
  return options;
}

/// storeOptionsProvider (unchanged)
final storeOptionsProvider = Provider<List<String>>((ref) {
  final asyncProducts = ref.watch(allProductsProvider);
  return asyncProducts.when(
    data: (products) => _getUniqueOptions(products, (p) => p.store),
    loading: () => [],
    error: (_, __) => [],
  );
});

// --- MODIFIED SECTION START ---

/// NEW: A family provider for categories that accepts a FilterState.
/// This contains the core logic that was previously in categoryOptionsProvider.
final categoryOptionsProviderFamily = Provider.family<List<String>, FilterState>((ref, filterState) {
  final asyncProducts = ref.watch(allProductsProvider);

  return asyncProducts.when(
    data: (products) {
      List<Product> relevantProducts = products;

      // If stores are selected, only show categories from products in those stores.
      if (filterState.selectedStores.isNotEmpty) {
        relevantProducts = products
            .where((p) => filterState.selectedStores.contains(p.store))
            .toList();
      }

      return _getUniqueOptions(relevantProducts, (p) => p.category);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// NEW: A family provider for subcategories that accepts a FilterState.
/// This contains the core logic that was previously in subcategoryOptionsProvider.
final subcategoryOptionsProviderFamily = Provider.family<List<String>, FilterState>((ref, filterState) {
  final asyncProducts = ref.watch(allProductsProvider);

  return asyncProducts.when(
    data: (products) {
      List<Product> relevantProducts = products;

      // Filter by selected stores first.
      if (filterState.selectedStores.isNotEmpty) {
        relevantProducts = relevantProducts
            .where((p) => filterState.selectedStores.contains(p.store))
            .toList();
      }

      // Then, filter by selected categories.
      if (filterState.selectedCategories.isNotEmpty) {
        relevantProducts = relevantProducts
            .where((p) => filterState.selectedCategories.contains(p.category))
            .toList();
      }

      return _getUniqueOptions(relevantProducts, (p) => p.subcategory);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});


/// MODIFIED: The original providers now just call their respective families
/// using the global filter state. This maintains backward compatibility.

final categoryOptionsProvider = Provider<List<String>>((ref) {
  final filterState = ref.watch(filterStateProvider);
  return ref.watch(categoryOptionsProviderFamily(filterState));
});

final subcategoryOptionsProvider = Provider<List<String>>((ref) {
  final filterState = ref.watch(filterStateProvider);
  return ref.watch(subcategoryOptionsProviderFamily(filterState));
});

// --- MODIFIED SECTION END ---