// lib/services/hive_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';

/// A service layer that handles all direct database interactions with Hive
/// for named shopping lists. The old concept of a separate favorites box is removed.
class HiveStorageService {
  final Box<NamedList> _namedListsBox;

  // The constructor no longer requires a 'favoritesBox'.
  HiveStorageService({
    required Box<NamedList> namedListsBox,
  }) : _namedListsBox = namedListsBox;

  // --- All methods related to the old favoritesBox have been removed. ---

  // --- Shopping List Methods ---

  List<NamedList> getShoppingLists() {
    return _namedListsBox.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
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
    if (namedList != null && !namedList.items.any((p) => p.id == product.id)) {
      final updatedItems = [...namedList.items, product];
      await _namedListsBox.put(listName, namedList.copyWith(items: updatedItems));
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