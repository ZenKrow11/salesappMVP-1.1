// lib/providers/search_suggestion_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

/// Generates search suggestions based on a user's query.
final searchSuggestionsProvider =
Provider.autoDispose.family<List<String>, String>((ref, query) {
  if (query.length < 2) {
    return [];
  }

  // CHANGED: Read from the new central productsProvider.
  final allProducts = ref.watch(productsProvider).value ?? [];
  final lowerCaseQuery = query.toLowerCase();
  final suggestions = <String>{}; // Use a Set to handle duplicates automatically.

  // Strategy 1: Check if any search keyword starts with the query.
  // This is often more useful than a contains check for suggestions.
  for (final product in allProducts) {
    if (product.name.toLowerCase().contains(lowerCaseQuery)) {
      suggestions.add(product.name);
    }
    for (final keyword in product.searchKeywords) {
      if (keyword.toLowerCase().startsWith(lowerCaseQuery)) {
        suggestions.add(product.name);
        break; // Move to next product once a keyword match is found
      }
    }
  }

  // Return the top 5 suggestions.
  return suggestions.take(5).toList();
});