// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import '../models/product.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

class FirestoreService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreService(this._auth, this._firestore);

  String? get _uid => _auth.currentUser?.uid;

  // Update user profile document
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Firestore collection shortcuts
  CollectionReference _shoppingListsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('shoppingLists');

  CollectionReference _listedProductIdsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('listedProductIds');

  CollectionReference _customItemsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('customItems');

  Future<void> addItemToList({
    required String listId,
    required String productId,
    Map<String, dynamic>? productData,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final listDocRef = _shoppingListsRef(uid).doc(listId).collection('items').doc(productId);
    final indexDocRef = _listedProductIdsRef(uid).doc(productId);

    final batch = _firestore.batch();
    final dataToSet = productData ?? {'addedAt': FieldValue.serverTimestamp()};
    batch.set(listDocRef, dataToSet);
    batch.set(indexDocRef, {'count': FieldValue.increment(1)}, SetOptions(merge: true));
    await batch.commit();
  }

  // Remove an item from a shopping list
  Future<void> removeItemFromList({
    required String listId,
    required String productId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final listDocRef = _shoppingListsRef(uid).doc(listId).collection('items').doc(productId);
    final indexDocRef = _listedProductIdsRef(uid).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final indexSnapshot = await transaction.get(indexDocRef);
      transaction.delete(listDocRef);
      if (indexSnapshot.exists) {
        final currentCount = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
        if (currentCount <= 1) {
          transaction.delete(indexDocRef);
        } else {
          transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
        }
      }
    });
  }

  // Delete a full shopping list
  Future<void> deleteList({required String listId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final listDocRef = _shoppingListsRef(uid).doc(listId);
    final listItemsColRef = listDocRef.collection('items');

    final listItemsSnapshot = await listItemsColRef.get();
    final itemIds = listItemsSnapshot.docs.map((doc) => doc.id).toList();

    await _firestore.runTransaction((transaction) async {
      final indexRefs = itemIds.map((id) => _listedProductIdsRef(uid).doc(id)).toList();
      final indexSnapshots = await Future.wait(indexRefs.map((ref) => transaction.get(ref)));

      for (var i = 0; i < indexSnapshots.length; i++) {
        final indexSnapshot = indexSnapshots[i];
        final indexDocRef = indexRefs[i];
        if (indexSnapshot.exists) {
          final currentCount = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
          if (currentCount <= 1) {
            transaction.delete(indexDocRef);
          } else {
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }
      transaction.delete(listDocRef);
    });

    if (listItemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in listItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // Stream of all product IDs currently in lists
  Stream<Set<String>> getListedProductIdsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value({});
    return _listedProductIdsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  // Stream of all shopping lists
  Stream<List<ShoppingListInfo>> getAllShoppingListsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _shoppingListsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ShoppingListInfo.fromFirestore(doc)).toList();
    });
  }

  // Stream of all items in a list (live updates)
  Stream<List<Map<String, dynamic>>> getShoppingListItemsStream({required String listId}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    final collectionRef = _shoppingListsRef(uid).doc(listId).collection('items');
    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // NEW: One-time read of shopping list items (for item limit enforcement)
  Future<List<Map<String, dynamic>>> getShoppingListItemsOnce({required String listId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final snapshot =
    await _shoppingListsRef(uid).doc(listId).collection('items').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Create a new empty shopping list
  Future<void> createNewList({required String listName}) async {
    final uid = _uid;
    if (uid == null) return;
    final listRef = _shoppingListsRef(uid).doc(listName);
    await listRef.set({'createdAt': FieldValue.serverTimestamp()});
  }

  // Ensure default list exists (Merkliste)
  Future<void> ensureDefaultListExists({required String listId}) async {
    final uid = _uid;
    if (uid == null) return;
    final listRef = _shoppingListsRef(uid).doc(listId);
    final doc = await listRef.get();
    if (!doc.exists) {
      await listRef.set({
        'name': listId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Removes a list of product IDs from a specific shopping list in a batch.
  Future<void> removeItemsFromList({
    required String listId,
    required List<String> productIds,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    if (productIds.isEmpty) return;

    await _firestore.runTransaction((transaction) async {
      // --- PHASE 1: ALL READS FIRST ---
      // First, we gather all the document references for the index counters.
      final indexRefs = productIds
          .map((id) => _listedProductIdsRef(uid).doc(id))
          .toList();

      // Now, execute all the 'get' operations for these references.
      // This is the "read" phase of the transaction.
      final indexSnapshots = await Future.wait(
          indexRefs.map((ref) => transaction.get(ref))
      );

      // --- PHASE 2: ALL WRITES LAST ---
      // Now that all reads are complete, we can safely perform our writes.
      for (var i = 0; i < productIds.length; i++) {
        final productId = productIds[i];
        final indexSnapshot = indexSnapshots[i];

        // Queue the deletion from the specific shopping list.
        final listDocRef = _shoppingListsRef(uid).doc(listId).collection('items').doc(productId);
        transaction.delete(listDocRef);

        // Now, using the data we already read, decide whether to update or delete the index.
        if (indexSnapshot.exists) {
          final currentCount = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;

          if (currentCount <= 1) {
            // This item only exists in this one list, so delete the index document.
            transaction.delete(indexSnapshot.reference);
          } else {
            // This item exists in other lists, so just decrement the counter.
            transaction.update(indexSnapshot.reference, {'count': FieldValue.increment(-1)});
          }
        }
      }
    });
  }


  // CUSTOM ITEM STORAGE (Add / Read / Update / Delete)
  Future<void> addCustomItemToStorage(Product customItem) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _customItemsRef(uid).doc(customItem.id).set(customItem.toJson());
  }

  Stream<List<Product>> getCustomItemsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _customItemsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> updateCustomItemInStorage(Product customItem) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _customItemsRef(uid).doc(customItem.id).update(customItem.toJson());
  }

  Future<void> deleteCustomItemFromStorage(String customItemId) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _customItemsRef(uid).doc(customItemId).delete();
  }
}
