import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

/// Generates search suggestions based on a user's query.
final searchSuggestionsProvider =
Provider.family<List<String>, String>((ref, query) {
  if (query.length < 2) {
    return [];
  }

  final allProducts = ref.watch(productsProvider);
  final lowerCaseQuery = query.toLowerCase();
  final suggestions = <String>{}; // Use a Set to handle duplicates automatically.

  // Strategy 1: Check if the product name contains the query.
  final nameMatches = allProducts
      .where((p) => p.name.toLowerCase().contains(lowerCaseQuery))
      .map((p) => p.name);
  suggestions.addAll(nameMatches);

  // Strategy 2: Check if any search keyword starts with the query.
  for (final product in allProducts) {
    for (final keyword in product.searchKeywords) {
      if (keyword.startsWith(lowerCaseQuery)) {
        suggestions.add(product.name);
      }
    }
  }

  // Return the top 5 suggestions.
  return suggestions.take(5).toList();
});