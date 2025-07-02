import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for persistence

import '../models/named_list.dart';
import '../models/product.dart';

// Note: Ensure you have `shared_preferences` in your pubspec.yaml
// dependencies:
//   shared_preferences: ^2.0.15

const String favoritesListName = 'Favorites';

// --- STORAGE SERVICE (No changes needed, this is well-structured) ---
// This class is responsible for all low-level communication with the Hive database.
class HiveStorageService {
  static final HiveStorageService instance = HiveStorageService._internal();
  final Box<NamedList> _namedListsBox = Hive.box<NamedList>('namedLists');

  HiveStorageService._internal();

  Map<String, NamedList> getShoppingLists() {
    return _namedListsBox.toMap().cast<String, NamedList>();
  }

  Future<void> createShoppingList(String listName, int index) async {
    if (!_namedListsBox.containsKey(listName)) {
      final newList = NamedList(name: listName, items: [], index: index);
      await _namedListsBox.put(listName, newList);
    }
  }

  Future<void> deleteShoppingList(String listName) async {
    await _namedListsBox.delete(listName);
  }

  Future<void> addToShoppingList(String listName, Product product) async {
    final namedList = _namedListsBox.get(listName);
    if (namedList != null) {
      if (!namedList.items.any((p) => p.id == product.id)) {
        final updatedItems = [...namedList.items, product];
        await _namedListsBox.put(listName, namedList.copyWith(items: updatedItems));
      }
    }
  }

  Future<void> removeFromShoppingList(String listName, String productId) async {
    final namedList = _namedListsBox.get(listName);
    if (namedList != null) {
      final updatedItems = namedList.items.where((p) => p.id != productId).toList();
      await _namedListsBox.put(listName, namedList.copyWith(items: updatedItems));
    }
  }

  Future<void> reorderLists(List<NamedList> lists) async {
    for (int i = 0; i < lists.length; i++) {
      final list = lists[i];
      await _namedListsBox.put(list.name, list.copyWith(index: i));
    }
  }
}

// --- SHOPPING LISTS NOTIFIER (No changes needed, this is well-structured) ---
// This notifier manages the state for the ENTIRE collection of shopping lists.
class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;

  ShoppingListNotifier(this._storageService) : super([]) {
    ensureFavoritesList();
    _loadLists();
  }

  void _loadLists() {
    final map = _storageService.getShoppingLists();
    state = map.values.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  void ensureFavoritesList() {
    if (!_storageService.getShoppingLists().containsKey(favoritesListName)) {
      _storageService.createShoppingList(favoritesListName, -1);
      _loadLists();
    }
  }

  Future<void> addEmptyList(String listName) async {
    final map = _storageService.getShoppingLists();
    final nonFavoritesCount = map.values.where((list) => list.name != favoritesListName).length;
    await _storageService.createShoppingList(listName, nonFavoritesCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    if (listName == favoritesListName) return;

    await _storageService.deleteShoppingList(listName);
    final nonFavoritesLists = _storageService
        .getShoppingLists()
        .values
        .where((list) => list.name != favoritesListName)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final reindexedLists = <NamedList>[];
    for (int i = 0; i < nonFavoritesLists.length; i++) {
      reindexedLists.add(nonFavoritesLists[i].copyWith(index: i));
    }

    await _storageService.reorderLists(reindexedLists);
    _loadLists();
  }

  Future<void> addToList(String listName, Product product) async {
    await _storageService.addToShoppingList(listName, product);
    _loadLists();
  }

  Future<void> removeItemFromList(String listName, Product product) async {
    await _storageService.removeFromShoppingList(listName, product.id);
    _loadLists();
  }

  Future<void> reorderCustomLists(List<NamedList> reorderedLists) async {
    await _storageService.reorderLists(reorderedLists);
    _loadLists();
  }
}

// --- MAIN PROVIDER for the list of lists ---
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>(
      (ref) => ShoppingListNotifier(HiveStorageService.instance),
);


// =========================================================================
// --- REFACTORED ACTIVE LIST NOTIFIER AND PROVIDER ---
// =========================================================================

// This notifier manages one simple piece of state: the name of the currently active list.
// It includes persistence logic to remember the user's choice across app restarts.
class ActiveListNotifier extends StateNotifier<String?> {
  // A unique key to save the data in SharedPreferences.
  static const _activeListKey = 'active_shopping_list_key';

  ActiveListNotifier() : super(null) {
    // When the notifier is created, immediately try to load the last saved value.
    _loadSavedActiveList();
  }

  // Asynchronous method to load the saved list name from device storage.
  Future<void> _loadSavedActiveList() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_activeListKey);
  }

  // The public method the UI will call. It updates the state in the app AND
  // saves the new value to device storage for the next session.
  Future<void> setActiveList(String? listName) async {
    final prefs = await SharedPreferences.getInstance();
    if (listName == null) {
      await prefs.remove(_activeListKey);
    } else {
      await prefs.setString(_activeListKey, listName);
    }
    // Update the in-memory state to instantly notify all listeners in the UI.
    state = listName;
  }
}

// This provider exposes the ActiveListNotifier and its state to the rest of the app.
// The UI will use this provider to read the active list name and to call `setActiveList`.
final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>(
      (ref) => ActiveListNotifier(),
);