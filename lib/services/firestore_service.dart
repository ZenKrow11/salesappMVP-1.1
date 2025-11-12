// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart'; // To get the auth provider
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
import '../models/product.dart';

/// Provides an instance of FirestoreService to the app.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref);
});

/// A service class to handle all interactions with Cloud Firestore.
///
/// This class centralizes database logic, making it easier to manage and test.
/// It handles user profiles, shopping lists, and custom items.
class FirestoreService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(this._ref);

  // =======================================================================
  // PRIVATE HELPERS
  // =======================================================================

  /// Centralized method to get the current user's UID.
  /// Throws a specific exception if the user is not authenticated.
  String _getUid() {
    final uid = _ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User not authenticated. Operation cannot proceed.',
      );
    }
    return uid;
  }

  /// Reference to the current user's document.
  DocumentReference _userDocRef() =>
      _firestore.collection('users').doc(_getUid());

  /// Reference to the `shoppingLists` subcollection for the current user.
  CollectionReference _shoppingListsRef() =>
      _userDocRef().collection('shoppingLists');

  /// Reference to the `listedProductIds` subcollection for the current user.
  CollectionReference _listedProductIdsRef() =>
      _userDocRef().collection('listedProductIds');

  /// Reference to the `customItems` subcollection for the current user.
  CollectionReference _customItemsRef() =>
      _userDocRef().collection('customItems');

  // =======================================================================
  // USER PROFILE MANAGEMENT
  // =======================================================================

  /// Creates a user profile document if one doesn't already exist.
  /// Called during the sign-up process.
  Future<void> createUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isPremium: false,
      );
      await userRef.set(profile.toFirestore());
    }
  }

  /// Updates the current user's profile with the provided data.
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _userDocRef().set(data, SetOptions(merge: true));
  }

  // =======================================================================
  // SHOPPING LIST MANAGEMENT
  // =======================================================================

  /// Creates a new shopping list with a given name.
  Future<void> createNewList({required String listName}) async {
    await _shoppingListsRef().doc().set({
      'name': listName,
      'createdAt': FieldValue.serverTimestamp(),
      'itemCount': 0,
    });
  }

  /// Updates the name of a specific shopping list.
  Future<void> updateShoppingListName(
      {required String listId, required String newName}) async {
    await _shoppingListsRef().doc(listId).update({'name': newName});
  }

  /// Deletes an entire shopping list and all its items.
  /// This is a complex operation that involves:
  /// 1. Deleting all items in the `items` subcollection.
  /// 2. Atomically updating the `listedProductIds` index.
  /// 3. Deleting the list document itself.
  Future<void> deleteList({required String listId}) async {
    final listDocRef = _shoppingListsRef().doc(listId);
    final itemsSnapshot = await listDocRef.collection('items').get();
    final itemIds = itemsSnapshot.docs.map((doc) => doc.id).toList();

    // Batch delete all items for efficiency.
    if (itemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Run a transaction to safely update the index and delete the list.
    await _firestore.runTransaction((transaction) async {
      for (final itemId in itemIds) {
        final indexDocRef = _listedProductIdsRef().doc(itemId);
        final indexSnapshot = await transaction.get(indexDocRef);

        if (indexSnapshot.exists) {
          final count = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
          if (count <= 1) {
            transaction.delete(indexDocRef); // Last one, delete the index.
          } else {
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }
      transaction.delete(listDocRef); // Finally, delete the list doc.
    });
  }

  // =======================================================================
  // LIST ITEM MANAGEMENT
  // =======================================================================

  /// Adds a product to a specific shopping list.
  Future<void> addItemToList({
    required String listId,
    required String productId,
    Map<String, dynamic>? productData,
  }) async {
    final listDocRef = _shoppingListsRef().doc(listId);
    final itemDocRef = listDocRef.collection('items').doc(productId);
    final indexDocRef = _listedProductIdsRef().doc(productId);

    final dataToSet = productData ?? {};
    dataToSet['addedAt'] = FieldValue.serverTimestamp();
    dataToSet['quantity'] = 1; // Always set a default quantity.

    final batch = _firestore.batch()
      ..set(itemDocRef, dataToSet)
      ..set(indexDocRef, {'count': FieldValue.increment(1)}, SetOptions(merge: true))
      ..update(listDocRef, {'itemCount': FieldValue.increment(1)});

    await batch.commit();
  }

  /// Removes a single product from a shopping list.
  Future<void> removeItemFromList({
    required String listId,
    required String productId,
  }) async {
    final listDocRef = _shoppingListsRef().doc(listId);
    final itemDocRef = listDocRef.collection('items').doc(productId);
    final indexDocRef = _listedProductIdsRef().doc(productId);

    await _firestore.runTransaction((transaction) async {
      final indexSnapshot = await transaction.get(indexDocRef);

      transaction.delete(itemDocRef);
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(-1)});

      if (indexSnapshot.exists) {
        final count = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
        if (count <= 1) {
          transaction.delete(indexDocRef);
        } else {
          transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
        }
      }
    });
  }

  // =======================================================================
  // --- THIS IS THE CORRECTED METHOD ---
  // =======================================================================
  /// Removes a list of products from a shopping list (e.g., for purging or multi-select delete).
  /// This transaction is structured to perform all reads before all writes to comply with Firestore rules.
  Future<void> removeItemsFromList({
    required String listId,
    required List<String> productIds,
  }) async {
    if (productIds.isEmpty) return;

    final listDocRef = _shoppingListsRef().doc(listId);

    await _firestore.runTransaction((transaction) async {
      // PHASE 1: READ ALL DOCUMENTS FIRST
      // We will read all the necessary index documents and store their snapshots.
      final Map<String, DocumentSnapshot> indexSnapshots = {};
      for (final productId in productIds) {
        final indexDocRef = _listedProductIdsRef().doc(productId);
        indexSnapshots[productId] = await transaction.get(indexDocRef);
      }

      // PHASE 2: NOW PERFORM ALL WRITES
      // Since all reads are complete, we can now safely perform writes.
      for (final productId in productIds) {
        // Delete the item from the current shopping list.
        final itemDocRef = listDocRef.collection('items').doc(productId);
        transaction.delete(itemDocRef);

        // Use the snapshot we read in Phase 1 to decide how to handle the index.
        final indexSnapshot = indexSnapshots[productId]!;
        if (indexSnapshot.exists) {
          final indexDocRef = _listedProductIdsRef().doc(productId);
          final count = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
          if (count <= 1) {
            // This is the last list containing this item, so delete the index.
            transaction.delete(indexDocRef);
          } else {
            // Other lists still have this item, so just decrement the count.
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }

      // Finally, update the total item count on the main list document.
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(-productIds.length)});
    });
  }

  /// Updates the quantities for multiple items in a list using a batch write.
  Future<void> updateItemQuantitiesInList({
    required String listId,
    required Map<String, int> quantities,
  }) async {
    if (quantities.isEmpty) return;

    final listRef = _shoppingListsRef().doc(listId);
    final batch = _firestore.batch();

    quantities.forEach((productId, quantity) {
      final itemRef = listRef.collection('items').doc(productId);
      batch.update(itemRef, {'quantity': quantity});
    });

    await batch.commit();
  }

  // =======================================================================
  // CUSTOM ITEM MANAGEMENT
  // =======================================================================

  /// Creates or overwrites a custom item in the user's private storage.
  Future<void> addCustomItemToStorage(Product customItem) async {
    await _customItemsRef().doc(customItem.id).set(customItem.toJson());
  }

  /// Updates an existing custom item.
  Future<void> updateCustomItemInStorage(Product customItem) async {
    await _customItemsRef().doc(customItem.id).update(customItem.toJson());
  }

  /// Deletes a custom item from the user's private storage.
  Future<void> deleteCustomItemFromStorage(String customItemId) async {
    await _customItemsRef().doc(customItemId).delete();
  }

  // =======================================================================
  // STREAM GETTERS
  // =======================================================================

  /// Streams the set of all product IDs currently on any of the user's lists.
  Stream<Set<String>> getListedProductIdsStream() {
    try {
      return _listedProductIdsRef()
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
    } catch (_) {
      return Stream.value({}); // Return empty stream if user is not logged in.
    }
  }

  /// Streams a list of all shopping lists (metadata only).
  Stream<List<ShoppingListInfo>> getAllShoppingListsStream() {
    try {
      return _shoppingListsRef()
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ShoppingListInfo.fromFirestore(doc))
          .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Streams the items (as raw data maps) within a specific shopping list.
  Stream<List<Map<String, dynamic>>> getShoppingListItemsStream(
      {required String listId}) {
    try {
      return _shoppingListsRef().doc(listId).collection('items').snapshots().map(
              (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Inject the document ID into the map.
            return data;
          }).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Streams all custom items created by the user.
  Stream<List<Product>> getCustomItemsStream() {
    try {
      return _customItemsRef().snapshots().map((snapshot) => snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }
}