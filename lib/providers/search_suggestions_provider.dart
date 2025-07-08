import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

// --- MODIFIED: Changed from FutureProvider to Provider ---
final searchSuggestionsProvider = Provider.family<List<String>, String>((ref, query) {
  if (query.length < 2) {
    return [];
  }

  // 1. Watch the AsyncValue of the single source of truth.
  final allProductsAsync = ref.watch(allProductsProvider);

  // 2. Use .when() to handle the states synchronously. This is the correct pattern.
  return allProductsAsync.when(
    loading: () => [], // While products are loading, we have no suggestions.
    error: (err, stack) {
      return []; // If products failed to load, we have no suggestions.
    },
    data: (allProducts) {
      // 3. ONLY when we have data, we perform the filtering logic.
      final lowerCaseQuery = query.toLowerCase();
      final suggestions = <String>{};

      // Strategy 1: Check the product name directly.
      final nameMatches = allProducts
          .where((p) => p.name.toLowerCase().contains(lowerCaseQuery))
          .map((p) => p.name);
      suggestions.addAll(nameMatches);

      // Strategy 2: Check all keywords.
      for (final product in allProducts) {
        for (final keyword in product.searchKeywords) {
          if (keyword.startsWith(lowerCaseQuery)) {
            suggestions.add(product.name);
          }
        }
      }

      return suggestions.take(5).toList();
    },
  );
});