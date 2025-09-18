// lib/providers/search_suggestions_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sales_app_mvp/models/product.dart'; // No longer needed
import 'package:sales_app_mvp/models/plain_product.dart'; // <-- IMPORT PlainProduct
import 'package:sales_app_mvp/providers/app_data_provider.dart';


// --- FIX G: Update helper classes to use `PlainProduct` ---
class _SearchInput {
  final List<PlainProduct> products; // <-- TYPE CHANGE
  final String query;
  _SearchInput({required this.products, required this.query});
}

List<String> _generateSuggestionsInBackground(_SearchInput input) {
  debugPrint("[ISOLATE] Generating search suggestions for query: '${input.query}'...");

  final allProducts = input.products;
  final lowerCaseQuery = input.query.toLowerCase();
  final suggestions = <String>{};

  for (final product in allProducts) { // `product` is now a PlainProduct
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

// --- FIX H: (Error at line 65) Update the provider logic ---
final searchSuggestionsProvider =
FutureProvider.autoDispose.family<List<String>, String>((ref, query) async {
  if (query.length < 2) {
    return [];
  }

  final appData = ref.watch(appDataProvider);
  final allProducts = appData.allProducts;

  if (allProducts.isEmpty) {
    return [];
  }

  // This conversion to plain objects now happens once and is passed to the isolate
  final plainProducts = allProducts.map((p) => p.toPlainObject()).toList();
  final input = _SearchInput(products: plainProducts, query: query);

  return compute(_generateSuggestionsInBackground, input);
});