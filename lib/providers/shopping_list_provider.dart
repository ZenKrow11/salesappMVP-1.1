// lib/providers/shopping_list_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/named_list.dart';
import 'package:sales_app_mvp/models/product.dart';
// NEW: Import the new Firestore service
import 'package:sales_app_mvp/services/firestore_service.dart';
// REMOVED: No longer need hive_storage_service.dart
import 'package:sales_app_mvp/providers/storage_providers.dart'; // Still need for productsBox
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sales_app_mvp/providers/app_data_provider.dart'; // Ensure this is imported


// This constant remains useful.
const String merklisteListName = 'Merkliste';

//============================================================================
//  NEW: The "Bridge" Provider
//============================================================================
// This provider is the core of our new real-time system.
// It watches for the list of product IDs from Firestore, then fetches the full
// product details from your local Hive cache. The UI will listen to this.
final shoppingListWithDetailsProvider = StreamProvider<List<Product>>((ref) {
  // 1. Get the list of product IDs from Firestore in real-time.
  final firestoreService = ref.watch(firestoreServiceProvider);
  final idStream = firestoreService.getShoppingListItemsStream(listId: merklisteListName);

  // 2. Get access to your local product database (Hive box).
  final productsBox = ref.watch(productsBoxProvider);

  // 3. Transform the stream of IDs into a stream of full Product objects.
  return idStream.map((productIds) {
    return productIds
        .map((id) => productsBox.get(id)) // Look up each product by its ID
        .where((product) => product != null) // Filter out any nulls
        .cast<Product>()
        .toList();
  });
});


//============================================================================
//  REFACTORED: ShoppingListNotifier
//============================================================================
// The notifier's role changes. It no longer holds the state itself.
// It's now responsible for ACTIONS (adding/removing items) and managing
// initialization logic. The actual list data comes from the StreamProvider above.
class ShoppingListNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final Ref _ref;
  bool _isInitialized = false;

  // Note: The state is now `void` because the data is handled by the StreamProvider.
  ShoppingListNotifier(this._firestoreService, this._ref) : super(null);

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Pass the constant 'merklisteListName' as the parameter. This will now compile correctly.
    await _firestoreService.ensureDefaultListExists(listId: merklisteListName);

    await _ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);

    _isInitialized = true;
  }

  // MODIFIED: This action is now much simpler.
  // It just calls the Firestore service. The UI will update automatically
  // because it's listening to the `shoppingListWithDetailsProvider` stream.
  Future<void> addToList(Product product) async {
    // We don't need a listName parameter for the free tier.
    await _firestoreService.addItemToList(
      listId: merklisteListName,
      productId: product.id,
    );
  }

  // MODIFIED: Also simplified.
  Future<void> removeItemFromList(Product product) async {
    await _firestoreService.removeItemFromList(
      listId: merklisteListName,
      productId: product.id,
    );
  }

// NOTE: Methods like addEmptyList, deleteList, and reorderCustomLists
// are for the premium tier. We will implement their Firestore versions
// once this core free-tier logic is working perfectly.
}

//============================================================================
//  REFACTORED & FINAL: The Main Provider
//============================================================================
final shoppingListsProvider = StateNotifierProvider<ShoppingListNotifier, void>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final notifier = ShoppingListNotifier(firestoreService, ref);

  // NEW: This is the critical initialization logic, restored and adapted.
  // It listens for the main app data to be loaded before initializing the shopping list.
  ref.listen<AppDataState>(appDataProvider, (previous, next) {
    // When the app data status changes to 'loaded', we initialize our notifier.
    if (next.status == InitializationStatus.loaded) {
      notifier.initialize();
    }
  });

  // Also handle the case where the app data is ALREADY loaded when this provider is first created.
  final currentAppData = ref.read(appDataProvider);
  if (currentAppData.status == InitializationStatus.loaded) {
    notifier.initialize();
  }

  return notifier;
});


//============================================================================
//  UNCHANGED: ActiveListNotifier
//============================================================================
// This provider is perfect as-is. It manages UI state (which list is active)
// and doesn't need to change.
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