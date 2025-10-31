// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';

// ======================= DEPRECATED PROVIDER =======================
final shoppingListViewModeProvider = StateProvider<bool>((ref) => true);
// ==================================================================

final listedProductIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value({});
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});

const String kDefaultListName = 'Shopping List'; // Changed from 'Merkliste'

final initializationProvider = FutureProvider<void>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return;
  await ref.read(shoppingListsProvider.notifier).initialize();
});

final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  ref.watch(initializationProvider);
  if (authState.value == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final activeListId = ref.watch(activeShoppingListProvider);
  if (user == null) return Stream.value([]);

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

final filteredAndSortedShoppingListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
  final filterState = ref.watch(shoppingListPageFilterStateProvider);

  if (asyncShoppingList is! AsyncData<List<Product>>) {
    return asyncShoppingList;
  }

  final products = List<Product>.from(asyncShoppingList.value);
  List<Product> transformedList = List.from(products);

  // Store filter
  if (filterState.selectedStores.isNotEmpty) {
    transformedList =
        transformedList.where((p) => filterState.selectedStores.contains(p.store)).toList();
  }

  // Category filter
  if (filterState.selectedCategories.isNotEmpty) {
    transformedList =
        transformedList.where((p) => filterState.selectedCategories.contains(p.category)).toList();
  }

  // Sorting
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

final String merklisteListName = kDefaultListName;

/// Notifier responsible for actions related to shopping lists.
class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  Future<void> initialize() async {
    try {
      // Use the constant directly for initialization
      await _firestoreService.ensureDefaultListExists(listId: kDefaultListName);
    } catch (e) {
      print("Error ensuring default list exists: $e");
    }
  }

  Future<void> createNewList(String listName) async {
    await _firestoreService.createNewList(listName: listName);
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

  // --- NEW METHOD FOR UPDATING AN EXISTING CUSTOM ITEM ---
  Future<void> updateCustomItem(Product product) async {
    await _firestoreService.updateCustomItemInStorage(product);
  }

  // --- NEW, CENTRALIZED METHOD FOR CREATING A CUSTOM ITEM ---
  Future<void> createAndAddCustomItem(Product customProduct, BuildContext context) async {
    // 1. Check the item limit first.
    final canAdd = await _checkItemLimit(context);
    if (!canAdd) return;

    // 2. Save the new item to the main 'customItems' collection.
    await _firestoreService.addCustomItemToStorage(customProduct);

    // 3. Add the new item's ID to the currently active shopping list.
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: customProduct.id,
      productData: customProduct.toJson(), // Pass the full data
    );
  }

  Future<void> removeItemFromList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.removeItemFromList(
      listId: activeListId,
      productId: product.id,
    );
  }

  /// Removes all products from the currently active list where isOnSale is false.
  Future<void> purgeExpiredItems() async {
    final activeListId = _ref.read(activeShoppingListProvider);
    final asyncShoppingList = _ref.read(shoppingListWithDetailsProvider);

    if (asyncShoppingList.value == null) return;

    final allProducts = asyncShoppingList.value!;
    final expiredProductIds = allProducts
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

  /// Removes ALL products from the currently active list.
  Future<void> clearActiveList() async {
    final activeListId = _ref.read(activeShoppingListProvider);
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

class ActiveListNotifier extends StateNotifier<String> {
  static const _activeListKey = 'active_shopping_list_key';

  ActiveListNotifier() : super(merklisteListName) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString(_activeListKey);
    if (savedList != null && savedList != state) {
      state = savedList;
    }
  }

  Future<void> setActiveList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeListKey, listName);
    if (state != listName) {
      state = listName;
    }
  }
}

final activeShoppingListProvider =
StateNotifierProvider<ActiveListNotifier, String>(
        (ref) => ActiveListNotifier());

final customItemsProvider = StreamProvider<List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCustomItemsStream();
});
