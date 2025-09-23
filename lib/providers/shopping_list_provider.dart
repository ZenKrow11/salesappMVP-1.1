// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Make sure you import main.dart to get access to the new provider
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ======================= NEW PROVIDER ADDED =======================
final shoppingListViewModeProvider = StateProvider<bool>((ref) => true); // Default to Grid View
// ==================================================================

final listedProductIdsProvider = StreamProvider<Set<String>>((ref) {
  // FIXED: Watching the new validation provider
  final user = ref.watch(authValidationProvider).value;
  if (user == null) {
    return Stream.value({});
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});


const String merklisteListName = 'Merkliste';

final initializationProvider = FutureProvider<void>((ref) async {
  // FIXED: Watching the new validation provider's future
  final user = await ref.watch(authValidationProvider.future);
  if (user == null) {
    return;
  }
  await ref.read(shoppingListsProvider.notifier).initialize();
});

final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  // FIXED: Watching the new validation provider
  final authState = ref.watch(authValidationProvider);
  if (authState.value == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  // FIXED: Watching the new validation provider
  final user = ref.watch(authValidationProvider).value;
  final activeListId = ref.watch(activeShoppingListProvider);

  if (user == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  final productsBox = ref.watch(productsBoxProvider);

  final itemsStream =
  firestoreService.getShoppingListItemsStream(listId: activeListId);

  return itemsStream.map((itemMaps) {
    if (itemMaps.isEmpty) {
      return <Product>[];
    }

    return itemMaps
        .map((itemData) {
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



/// Notifier responsible for actions related to shopping lists.
class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;
  bool _isInitialized = false;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _firestoreService.ensureDefaultListExists(listId: merklisteListName);
    _isInitialized = true;
  }

  Future<void> createNewList(String listName) async {
    await _firestoreService.createNewList(listName: listName);
    await _ref.read(activeShoppingListProvider.notifier).setActiveList(listName);
  }

  Future<void> addToList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: product.id,
    );
  }

  Future<void> addToSpecificList(Product product, String listId) async {
    await _firestoreService.addItemToList(
      listId: listId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    );
  }

  Future<void> removeItemFromList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.removeItemFromList(
      listId: activeListId,
      productId: product.id,
    );
  }

  Future<void> addCustomItemToList(Product customProduct) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: customProduct.id,
      productData: customProduct.toJson(),
    );
  }
}

final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, void>((ref) {
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

final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String>((ref) => ActiveListNotifier());

final customItemsProvider = StreamProvider<List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCustomItemsStream();
});