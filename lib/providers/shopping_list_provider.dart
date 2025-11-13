// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:flutter/widgets.dart'; // --- FIX: Replaced implementation import ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/main.dart';

part 'shopping_list_provider.freezed.dart';

// =========================================================================
// SECTION 1: DATA STREAM PROVIDERS
// =========================================================================

final listedProductIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getListedProductIdsStream();
});

final allShoppingListsProvider = StreamProvider.autoDispose<List<ShoppingListInfo>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllShoppingListsStream();
});

class ActiveListNotifier extends StateNotifier<String?> {
  final Ref _ref;
  ProviderSubscription? _listsSubscription;

  ActiveListNotifier(this._ref) : super(null) {
    _initialize();
  }

  void _initialize() {
    _listsSubscription = _ref.listen<AsyncValue<List<ShoppingListInfo>>>(
      allShoppingListsProvider,
          (previous, next) {
        final lists = next.value ?? [];
        if (lists.isEmpty) {
          state = null;
          return;
        }
        final currentListExists = state != null && lists.any((list) => list.id == state);
        if (!currentListExists) {
          state = lists.first.id;
        }
      },
      fireImmediately: true,
    );
  }

  void setActiveList(String listId) {
    state = listId;
  }

  void handleListDeletion(String deletedListId) {
    if (state == deletedListId) {
      final allLists = _ref.read(allShoppingListsProvider).value ?? [];
      state = allLists.isNotEmpty ? allLists.first.id : null;
    }
  }

  @override
  void dispose() {
    _listsSubscription?.close();
    super.dispose();
  }
}

final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>((ref) {
  return ActiveListNotifier(ref);
});

final shoppingListWithDetailsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final activeListId = ref.watch(activeShoppingListProvider);
  if (activeListId == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  final productsBox = ref.watch(productsBoxProvider);
  final itemsStream = firestoreService.getShoppingListItemsStream(listId: activeListId);

  return itemsStream.map((itemMaps) {
    return itemMaps.map((itemData) {
      final product = itemData['isCustom'] == true
          ? Product.fromFirestore(itemData['id'], itemData)
          : productsBox.get(itemData['id']);
      return product?.copyWith(quantity: itemData['quantity'] as int? ?? 1);
    }).whereType<Product>().toList();
  });
});

final filteredAndSortedShoppingListProvider = Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
  final filterState = ref.watch(shoppingListPageFilterStateProvider);
  return asyncShoppingList.whenData((products) {
    List<Product> transformedList = List.from(products);
    if (filterState.selectedStores.isNotEmpty) {
      transformedList = transformedList.where((p) => filterState.selectedStores.contains(p.store)).toList();
    }
    if (filterState.selectedCategories.isNotEmpty) {
      transformedList = transformedList.where((p) => filterState.selectedCategories.contains(p.category)).toList();
    }
    transformedList.sort((a, b) {
      switch (filterState.sortOption) {
        case SortOption.priceLowToHigh: return a.currentPrice.compareTo(b.currentPrice);
        case SortOption.priceHighToLow: return b.currentPrice.compareTo(a.currentPrice);
        case SortOption.productAlphabetical: return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.storeAlphabetical:
          final storeCompare = a.store.toLowerCase().compareTo(b.store.toLowerCase());
          return storeCompare != 0 ? storeCompare : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        default: return 0;
      }
    });
    return transformedList;
  });
});

final customItemsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCustomItemsStream();
});


// =========================================================================
// SECTION 2: ACTION NOTIFIER
// =========================================================================

@freezed
class ShoppingListActionState with _$ShoppingListActionState {
  const factory ShoppingListActionState.initial() = _Initial;
  const factory ShoppingListActionState.loading() = _Loading;
  const factory ShoppingListActionState.success(String message) = _Success;
  const factory ShoppingListActionState.error(String error) = _Error;
}

class ShoppingListNotifier extends StateNotifier<ShoppingListActionState> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  bool _isDisposed = false;

  ShoppingListNotifier(this._firestoreService, this._ref) : super(const ShoppingListActionState.initial());

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> _performAction(Future<void> Function() action, {String? successMessage}) async {
    state = const ShoppingListActionState.loading();
    try {
      await action();
      if (_isDisposed) return true;
      state = ShoppingListActionState.success(successMessage ?? 'Success!');
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      state = ShoppingListActionState.error(e.toString());
      return false;
    }
  }

  Future<void> createNewList(String listName) async {
    final isPremium = _ref.read(userProfileProvider).value?.isPremium ?? false;
    final listCount = _ref.read(allShoppingListsProvider).value?.length ?? 0;
    final limit = isPremium ? 6 : 2;
    if (listCount >= limit) {
      state = const ShoppingListActionState.error('List limit reached. Upgrade to create more.');
      return;
    }
    await _performAction(() => _firestoreService.createNewList(listName: listName), successMessage: 'List "$listName" created.');
  }

  Future<void> renameList(String listId, String newName) async {
    await _performAction(() => _firestoreService.updateShoppingListName(listId: listId, newName: newName), successMessage: 'List renamed to "$newName".');
  }

  Future<void> deleteList(String listId) async {
    final success = await _performAction(() => _firestoreService.deleteList(listId: listId), successMessage: 'List deleted.');
    if (success && !_isDisposed) {
      _ref.read(activeShoppingListProvider.notifier).handleListDeletion(listId);
    }
  }

  Future<void> addToList(Product product) async {
    if (!_isItemLimitOk()) return;
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) {
      state = const ShoppingListActionState.error('No active list selected.');
      return;
    }
    await _performAction(() => _firestoreService.addItemToList(
      listId: activeListId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    ), successMessage: '"${product.name}" added to list.');
  }

  Future<void> addToSpecificList(Product product, String listId) async {
    if (!_isItemLimitOk()) return;
    final listName = _ref.read(allShoppingListsProvider).value?.firstWhere((info) => info.id == listId,
        orElse: () => ShoppingListInfo(id: '', name: 'list', itemCount: 0)
    ).name ?? 'list';

    await _performAction(() => _firestoreService.addItemToList(
      listId: listId,
      productId: product.id,
      productData: product.isCustom ? product.toJson() : null,
    ), successMessage: '"${product.name}" added to $listName');
  }

  Future<void> updateCustomItem(Product product) async {
    await _performAction(() => _firestoreService.updateCustomItemInStorage(product), successMessage: 'Custom item updated.');
  }

  Future<void> createAndAddCustomItem(Product customProduct) async {
    if (!_isItemLimitOk()) return;
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) {
      state = const ShoppingListActionState.error('No active list selected.');
      return;
    }
    await _performAction(() async {
      await _firestoreService.addCustomItemToStorage(customProduct);
      await _firestoreService.addItemToList(
        listId: activeListId,
        productId: customProduct.id,
        productData: customProduct.toJson(),
      );
    }, successMessage: 'Custom item created and added to list.');
  }

  Future<void> updateItemQuantities(Map<String, int> updatedQuantities) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    try {
      await _firestoreService.updateItemQuantitiesInList(listId: activeListId, quantities: updatedQuantities);
    } catch (e) {
      // --- FIX: Replaced print with debugPrint ---
      debugPrint('Silent error saving quantities: $e');
    }
  }

  Future<void> removeItemFromList(Product product) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    await _performAction(() => _firestoreService.removeItemFromList(listId: activeListId, productId: product.id));
  }

  Future<void> removeItemsFromList(Set<String> productIds) async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) {
      state = const ShoppingListActionState.error('No active list to remove items from.');
      return;
    }
    if (productIds.isEmpty) return;

    final idsToRemove = productIds.toList();

    // --- FIX: Replaced print with debugPrint ---
    debugPrint('ShoppingListNotifier received request to remove: $idsToRemove from list $activeListId');

    await _performAction(
          () async {
        try {
          await _firestoreService.removeItemsFromList(
            listId: activeListId,
            productIds: idsToRemove,
          );
        } catch (e) {
          // --- FIX: Replaced print with debugPrint ---
          debugPrint('!!! ERROR during bulk delete in FirestoreService: $e');
          // --- FIX: Use rethrow to preserve the stack trace ---
          rethrow;
        }
      },
      successMessage: '${idsToRemove.length} item(s) removed from the list.',
    );
  }

  Future<void> purgeExpiredItems() async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    final productList = _ref.read(shoppingListWithDetailsProvider).value;
    if (productList == null) return;
    final expiredIds = productList.where((p) => !p.isOnSale).map((p) => p.id).toList();
    if (expiredIds.isEmpty) {
      state = const ShoppingListActionState.success('No expired items to remove.');
      return;
    }
    await _performAction(() => _firestoreService.removeItemsFromList(listId: activeListId, productIds: expiredIds), successMessage: '${expiredIds.length} expired item(s) removed.');
  }

  Future<void> clearActiveList() async {
    final activeListId = _ref.read(activeShoppingListProvider);
    if (activeListId == null) return;
    final productList = _ref.read(shoppingListWithDetailsProvider).value;
    if (productList == null || productList.isEmpty) return;
    final allIds = productList.map((p) => p.id).toList();
    await _performAction(() => _firestoreService.removeItemsFromList(listId: activeListId, productIds: allIds), successMessage: 'All items cleared from list.');
  }

  bool _isItemLimitOk() {
    final isPremium = _ref.read(userProfileProvider).value?.isPremium ?? false;
    final limit = isPremium ? 60 : 30;
    final count = _ref.read(shoppingListWithDetailsProvider).value?.length ?? 0;
    if (count >= limit) {
      state = ShoppingListActionState.error('Item limit ($limit) reached.');
      return false;
    }
    return true;
  }
}

final shoppingListsProvider = StateNotifierProvider.autoDispose<ShoppingListNotifier, ShoppingListActionState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingListNotifier(firestoreService, ref);
});