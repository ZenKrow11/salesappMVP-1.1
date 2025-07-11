// lib/services/hive_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';

/// A service layer that handles all direct database interactions with Hive
/// for both favorites and shopping lists.
class HiveStorageService {
  final Box<Product> _favoritesBox;
  final Box<NamedList> _namedListsBox;

  HiveStorageService({
    required Box<Product> favoritesBox,
    required Box<NamedList> namedListsBox,
  })  : _favoritesBox = favoritesBox,
        _namedListsBox = namedListsBox;

  // --- Favorites Methods ---

  List<Product> getFavorites() => _favoritesBox.values.toList();
  bool isFavorite(String productId) => _favoritesBox.containsKey(productId);
  Future<void> toggleFavorite(Product product) async {
    if (_favoritesBox.containsKey(product.id)) {
      await _favoritesBox.delete(product.id);
    } else {
      await _favoritesBox.put(product.id, product);
    }
  }

  // --- Shopping List Methods (NOW COMPLETE) ---

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