// lib/providers/shopping_list_provider.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

import 'package:sales_app_mvp/models/named_list.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/services/hive_storage_service.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';

const String merklisteListName = 'Merkliste';
const List<String> _oldNamedListNames = ['Favorites', 'Merkzettel'];

class ShoppingListNotifier extends StateNotifier<List<NamedList>> {
  final HiveStorageService _storageService;
  final Ref _ref;
  bool _isInitialized = false;

  ShoppingListNotifier(this._storageService, this._ref) : super([]);

  // Add a getter to check initialization status
  bool get isInitialized => _isInitialized;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final appData = _ref.read(appDataProvider);
    if (appData.status == InitializationStatus.loaded) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final allProducts = _ref.read(appDataProvider).allProducts;
    final allProductIds = allProducts.map((p) => p.id).toSet();

    // Load lists first
    _loadLists();

    // Ensure Merkliste exists, using its special index of -1.
    if (!state.any((list) => list.name == merklisteListName)) {
      await _storageService.createShoppingList(merklisteListName, -1);
      _loadLists(); // Reload after creating Merkliste
    }

    final prefs = await SharedPreferences.getInstance();
    final savedListName = prefs.getString('active_shopping_list_key');
    final listExists = savedListName != null && state.any((l) => l.name == savedListName);

    if (listExists) {
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(savedListName);
    } else {
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
    }
  }

  void _loadLists() {
    state = _storageService.getShoppingLists();
  }

  Future<void> addEmptyList(String listName) async {
    await ensureInitialized();
    final nonSpecialListCount = state.where((list) => list.name != merklisteListName).length;
    await _storageService.createShoppingList(listName, nonSpecialListCount);
    _loadLists();
  }

  Future<void> deleteList(String listName) async {
    await ensureInitialized();
    if (listName == merklisteListName) return;

    final activeList = _ref.read(activeShoppingListProvider);
    await _storageService.deleteShoppingList(listName);

    if (activeList == listName) {
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
    }

    final remainingCustomLists = state
        .where((list) => list.name != merklisteListName && list.name != listName)
        .toList();

    await _storageService.reorderLists(remainingCustomLists);
    _loadLists();
  }

  Future<void> addToList(String listName, Product product) async {
    await ensureInitialized();
    if (listName == merklisteListName) {
      final merkliste = state.firstWhereOrNull((list) => list.name == merklisteListName);
      if (merkliste != null && merkliste.items.length >= 30 && !merkliste.items.any((p) => p.id == product.id)) {
        return;
      }
    }
    await _storageService.addToShoppingList(listName, product);
    _loadLists();
  }

  Future<void> removeItemFromList(String listName, Product product) async {
    await ensureInitialized();
    await _storageService.removeFromShoppingList(listName, product.id);
    _loadLists();
  }

  Future<void> reorderCustomLists(List<NamedList> reorderedCustomLists) async {
    await ensureInitialized();
    await _storageService.reorderLists(reorderedCustomLists);
    _loadLists();
  }
}

// Modified provider with better initialization handling
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, List<NamedList>>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  final notifier = ShoppingListNotifier(storageService, ref);

  // Listen to app data changes and initialize when ready
  ref.listen(appDataProvider, (previous, next) {
    if (next.status == InitializationStatus.loaded && !notifier.isInitialized) {
      // Use addPostFrameCallback to ensure this runs after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.initialize();
      });
    }
  });

  // Also try to initialize immediately if app is already loaded
  final currentAppData = ref.read(appDataProvider);
  if (currentAppData.status == InitializationStatus.loaded && !notifier.isInitialized) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.initialize();
    });
  }

  return notifier;
});

class ActiveListNotifier extends StateNotifier<String?> {
  static const _activeListKey = 'active_shopping_list_key';
  ActiveListNotifier() : super(null);

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

final activeShoppingListProvider = StateNotifierProvider<ActiveListNotifier, String?>((ref) => ActiveListNotifier());