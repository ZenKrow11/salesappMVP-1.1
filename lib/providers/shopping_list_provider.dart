// lib/providers/shopping_list_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sales_app_mvp/models/named_list.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/services/hive_storage_service.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/models/products_provider.dart';


const String merklisteListName = 'Merkliste';
const List<String> _oldNamedListNames = ['Favorites', 'Merkzettel'];

// --- UPDATED ShoppingListNotifier ---
class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;
  final Ref _ref;

  ShoppingListNotifier(this._storageService, this._ref) : super([]) {
    _loadAndMigrateLists();
  }

  /// This function runs on startup. It performs a one-time data migration
  /// and ensures that only currently existing products are in the lists.
  Future<void> _loadAndMigrateLists() async {
    // Wait for the master product list to be ready first.
    final allProducts = await _ref.read(initialProductsProvider.future);
    final allProductIds = allProducts.map((p) => p.id).toSet();

    // --- MIGRATION PART 1: From the old `favorites` Box ---
    final oldFavoritesBox = Hive.box<Product>('favorites');
    if (oldFavoritesBox.isNotEmpty) {
      print("MIGRATION: Old 'favorites' box found. Migrating...");
      if (!_storageService.getShoppingLists().any((list) => list.name == merklisteListName)) {
        await _storageService.createShoppingList(merklisteListName, -1);
      }
      for (final product in oldFavoritesBox.values) {
        if (allProductIds.contains(product.id)) {
          await _storageService.addToShoppingList(merklisteListName, product);
        }
      }
      await oldFavoritesBox.clear();
      print("MIGRATION: 'favorites' box migration complete.");
    }

    // --- MIGRATION PART 2: From incorrectly named 'NamedList's ---
    for (final oldName in _oldNamedListNames) {
      final oldList = _storageService.getShoppingLists().firstWhereOrNull((l) => l.name == oldName);
      if (oldList != null) {
        print("MIGRATION: Incorrectly named list '$oldName' found. Merging...");
        for (final product in oldList.items) {
          if (allProductIds.contains(product.id)) {
            await _storageService.addToShoppingList(merklisteListName, product);
          }
        }
        await _storageService.deleteShoppingList(oldName);
        print("MIGRATION: Merged and deleted '$oldName'.");
      }
    }

    // --- CORRECTED: Data Integrity Check ---
    final allLoadedLists = _storageService.getShoppingLists();
    for (final list in allLoadedLists) {
      final staleItems = list.items.where((item) => !allProductIds.contains(item.id)).toList();
      if (staleItems.isNotEmpty) {
        print("CLEANUP: Removing ${staleItems.length} stale products from '${list.name}'.");
        for (final staleItem in staleItems) {
          // Use the existing service method to remove stale items one by one.
          await _storageService.removeFromShoppingList(list.name, staleItem.id);
        }
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

  // --- No changes needed to the public methods below ---
  Future<void> addEmptyList(String listName) async {
    final nonSpecialListCount = state.where((list) => list.name != merklisteListName).length;
    await _storageService.createShoppingList(listName, nonSpecialListCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    if (listName == merklisteListName) return;
    await _storageService.deleteShoppingList(listName);
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

// --- UPDATED: Pass the Ref object to the notifier ---
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return ShoppingListNotifier(storageService, ref);
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