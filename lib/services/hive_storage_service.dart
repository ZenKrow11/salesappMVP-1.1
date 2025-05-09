import 'package:hive/hive.dart';
import '../models/product.dart';

class HiveStorageService {
  HiveStorageService._privateConstructor();
  static final HiveStorageService instance = HiveStorageService._privateConstructor();

  static const _favoritesBoxName = 'favorites';
  static const _shoppingListsBoxName = 'shoppingLists';

  late Box<Product> _favoritesBox;
  late Box _shoppingListsBox;

  Future<void> init() async {
    _favoritesBox = await Hive.openBox<Product>(_favoritesBoxName);
    _shoppingListsBox = await Hive.openBox(_shoppingListsBoxName);
    print('[HiveStorageService] Hive boxes initialized');
  }

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
  Map<String, List<Product>> getShoppingLists() {
    final lists = _shoppingListsBox.toMap().map(
          (key, value) => MapEntry(key as String, List<Product>.from(value)),
    );
    print('[ShoppingLists] Loaded ${lists.length} lists');
    return lists;
  }

  List<Product> getListByName(String listName) {
    final list = List<Product>.from(_shoppingListsBox.get(listName, defaultValue: []));
    print('[ShoppingLists] Retrieved list "$listName" with ${list.length} items');
    return list;
  }

  Future<void> createShoppingList(String listName) async {
    if (!_shoppingListsBox.containsKey(listName)) {
      await _shoppingListsBox.put(listName, <Product>[]);
      print('[ShoppingLists] Created empty list: $listName');
    }
  }

  Future<void> deleteShoppingList(String listName) async {
    await _shoppingListsBox.delete(listName);
    print('[ShoppingLists] Deleted list: $listName');
  }

  Future<void> addToShoppingList(String listName, Product product) async {
    final currentList = List<Product>.from(_shoppingListsBox.get(listName, defaultValue: []));
    final alreadyExists = currentList.any((p) => p.id == product.id);
    if (!alreadyExists) {
      currentList.add(product);
      await _shoppingListsBox.put(listName, currentList);
      print('[ShoppingLists] Added "${product.name}" to "$listName"');
    } else {
      print('[ShoppingLists] "${product.name}" already exists in "$listName"');
    }
  }

  Future<void> removeFromShoppingList(String listName, String productId) async {
    final currentList = List<Product>.from(_shoppingListsBox.get(listName, defaultValue: []));
    final newList = currentList.where((p) => p.id != productId).toList();
    await _shoppingListsBox.put(listName, newList);
    print('[ShoppingLists] Removed product ID $productId from "$listName"');
  }
}
