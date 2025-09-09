// lib/providers/home_page_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the UI state for the HomePage.

/// The single source of truth for the index of the category
/// currently at the top of the HomePage's scroll view.
final currentCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => 0);


// =========================================================================
// === NEW PAGINATION LOGIC
// =========================================================================

// The number of items to show in a collapsed category.
const int kCollapsedItemLimit = 20;
// The number of items to add with each press of "Show More".
const int kPaginationIncrement = 20;

/// This provider holds a map of {CategoryName: NumberOfItemsToShow}.
/// This is the new state management for the collapsible/paginated categories.
final categoryPaginationProvider = StateProvider<Map<String, int>>((ref) {
  // Starts as an empty map. The UI will use kCollapsedItemLimit as the default.
  return {};
});
