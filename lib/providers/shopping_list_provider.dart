import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/named_list.dart';
import '../models/product.dart';

const String favoritesListName = 'Favorites';

class HiveStorageService {
  static final HiveStorageService instance = HiveStorageService._internal();
  final Box<NamedList> _namedListsBox = Hive.box<NamedList>('namedLists');

  HiveStorageService._internal();

  Map<String, NamedList> getShoppingLists() {
    final lists = _namedListsBox.toMap().cast<String, NamedList>();
    print('[ShoppingLists] Loaded ${lists.length} lists');
    return lists;
  }

  NamedList? getListByName(String listName) {
    final list = _namedListsBox.get(listName);
    print('[ShoppingLists] Retrieved list "$listName" with ${list?.items.length ?? 0} items');
    return list;
  }

  Future<void> createShoppingList(String listName, int index) async {
    if (!_namedListsBox.containsKey(listName)) {
      final newList = NamedList(name: listName, items: [], index: index);
      await _namedListsBox.put(listName, newList);
      print('[ShoppingLists] Created empty list: $listName');
    }
  }

  Future<void> deleteShoppingList(String listName) async {
    await _namedListsBox.delete(listName);
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
        print('[ShoppingLists] "${product.name}" already exists in "$listName"');
      }
    }
  }

  Future<void> removeFromShoppingList(String listName, String productId) async {
    final namedList = _namedListsBox.get(listName);
    if (namedList != null) {
      final updatedItems = namedList.items.where((p) => p.id != productId).toList();
      final updatedList = namedList.copyWith(items: updatedItems);
      await _namedListsBox.put(listName, updatedList);
      print('[ShoppingLists] Removed product ID $productId from "$listName"');
    }
  }

  Future<void> updateList(String listName, NamedList updatedList) async {
    await _namedListsBox.put(listName, updatedList);
    print('[ShoppingLists] Updated list: $listName');
  }

  Future<void> reorderLists(List<NamedList> lists) async {
    // Use a batch operation for better performance
    final batch = <Future<void>>[];

    for (int i = 0; i < lists.length; i++) {
      final list = lists[i];
      batch.add(_namedListsBox.put(list.name, list.copyWith(index: i)));
    }

    await Future.wait(batch);
    print('[ShoppingLists] Reordered lists');
  }
}

// --- Shopping Lists Notifier---

class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;

  ShoppingListNotifier(this._storageService) : super([]) {
    ensureFavoritesList(); // Ensure Favorites list on creation
    _loadLists(); // Load initial state
  }

  void _loadLists() {
    final map = _storageService.getShoppingLists();
    state = map.values.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  void ensureFavoritesList() {
    final map = _storageService.getShoppingLists();
    if (!map.containsKey(favoritesListName)) {
      _storageService.createShoppingList(favoritesListName, -1); // Modifies Hive box
      _loadLists(); // Updates state
      print('[ShoppingLists] Ensured Favorites list exists');
    }
  }

  Future<void> addEmptyList(String listName) async {
    final map = _storageService.getShoppingLists();
    final nonFavoritesCount = map.values.where((list) => list.name != favoritesListName).length;
    await _storageService.createShoppingList(listName, nonFavoritesCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    if (listName != favoritesListName) {
      // First delete the list
      await _storageService.deleteShoppingList(listName);

      // Now get the current state after deletion
      final currentLists = _storageService.getShoppingLists().values.toList();

      // Filter out favorites and sort by current index
      final nonFavoritesLists = currentLists
          .where((list) => list.name != favoritesListName)
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      // Reindex all non-favorites lists
      final updatedLists = <NamedList>[];
      for (int i = 0; i < nonFavoritesLists.length; i++) {
        updatedLists.add(nonFavoritesLists[i].copyWith(index: i));
      }

      // Save all reindexed lists
      await _storageService.reorderLists(updatedLists);

      // Reload the state to reflect changes
      _loadLists();
    }
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

final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>(
      (ref) => ShoppingListNotifier(HiveStorageService.instance),
);