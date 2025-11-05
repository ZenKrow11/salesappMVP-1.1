// lib/providers/home_page_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider remains the same
final currentCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

// Constants remain the same (20 items)
const int kCollapsedItemLimit = 20;
const int kPaginationIncrement = 20;

/// StateNotifier to manage the pagination state for each category.
class CategoryPaginationNotifier extends StateNotifier<Map<String, int>> {
  CategoryPaginationNotifier() : super({});

  /// Shows more items for a given category.
  void increase(String categoryKey) {
    final currentCount = state[categoryKey] ?? kCollapsedItemLimit;
    state = {...state, categoryKey: currentCount + kPaginationIncrement};
  }

  /// Resets the item count for a given category back to the initial collapsed state.
  void reset(String categoryKey) {
    state = {...state, categoryKey: kCollapsedItemLimit};
  }
}

/// Provider for the pagination logic.
final categoryPaginationProvider =
StateNotifierProvider<CategoryPaginationNotifier, Map<String, int>>((ref) {
  return CategoryPaginationNotifier();
});