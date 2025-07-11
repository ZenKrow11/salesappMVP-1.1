// lib/providers/shopping_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_app_mvp/models/named_list.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/services/hive_storage_service.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

const String favoritesListName = 'Favorites';

/// Notifier responsible for managing the state of all shopping lists.
/// It uses the injected `HiveStorageService` for all database operations.
class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;

  ShoppingListNotifier(this._storageService) : super([]) {
    _loadLists();
    _ensureFavoritesList();
  }

  void _loadLists() {
    state = _storageService.getShoppingLists();
  }

  void _ensureFavoritesList() {
    final currentLists = _storageService.getShoppingLists();
    if (!currentLists.any((list) => list.name == favoritesListName)) {
      _storageService.createShoppingList(favoritesListName, -1);
      _loadLists();
    }
  }

  Future<void> addEmptyList(String listName) async {
    final nonFavoritesCount = state.where((list) => list.name != favoritesListName).length;
    await _storageService.createShoppingList(listName, nonFavoritesCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    if (listName == favoritesListName) return;

    await _storageService.deleteShoppingList(listName);

    final remainingLists = _storageService.getShoppingLists()
        .where((list) => list.name != favoritesListName)
        .toList();

    final reindexedLists = <NamedList>[];
    for (int i = 0; i < remainingLists.length; i++) {
      reindexedLists.add(remainingLists[i].copyWith(index: i));
    }
    await _storageService.reorderLists(reindexedLists);
    _loadLists();
  }

  Future<void> addToList(String listName, Product product) async {
    await _storageService.addToShoppingList(listName, product);
    _loadLists();
  }

  Future<void> removeItemFromList(String listName, Product product) async {
    // --- TYPO FIX: Changed '_storageSrvice' to '_storageService' ---
    await _storageService.removeFromShoppingList(listName, product.id);
    _loadLists();
  }

  Future<void> reorderCustomLists(List<NamedList> reorderedLists) async {
    await _storageService.reorderLists(reorderedLists);
    _loadLists();
  }
}

/// Provides the `ShoppingListNotifier` instance to the app, ensuring it's only
/// created after the storage service is ready.
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return ShoppingListNotifier(storageService);
});

// =========================================================================
//  ACTIVE LIST PROVIDER (No changes needed)
// =========================================================================

class ActiveListNotifier extends StateNotifier<String?> {
  static const _activeListKey = 'active_shopping_list_key';

  ActiveListNotifier() : super(null) {
    _loadSavedActiveList();
  }

  Future<void> _loadSavedActiveList() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_activeListKey);
  }

  Future<void> setActiveList(String? listName) async {
    final prefs = await SharedPreferences.getInstance();
    if (listName == null) {
      await prefs.remove(_activeListKey);
    } else {
      await prefs.setString(_activeListKey, listName);
    }
    state = listName;
  }
}

final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>((ref) => ActiveListNotifier());