// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Create a class to hold all your settings ---
class SettingsState {
  final bool isGridView;
  final bool hideCheckedItemsInShoppingMode;

  // Constructor with default values
  SettingsState({
    this.isGridView = true, // Default to grid view
    this.hideCheckedItemsInShoppingMode = false, // Default to showing checked items
  });

  // copyWith method for easy, immutable updates
  SettingsState copyWith({
    bool? isGridView,
    bool? hideCheckedItemsInShoppingMode,
  }) {
    return SettingsState(
      isGridView: isGridView ?? this.isGridView,
      hideCheckedItemsInShoppingMode:
      hideCheckedItemsInShoppingMode ?? this.hideCheckedItemsInShoppingMode,
    );
  }
}

// --- Define keys for SharedPreferences ---
const String _isGridViewKey = 'isGridView';
const String _hideCheckedItemsKey = 'hide_checked_items_key';


/// Manages the state of all user-configurable settings.
class SettingsNotifier extends StateNotifier<SettingsState> {
  // Initialize with a default SettingsState object
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  // Load all saved settings from local storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isGridView: prefs.getBool(_isGridViewKey) ?? true,
      hideCheckedItemsInShoppingMode: prefs.getBool(_hideCheckedItemsKey) ?? false,
    );
  }

  // Toggle the grid/list view mode and save
  Future<void> toggleGridView() async {
    final newValue = !state.isGridView;
    state = state.copyWith(isGridView: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, newValue);
  }

  // Toggle the visibility of checked items and save
  Future<void> toggleHideCheckedItems() async {
    final newValue = !state.hideCheckedItemsInShoppingMode;
    state = state.copyWith(hideCheckedItemsInShoppingMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideCheckedItemsKey, newValue);
  }
}

/// The provider that allows the UI to interact with the SettingsNotifier.
/// The state of this provider is now a SettingsState object.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});