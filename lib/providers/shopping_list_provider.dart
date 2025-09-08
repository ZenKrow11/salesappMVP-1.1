// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- NEW: This provider streams the Set of all globally listed product IDs. ---
final listedProductIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value({}); // Return an empty set if no user is logged in
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});


const String merklisteListName = 'Merkliste';

/// A single provider that manages all user-dependent startup logic.
/// The UI should wait for this to complete before building pages.
final initializationProvider = FutureProvider<void>((ref) async {
  // 1. Wait until Firebase Auth confirms if a user is logged in or not.
  final user = await ref.watch(authStateChangesProvider.future);

  // 2. If no user is logged in, there is nothing further to initialize.
  if (user == null) {
    return;
  }

  // 3. If a user is logged in, trigger and wait for the shopping list initialization to complete.
  // This guarantees that the default list exists and an active list is set before the UI loads.
  await ref.read(shoppingListsProvider.notifier).initialize();
});

/// Streams all shopping lists for the current authenticated user.
final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

/// Streams the product details for the currently active shopping list.
final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final activeListId = ref.watch(activeShoppingListProvider);

  if (user == null || activeListId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  final itemsStream = firestoreService.getShoppingListItemsStream(listId: activeListId);
  final productsBox = ref.watch(productsBoxProvider);

  return itemsStream.map((itemMaps) {
    return itemMaps.map((itemData) {
      // If the item data has the 'isCustom' flag, it's a private custom item.
      if (itemData['isCustom'] == true) {
        // Create the Product object directly from the Firestore data.
        return Product.fromFirestore(itemData['id'], itemData);
      } else {
        // Otherwise, it's a public sale item. Look it up in the local Hive cache.
        return productsBox.get(itemData['id']);
      }
    })
        .where((product) => product != null)
        .cast<Product>()
        .toList();
  });
});

/// Notifier responsible for actions related to shopping lists.
class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;
  bool _isInitialized = false;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  /// Ensures the default list exists and an active list is set.
  /// This is the main initialization logic called by the `initializationProvider`.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _firestoreService.ensureDefaultListExists(listId: merklisteListName);

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString(ActiveListNotifier._activeListKey);

    // If no active list was saved from a previous session, set "Merkliste" as the default.
    if (savedList == null) {
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
    }

    _isInitialized = true;
  }

  Future<void> createNewList(String listName) async {
    await _firestoreService.createNewList(listName: listName);
    await _ref.read(activeShoppingListProvider.notifier).setActiveList(listName);
  }

  Future<void> addToList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: product.id,
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

  Future<void> addCustomItemToList(Product customProduct) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: customProduct.id,
      productData: customProduct.toJson(),
    );
  }
}

/// The main provider for the ShoppingListNotifier.
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, void>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingListNotifier(firestoreService, ref);
});

/// Notifier that manages the state of the currently active shopping list.
class ActiveListNotifier extends StateNotifier<String?> {
  static const _activeListKey = 'active_shopping_list_key';

  ActiveListNotifier() : super(null) {
    _loadInitial();
  }

  /// Loads the last active list name from local storage on startup.
  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_activeListKey);
  }

  /// Sets the new active list and persists it to local storage.
  Future<void> setActiveList(String? listName) async {
    final prefs = await SharedPreferences.getInstance();
    if (listName == null) {
      await prefs.remove(_activeListKey);
    } else {
      await prefs.setString(_activeListKey, listName);
    }
    if (state != listName) {
      state = listName;
    }
  }
}

/// The provider for the ActiveListNotifier.
final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>((ref) => ActiveListNotifier());