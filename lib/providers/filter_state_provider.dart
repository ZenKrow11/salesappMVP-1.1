// lib/providers/filter_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart';

// --- DEPRECATED ---
// This single global provider is being replaced by page-specific providers
// to decouple the filter states between the home page and the shopping list page.
/*
final filterStateProvider = StateProvider<FilterState>((ref) {
  return const FilterState();
});
*/


// --- NEW INDEPENDENT PROVIDERS ---

/// Manages the filter and sort state exclusively for the **HomePage**.
///
/// This provider holds the user's selections for searching, filtering by
/// store/category, and sorting the main product feed. It defaults to sorting
/// by "Discount: High-Low".
final homePageFilterStateProvider = StateProvider.autoDispose<FilterState>((ref) {
  return const FilterState(sortOption: SortOption.discountHighToLow);
});

/// Manages the filter and sort state exclusively for the **ShoppingListPage**.
///
/// This provider holds the user's selections for filtering by store/category
/// and sorting the items within their active shopping list. It defaults to sorting
/// alphabetically by "Store".
final shoppingListPageFilterStateProvider = StateProvider.autoDispose<FilterState>((ref) {
  return const FilterState(sortOption: SortOption.storeAlphabetical);
});