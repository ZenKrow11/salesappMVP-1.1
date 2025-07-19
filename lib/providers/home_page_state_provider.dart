// lib/providers/home_page_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the UI state for the HomePage.

/// The single source of truth for the index of the category
/// currently at the top of the HomePage's scroll view.
final currentCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => 0);