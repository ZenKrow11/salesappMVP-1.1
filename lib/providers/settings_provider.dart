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
  // --- FIX Start ---
  // 1. Add a flag to track if the notifier has been disposed.
  bool _isDisposed = false;
  // --- FIX End ---

  // Initialize with a default SettingsState object
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  // --- FIX Start ---
  // 2. Override the dispose method to update the flag.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  // --- FIX End ---


  // Load all saved settings from local storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // --- FIX Start ---
    // 3. Before setting state after an async gap, check if the notifier is still alive.
    if (_isDisposed) return;
    // --- FIX End ---

    state = state.copyWith(
      isGridView: prefs.getBool(_isGridViewKey) ?? true,
      hideCheckedItemsInShoppingMode: prefs.getBool(_hideCheckedItemsKey) ?? false,
    );
  }

  // Toggle the grid/list view mode and save
  Future<void> toggleGridView() async {
    // This method is safe as-is because the state is updated BEFORE the await.
    // This is known as an "optimistic update".
    final newValue = !state.isGridView;
    state = state.copyWith(isGridView: newValue);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, newValue);
  }

  // Toggle the visibility of checked items and save
  Future<void> toggleHideCheckedItems() async {
    // This method is also safe for the same reason (optimistic update).
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