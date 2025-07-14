// lib/providers/shopping_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_app_mvp/models/named_list.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/services/hive_storage_service.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

const String merklisteListName = 'Merkliste';
// A list of wrongly named 'NamedList's to also migrate.
const List<String> _oldNamedListNames = ['Favorites', 'Merkzettel'];

class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;

  ShoppingListNotifier(this._storageService) : super([]) {
    _loadAndMigrateLists();
  }

  /// This function runs on startup. It performs a one-time data migration
  /// from the old `favorites` box and any incorrectly named lists into the
  /// standardized "Merkliste", then loads the final state.
  Future<void> _loadAndMigrateLists() async {
    // --- MIGRATION PART 1: From the old `favorites` Box ---
    // We access the box directly here just for the migration.
    final oldFavoritesBox = Hive.box<Product>('favorites');
    if (oldFavoritesBox.isNotEmpty) {
      print("MIGRATION: Old 'favorites' box found with items. Migrating to '$merklisteListName'...");

      // Ensure "Merkliste" exists.
      if (!_storageService.getShoppingLists().any((list) => list.name == merklisteListName)) {
        await _storageService.createShoppingList(merklisteListName, -1);
      }
      // Add all products from the old box to the new list.
      for (final product in oldFavoritesBox.values) {
        await _storageService.addToShoppingList(merklisteListName, product);
      }
      // Clear the old box to prevent this from running again.
      await oldFavoritesBox.clear();
      print("MIGRATION: Completed. Old 'favorites' box is now empty.");
    }

    // --- MIGRATION PART 2: From incorrectly named 'NamedList's ---
    for (final oldName in _oldNamedListNames) {
      final oldList = _storageService.getShoppingLists().where((l) => l.name == oldName).firstOrNull;
      if (oldList != null) {
        print("MIGRATION: Incorrectly named list '$oldName' found. Merging...");
        for(final product in oldList.items) {
          await _storageService.addToShoppingList(merklisteListName, product);
        }
        await _storageService.deleteShoppingList(oldName);
        print("MIGRATION: Merged and deleted '$oldName'.");
      }
    }

    // Ensure Merkliste always exists for new users
    if (!_storageService.getShoppingLists().any((list) => list.name == merklisteListName)) {
      await _storageService.createShoppingList(merklisteListName, -1);
    }

    // Finally, load the clean state.
    _loadLists();
  }

  void _loadLists() {
    state = _storageService.getShoppingLists();
  }

  Future<void> addEmptyList(String listName) async {
    final nonSpecialListCount = state.where((list) => list.name != merklisteListName).length;
    await _storageService.createShoppingList(listName, nonSpecialListCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    if (listName == merklisteListName) return;

    await _storageService.deleteShoppingList(listName);
    // Re-index remaining lists after deletion
    final remainingLists = _storageService.getShoppingLists()
        .where((list) => list.name != merklisteListName)
        .toList();
    await _storageService.reorderLists(remainingLists);
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

final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return ShoppingListNotifier(storageService);
});

// --- ACTIVE LIST PROVIDER (No changes needed) ---
class ActiveListNotifier extends StateNotifier<String?> {
  static const _activeListKey = 'active_shopping_list_key';
  ActiveListNotifier() : super(null) { _loadSavedActiveList(); }
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