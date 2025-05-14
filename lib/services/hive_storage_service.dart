import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/named_list.dart';

class HiveStorageService {
  HiveStorageService._privateConstructor();

  static final HiveStorageService instance = HiveStorageService
      ._privateConstructor();

  static const _favoritesBoxName = 'favorites';
  static const _shoppingListsBoxName = 'shoppingLists';
  static const _namedListsBoxName = 'namedLists';

  late Box<Product> _favoritesBox;
  late Box _shoppingListsBox;
  late Box<NamedList> _namedListsBox;

  Future<void> init() async {
    _favoritesBox = await Hive.openBox<Product>(_favoritesBoxName);
    _shoppingListsBox = await Hive.openBox(_shoppingListsBoxName);
    _namedListsBox = await Hive.openBox<NamedList>(_namedListsBoxName);
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
  List<NamedList> getShoppingLists() {
    final lists = _namedListsBox.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    print('[ShoppingLists] Loaded ${lists.length} lists');
    return lists;
  }

  List<Product> getListByName(String listName) {
    final list = _namedListsBox
        .get(listName)
        ?.items ?? [];
    print(
        '[ShoppingLists] Retrieved list "$listName" with ${list.length} items');
    return list;
  }

  Future<void> createShoppingList(String listName) async {
    if (!_namedListsBox.containsKey(listName)) {
      final newList = NamedList(
        name: listName,
        items: [],
        index: _namedListsBox.values.length, // Assign next available index
      );
      await _namedListsBox.put(listName, newList);
      print('[ShoppingLists] Created empty list: $listName');
    }
  }

  Future<void> deleteShoppingList(String listName) async {
    await _namedListsBox.delete(listName);
    // Reindex remaining lists to maintain sequential indices
    final lists = _namedListsBox.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    for (int i = 0; i < lists.length; i++) {
      await _namedListsBox.put(lists[i].name, lists[i].copyWith(index: i));
    }
    print('[ShoppingLists] Deleted list: $listName');
  }

  Future<void> addToShoppingList(String listName, Product product) async {
    final namedList = _namedListsBox.get(listName);
    if (namedList != null) {
      final currentItems = namedList.items;
      final alreadyExists = currentItems.any((p) => p.id == product.id);
      if (!alreadyExists) {
        final updatedItems = [...currentItems, product];
        final updatedList = namedList.copyWith(items: updatedItems);
        await _namedListsBox.put(listName, updatedList);
        print('[ShoppingLists] Added "${product.name}" to "$listName"');
      } else {
        print(
            '[ShoppingLists] "${product.name}" already exists in "$listName"');
      }
    } else {
      print('[ShoppingLists] List "$listName" does not exist');
    }
  }

  Future<void> removeFromShoppingList(String listName, String productId) async {
    final namedList = _namedListsBox.get(listName);
    if (namedList != null) {
      final currentItems = namedList.items;
      final updatedItems = currentItems
          .where((p) => p.id != productId)
          .toList();
      final updatedList = namedList.copyWith(items: updatedItems);
      await _namedListsBox.put(listName, updatedList);
      print('[ShoppingLists] Removed product ID $productId from "$listName"');
    } else {
      print('[ShoppingLists] List "$listName" does not exist');
    }
  }
}