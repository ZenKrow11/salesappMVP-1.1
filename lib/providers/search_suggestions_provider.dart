// lib/providers/search_suggestions_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';

// --- NO CHANGES NEEDED for these helper functions and classes ---
// They already correctly use `PlainProduct`.
class _SearchInput {
  final List<PlainProduct> products;
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

/// Provides search suggestions based on a query.
final searchSuggestionsProvider =
FutureProvider.autoDispose.family<List<String>, String>((ref, query) async {
  if (query.length < 2) {
    return [];
  }

  // --- FIX: Watch the new centralized provider. ---
  // This removes the redundant `.map((p) => p.toPlainObject())` call from this provider.
  final plainProducts = ref.watch(plainProductsProvider);
  if (plainProducts.isEmpty) {
    return [];
  }

  final input = _SearchInput(products: plainProducts, query: query);
  return compute(_generateSuggestionsInBackground, input);
});