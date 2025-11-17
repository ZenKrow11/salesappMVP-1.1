// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
import '../models/product.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref);
});

class FirestoreService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(this._ref);

  // =======================================================================
  // PRIVATE HELPERS
  // =======================================================================

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

  DocumentReference _userDocRef() =>
      _firestore.collection('users').doc(_getUid());

  CollectionReference _shoppingListsRef() =>
      _userDocRef().collection('shoppingLists');

  CollectionReference _listedProductIdsRef() =>
      _userDocRef().collection('listedProductIds');

  CollectionReference _customItemsRef() =>
      _userDocRef().collection('customItems');

  // =======================================================================
  // USER PROFILE MANAGEMENT
  // =======================================================================

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

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _userDocRef().set(data, SetOptions(merge: true));
  }

  // =======================================================================
  // SHOPPING LIST MANAGEMENT
  // =======================================================================

  Future<void> createNewList({required String listName}) async {
    await _shoppingListsRef().doc().set({
      'name': listName,
      'createdAt': FieldValue.serverTimestamp(),
      'itemCount': 0,
    });
  }

  Future<void> updateShoppingListName(
      {required String listId, required String newName}) async {
    await _shoppingListsRef().doc(listId).update({'name': newName});
  }

  Future<void> deleteList({required String listId}) async {
    final listDocRef = _shoppingListsRef().doc(listId);
    final itemsSnapshot = await listDocRef.collection('items').get();
    final itemIds = itemsSnapshot.docs.map((doc) => doc.id).toList();

    if (itemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _firestore.runTransaction((transaction) async {
      for (final itemId in itemIds) {
        final indexDocRef = _listedProductIdsRef().doc(itemId);
        final indexSnapshot = await transaction.get(indexDocRef);

        if (indexSnapshot.exists) {
          final count = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
          if (count <= 1) {
            transaction.delete(indexDocRef);
          } else {
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }
      transaction.delete(listDocRef);
    });
  }

  Future<DocumentSnapshot> getShoppingListDocument(String listId) async {
    return _shoppingListsRef().doc(listId).get();
  }

  // =======================================================================
  // LIST ITEM MANAGEMENT (REFACTORED)
  // =======================================================================

  Future<void> addItemToList({
    required String listId,
    required String productId,
    Map<String, dynamic>? productData,
  }) async {
    final listDocRef = _shoppingListsRef().doc(listId);
    final itemDocRef = listDocRef.collection('items').doc(productId);
    final indexDocRef = _listedProductIdsRef().doc(productId);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemDocRef);
      if (itemSnapshot.exists) {
        return;
      }

      final dataToSet = {
        'id': productId,
        'isCustom': productData != null,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
        if (productData != null) ...productData,
      };

      transaction.set(itemDocRef, dataToSet);
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(1)});
      transaction.set(indexDocRef, {'count': FieldValue.increment(1)}, SetOptions(merge: true));
    });
  }

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
        final count = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
        if (count <= 1) {
          transaction.delete(indexDocRef);
        } else {
          transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
        }
      }
    });
  }

  Future<void> removeItemsFromList({
    required String listId,
    required List<String> productIds,
  }) async {
    if (productIds.isEmpty) return;
    final listDocRef = _shoppingListsRef().doc(listId);

    await _firestore.runTransaction((transaction) async {
      // --- FIX START ---
      // We separate the transaction into a READ phase and a WRITE phase.

      // PHASE 1: READ ALL NECESSARY DATA FIRST
      final List<DocumentSnapshot> indexSnapshots = [];
      for (final productId in productIds) {
        final indexDocRef = _listedProductIdsRef().doc(productId);
        // Read each document and store the result.
        final indexSnapshot = await transaction.get(indexDocRef);
        indexSnapshots.add(indexSnapshot);
      }

      // PHASE 2: PERFORM ALL WRITES NOW THAT READING IS COMPLETE
      for (int i = 0; i < productIds.length; i++) {
        final productId = productIds[i];
        final indexSnapshot = indexSnapshots[i];

        // Delete the item from the list's subcollection
        final itemDocRef = listDocRef.collection('items').doc(productId);
        transaction.delete(itemDocRef);

        // Update the global listedProductIds count
        if (indexSnapshot.exists) {
          final indexDocRef = indexSnapshot.reference; // Use reference from the snapshot
          final count = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
          if (count <= 1) {
            // If this was the last list the item was on, delete the index doc
            transaction.delete(indexDocRef);
          } else {
            // Otherwise, just decrement the count
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }

      // Finally, update the total item count on the list document itself
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(-productIds.length)});
      // --- FIX END ---
    });
  }

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

  Future<void> addCustomItemToStorage(Product customItem) async {
    await _customItemsRef().doc(customItem.id).set(customItem.toJson());
  }

  Future<void> updateCustomItemInStorage(Product customItem) async {
    await _customItemsRef().doc(customItem.id).update(customItem.toJson());
  }

  Future<void> deleteCustomItemFromStorage(String customItemId) async {
    await _customItemsRef().doc(customItemId).delete();
  }

  // =======================================================================
  // STREAM GETTERS
  // =======================================================================

  Stream<Set<String>> getListedProductIdsStream() {
    try {
      return _listedProductIdsRef()
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
    } catch (_) {
      return Stream.value({});
    }
  }

  Stream<List<ShoppingListInfo>> getAllShoppingListsStream() {
    try {
      return _shoppingListsRef()
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ShoppingListInfo.fromFirestore(doc))
          .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> getShoppingListItemsStream(
      {required String listId}) {
    try {
      return _shoppingListsRef().doc(listId).collection('items').snapshots().map(
              (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

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