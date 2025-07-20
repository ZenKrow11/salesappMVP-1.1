// lib/providers/search_suggestion_provider.dart

import 'package:flutter/foundation.dart'; // IMPORTANT: Import for `compute`
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

// =========================================================================
// === NEW: HELPERS FOR BACKGROUND SEARCH
// =========================================================================

/// A helper class to bundle the data needed for the background search isolate.
class _SearchInput {
  final List<Product> products;
  final String query;

  _SearchInput({required this.products, required this.query});
}

/// This function will be executed in a separate isolate to generate search suggestions.
/// It contains the exact same logic as your old provider.
List<String> _generateSuggestionsInBackground(_SearchInput input) {
  debugPrint("[ISOLATE] Generating search suggestions for query: '${input.query}'...");

  final allProducts = input.products;
  final lowerCaseQuery = input.query.toLowerCase();
  final suggestions = <String>{}; // Use a Set to handle duplicates automatically.

  // Strategy 1: Check if product name contains the query.
  for (final product in allProducts) {
    if (product.name.toLowerCase().contains(lowerCaseQuery)) {
      suggestions.add(product.name);
    }
    // Strategy 2: Check if any search keyword starts with the query.
    for (final keyword in product.searchKeywords) {
      if (keyword.toLowerCase().startsWith(lowerCaseQuery)) {
        suggestions.add(product.name);
        break; // Move to next product once a keyword match is found
      }
    }
  }

  // Return the top 5 suggestions to keep the list clean.
  return suggestions.take(5).toList();
}


// =========================================================================
// === REFACTORED ASYNC SEARCH PROVIDER
// =========================================================================

/// Generates search suggestions asynchronously based on a user's query.
/// This is now a FutureProvider, so it returns an AsyncValue.
final searchSuggestionsProvider =
FutureProvider.autoDispose.family<List<String>, String>((ref, query) async {
  // Don't bother searching for very short queries.
  if (query.length < 2) {
    return [];
  }

  // Watch the master list of products.
  final allProductsAsyncValue = ref.watch(initialProductsProvider);
  final allProducts = allProductsAsyncValue.value ?? [];

  // If the main product list isn't even loaded yet, we can't search.
  if (allProducts.isEmpty) {
    return [];
  }

  // As before, convert HiveObjects to plain objects before sending to the isolate.
  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();

  // Bundle the data into our helper class.
  final input = _SearchInput(products: plainProducts, query: query);

  // Run the search logic in the background.
  return compute(_generateSuggestionsInBackground, input);
});