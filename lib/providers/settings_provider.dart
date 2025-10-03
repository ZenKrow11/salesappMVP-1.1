// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The key we'll use to store the setting in SharedPreferences.
const String _isGridViewKey = 'isGridView';

/// Manages the state of user-configurable settings.
/// In this case, it only manages the list/grid view mode.
class SettingsNotifier extends StateNotifier<bool> {
  // Initialize with a default value (false = list view)
  SettingsNotifier() : super(false) {
    _loadSetting();
  }

  // Load the saved setting from local storage
  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved value, or default to false (list view) if it doesn't exist.
    state = prefs.getBool(_isGridViewKey) ?? false;
  }

  // Toggle the view mode and save the new preference
  Future<void> toggleView() async {
    state = !state; // Invert the current state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, state);
  }
}

/// The provider that allows the UI to interact with the SettingsNotifier.
/// The state of this provider is a boolean: `true` for Grid View, `false` for List View.
final settingsProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier();
});