// lib/providers/search_suggestions_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';

// --- MODIFICATION: This import is replaced ---
// import 'package:sales_app_mvp/models/products_provider.dart';
// --- With our new master provider ---
import 'package:sales_app_mvp/providers/app_data_provider.dart';


// --- All helper functions and classes below this line are UNCHANGED ---
class _SearchInput {
  final List<Product> products;
  final String query;

  _SearchInput({required this.products, required this.query});
}

List<String> _generateSuggestionsInBackground(_SearchInput input) {
  debugPrint("[ISOLATE] Generating search suggestions for query: '${input.query}'...");

  final allProducts = input.products;
  final lowerCaseQuery = input.query.toLowerCase();
  final suggestions = <String>{};

  for (final product in allProducts) {
    if (product.name.toLowerCase().contains(lowerCaseQuery)) {
      suggestions.add(product.name);
    }
    for (final keyword in product.nameTokens) {
      if (keyword.toLowerCase().startsWith(lowerCaseQuery)) {
        suggestions.add(product.name);
        break;
      }
    }
  }

  return suggestions.take(5).toList();
}

// =========================================================================
// === REFACTORED ASYNC SEARCH PROVIDER
// =========================================================================

final searchSuggestionsProvider =
FutureProvider.autoDispose.family<List<String>, String>((ref, query) async {
  if (query.length < 2) {
    return [];
  }

  // --- MODIFICATION: The data source is updated here ---
  // Watch the master app state.
  final appData = ref.watch(appDataProvider);
  // Get the product list directly from the state.
  final allProducts = appData.allProducts;
  // --- END MODIFICATION ---

  if (allProducts.isEmpty) {
    return [];
  }

  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();
  final input = _SearchInput(products: plainProducts, query: query);

  return compute(_generateSuggestionsInBackground, input);
});