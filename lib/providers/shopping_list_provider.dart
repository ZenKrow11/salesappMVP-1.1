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

const String merklisteListName = 'Merkliste';

final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

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
      if (itemData['isCustom'] == true) {
        return Product.fromFirestore(itemData['id'], itemData);
      } else {
        return productsBox.get(itemData['id']);
      }
    })
        .where((product) => product != null)
        .cast<Product>()
        .toList();
  });
});

class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;
  bool _isInitialized = false;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _firestoreService.ensureDefaultListExists(listId: merklisteListName);
    if (_ref.read(activeShoppingListProvider) == null) {
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

final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, void>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final notifier = ShoppingListNotifier(firestoreService, ref);

  // This is the key. When a user logs in, we guarantee initialization runs.
  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
    final user = next.value;
    if (user != null) {
      // The initialize method will now handle setting the default active list.
      notifier.initialize();
    }
  });

  return notifier;
});

class ActiveListNotifier extends StateNotifier<String?> {
  static const _activeListKey = 'active_shopping_list_key';

  // MODIFIED: We add a Ref to the constructor to access other providers
  final Ref _ref;

  ActiveListNotifier(this._ref) : super(null) {
    _loadInitial(); // Load the saved active list on startup
  }

  // NEW METHOD: Loads the last active list from storage
  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString(_activeListKey);
    if (savedList != null) {
      state = savedList;
    } else {
      // THIS IS THE CRITICAL FALLBACK
      // If no list was saved, we check if the default "Merkliste" exists.
      // This solves the race condition.
      final allLists = await _ref.read(allShoppingListsProvider.future);
      if (allLists.any((list) => list.id == merklisteListName)) {
        setActiveList(merklisteListName);
      }
    }
  }

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

// MODIFIED: We pass the 'ref' to the notifier
final activeShoppingListProvider =
StateNotifierProvider<ActiveListNotifier, String?>((ref) => ActiveListNotifier(ref));