// lib/providers/home_page_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the UI state for the HomePage.

/// The single source of truth for the index of the category
/// currently at the top of the HomePage's scroll view.
final currentCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

// This provider will hold the unique display names of the categories that are expanded.
final expandedCategoriesProvider = StateProvider<Set<String>>((ref) {
  // It starts as an empty set, meaning all categories are collapsed by default.
  return {};
});