import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/hive_storage_service.dart';

class ShoppingListNotifier extends StateNotifier<Map<String, List<Product>>> {
  ShoppingListNotifier() : super(HiveStorageService.instance.getShoppingLists()) {
    print('[Notifier] Initialized ShoppingListNotifier');
  }

  void addItemToList(String listName, Product product) async {
    print('[Notifier] Adding "${product.name}" to "$listName"...');
    await HiveStorageService.instance.addToShoppingList(listName, product);
    state = HiveStorageService.instance.getShoppingLists();
  }

  void removeItemFromList(String listName, Product product) async {
    print('[Notifier] Removing "${product.name}" from "$listName"...');
    await HiveStorageService.instance.removeFromShoppingList(listName, product.id);
    state = HiveStorageService.instance.getShoppingLists();
  }

  void addEmptyList(String listName) async {
    if (!state.containsKey(listName)) {
      print('[Notifier] Creating new list: $listName');
      await HiveStorageService.instance.createShoppingList(listName);
      state = HiveStorageService.instance.getShoppingLists();
    } else {
      print('[Notifier] List "$listName" already exists');
    }
  }

  void deleteList(String listName) async {
    print('[Notifier] Deleting list: $listName');
    await HiveStorageService.instance.deleteShoppingList(listName);
    state = HiveStorageService.instance.getShoppingLists();
  }

  List<String> getListNames() => state.keys.toList();
}

final shoppingListsProvider =
StateNotifierProvider<ShoppingListNotifier, Map<String, List<Product>>>(
      (ref) => ShoppingListNotifier(),
);
