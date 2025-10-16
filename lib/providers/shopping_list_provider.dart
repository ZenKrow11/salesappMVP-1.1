// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ADDED IMPORTS FOR FILTERING AND SORTING ---
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';


// ======================= DEPRECATED PROVIDER =======================
// This provider is being replaced by the one in settings_provider.dart
// Keeping it here temporarily won't break anything, but it can be removed
// if you have fully migrated to the settings_provider.
final shoppingListViewModeProvider = StateProvider<bool>((ref) => true);
// ==================================================================


// --- No changes in the providers below ---
final listedProductIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value({});
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});


const String merklisteListName = 'Merkliste';

final initializationProvider = FutureProvider<void>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) {
    return;
  }
  await ref.read(shoppingListsProvider.notifier).initialize();
});

final allShoppingListsProvider = StreamProvider<List<ShoppingListInfo>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

// This provider remains the "source of truth" for the raw, unfiltered list
final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
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

// --- NEW DERIVED PROVIDER FOR THE UI ---
// This provider takes the raw list and applies the user's selected filters and sorting.
// The UI will watch this provider instead of the raw one.
final filteredAndSortedShoppingListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  // Watch the original list and the filter state
  final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
  final filterState = ref.watch(filterStateProvider);

  // Handle loading/error states from the original provider by passing them through.
  if (asyncShoppingList is! AsyncData<List<Product>>) {
    return asyncShoppingList;
  }

  // Once data is available, apply transformations
  final products = asyncShoppingList.value;
  List<Product> transformedList = List.from(products);

  // 1. APPLY STORE FILTER
  if (filterState.selectedStores.isNotEmpty) {
    transformedList = transformedList
        .where((p) => filterState.selectedStores.contains(p.store))
        .toList();
  }

  // --- NEW: APPLY CATEGORY FILTER ---
  if (filterState.selectedCategories.isNotEmpty) {
    transformedList = transformedList
        .where((p) => filterState.selectedCategories.contains(p.category))
        .toList();
  }

  // 2. APPLY SORTING
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
        // If stores are different, sort by store.
        if (storeCompare != 0) return storeCompare;
        // If stores are the same, sort by product name as a secondary criterion.
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    // Default case for discount etc., which aren't used in this bottom sheet
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

  /// Adds a product to the currently active shopping list.
  Future<void> addToList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    await _firestoreService.addItemToList(
      listId: activeListId,
      productId: product.id,
    );
  }

  /// Adds a product to a specific shopping list, identified by its ID.
  Future<void> addToSpecificList(Product product, String listId) async {
    await _firestoreService.addItemToList(
      listId: listId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    );
  }

  /// This method works implicitly on the active list.
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