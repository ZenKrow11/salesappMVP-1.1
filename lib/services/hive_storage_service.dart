// lib/services/hive_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';

// It's just a normal class now. No more Singleton pattern!
class HiveStorageService {
  final Box<Product> _favoritesBox;
  final Box<NamedList> _namedListsBox;

  // The constructor now receives its dependencies (the open boxes) from Riverpod.
  HiveStorageService({
    required Box<Product> favoritesBox,
    required Box<NamedList> namedListsBox,
  })  : _favoritesBox = favoritesBox,
        _namedListsBox = namedListsBox;

  // --- ALL YOUR OTHER METHODS REMAIN EXACTLY THE SAME ---
  // They will now work on the _favoritesBox and _namedListsBox
  // instance variables passed in via the constructor.

  // --- Favorites ---
  List<Product> getFavorites() => _favoritesBox.values.toList();

  bool isFavorite(String productId) => _favoritesBox.containsKey(productId);

  Future<void> toggleFavorite(Product product) async {
    if (_favoritesBox.containsKey(product.id)) {
      await _favoritesBox.delete(product.id);
      print('[Favorites] Removed: ${product.name}');
    } else {
      await _favoritesBox.put(product.id, product);
      print('[Favorites] Added: ${product.name}');
    }
  }

  // --- Shopping Lists ---
  List<NamedList> getShoppingLists() {
    final lists = _namedListsBox.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    print('[ShoppingLists] Loaded ${lists.length} lists');
    return lists;
  }

// ... and so on for all your other service methods.
// No changes are needed for them.
}