// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/main.dart'; // Needed for authStateChangesProvider

// ======================= DEPRECATED PROVIDER =======================
final shoppingListViewModeProvider = StateProvider<bool>((ref) => true);
// ==================================================================

// --- This provider is unchanged ---
final listedProductIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value({});
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});

// --- This provider is now simpler ---
final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});


// === NEW ActiveListNotifier ===
final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>((ref) {
  final allListsAsync = ref.watch(allShoppingListsProvider);
  final firstListId = allListsAsync.whenOrNull(data: (lists) => lists.isNotEmpty ? lists.first.id : null);
  return ActiveListNotifier(ref, firstListId);
});

class ActiveListNotifier extends StateNotifier<String?> {
  final Ref _ref;

  ActiveListNotifier(this._ref, String? initialState) : super(initialState);

  void setActiveList(String listId) {
    state = listId;
  }

  void handleListDeletion(String deletedListId) {
    if (state == deletedListId) {
      final allLists = _ref.read(allShoppingListsProvider).value ?? [];
      if (allLists.isNotEmpty) {
        state = allLists.first.id;
      } else {
        state = null;
      }
    }
  }
}


// --- This provider is MODIFIED ---
final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final activeListId = ref.watch(activeShoppingListProvider);

  if (user == null || activeListId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  final productsBox = ref.watch(productsBoxProvider);
  final itemsStream = firestoreService.getShoppingListItemsStream(listId: activeListId);

  return itemsStream.map((itemMaps) {
    if (itemMaps.isEmpty) return <Product>[];
    return itemMaps
        .map((itemData) {
      if (itemData['isCustom'] == true) {
        return Product.fromFirestore(itemData['id'], itemData);
      } else {
        return productsBox.get(itemData['id']);
      }
    })
        .whereType<Product>()
        .toList();
  });
});


// --- This provider is unchanged ---
final filteredAndSortedShoppingListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
  final filterState = ref.watch(shoppingListPageFilterStateProvider);

  if (asyncShoppingList is! AsyncData<List<Product>>) {
    return asyncShoppingList;
  }

  final products = List<Product>.from(asyncShoppingList.value);
  List<Product> transformedList = List.from(products);

  if (filterState.selectedStores.isNotEmpty) {
    transformedList =
        transformedList.where((p) => filterState.selectedStores.contains(p.store)).toList();
  }

  if (filterState.selectedCategories.isNotEmpty) {
    transformedList =
        transformedList.where((p) => filterState.selectedCategories.contains(p.category)).toList();
  }

  transformedList.sort((a, b) {
    switch (filterState.sortOption) {
      case SortOption.priceLowToHigh:
        return a.normalPrice.compareTo(b.normalPrice);
      case SortOption.priceHighToLow:
        return b.normalPrice.compareTo(a.normalPrice);
      case SortOption.productAlphabetical:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortOption.storeAlphabetical:
        final storeCompare = a.store.toLowerCase().compareTo(b.store.toLowerCase());
        return storeCompare != 0
            ? storeCompare
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      default:
        return 0;
    }
  });

  return AsyncData(transformedList);
});

/// Notifier responsible for actions related to shopping lists.
class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  Future<void> createNewList(String listName) async {
    final isPremium = _ref.read(userProfileProvider).value?.isPremium ?? false;
    final currentListCount = _ref.read(allShoppingListsProvider).value?.length ?? 0;
    final limit = isPremium ? 6 : 2;

    if (currentListCount >= limit) {
      throw Exception('List limit reached. Upgrade to create more.');
    }
    await _firestoreService.createNewList(listName: listName);
  }

  // === NEW: Method to rename a list ===
  Future<void> renameList(String listId, String newName) async {
    // Call the firestore service to perform the update.
    // The `allShoppingListsProvider` is a StreamProvider, so it will automatically
    // reflect the change in the UI once the database is updated.
    await _firestoreService.updateShoppingListName(listId: listId, newName: newName);
  }

  Future<void> deleteList(String listId) async {
    await _firestoreService.deleteList(listId: listId);
    _ref.read(activeShoppingListProvider.notifier).handleListDeletion(listId);
  }

  Future<bool> _checkItemLimit(BuildContext context) async {
    final user = _ref.read(userProfileProvider).value;
    final isPremium = user?.isPremium ?? false;
    final limit = isPremium ? 60 : 30;

    final asyncShoppingList = _ref.read(shoppingListWithDetailsProvider);
    final currentList = asyncShoppingList.value ?? [];

    if (currentList.length >= limit) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('You’ve reached the item limit ($limit).'),
          duration: const Duration(seconds: 2),
        ));
      return false;
    }
    return true;
  }

  Future<void> addToList(Product product, BuildContext context) async {
    final canAdd = await _checkItemLimit(context);
    if (!canAdd) return;

    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) {
      return;
    }
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    );
  }

  Future<void> addToSpecificList(Product product, String listId, BuildContext context) async {
    final canAdd = await _checkItemLimit(context);
    if (!canAdd) return;

    await _firestoreService.addItemToList(
      listId: listId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    );
  }

  Future<void> updateCustomItem(Product product) async {
    await _firestoreService.updateCustomItemInStorage(product);
  }

  Future<void> createAndAddCustomItem(Product customProduct, BuildContext context) async {
    final canAdd = await _checkItemLimit(context);
    if (!canAdd) return;

    await _firestoreService.addCustomItemToStorage(customProduct);

    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) {
      return;
    }
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: customProduct.id,
      productData: customProduct.toJson(),
    );
  }

  Future<void> removeItemFromList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    await _firestoreService.removeItemFromList(
      listId: activeListId,
      productId: product.id,
    );
  }

  Future<void> purgeExpiredItems() async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    final asyncShoppingList = _ref.read(shoppingListWithDetailsProvider);
    if (asyncShoppingList.value == null) return;

    final expiredProductIds = asyncShoppingList.value!
        .where((product) => !product.isOnSale)
        .map((product) => product.id)
        .toList();

    if (expiredProductIds.isNotEmpty) {
      await _firestoreService.removeItemsFromList(
        listId: activeListId,
        productIds: expiredProductIds,
      );
    }
  }

  Future<void> clearActiveList() async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    final asyncShoppingList = _ref.read(shoppingListWithDetailsProvider);
    if (asyncShoppingList.value == null) return;

    final allProductIds = asyncShoppingList.value!
        .map((product) => product.id)
        .toList();

    if (allProductIds.isNotEmpty) {
      await _firestoreService.removeItemsFromList(
        listId: activeListId,
        productIds: allProductIds,
      );
    }
  }
}

final shoppingListsProvider =
StateNotifierProvider<ShoppingListNotifier, void>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingListNotifier(firestoreService, ref);
});

// --- This provider is unchanged ---
final customItemsProvider = StreamProvider<List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCustomItemsStream();
});