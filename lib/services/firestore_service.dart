// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';

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

  CollectionReference _shoppingListsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('shoppingLists');

  CollectionReference _listedProductIdsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('listedProductIds');

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
        final currentCount = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
        if (currentCount <= 1) {
          transaction.delete(indexDocRef);
        } else {
          transaction.update(indexDocRef, {'count': FieldValue.increment(-1)});
        }
      }
    });
  }

  // ========== THIS IS THE CORRECTED METHOD THAT FIXES THE CRASH ==========
  Future<void> deleteList({required String listId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final listDocRef = _shoppingListsRef(uid).doc(listId);
    final listItemsColRef = listDocRef.collection('items');

    // Step 1: Read the list of items outside the transaction.
    final listItemsSnapshot = await listItemsColRef.get();
    final itemIds = listItemsSnapshot.docs.map((doc) => doc.id).toList();

    // Step 2: Run the transaction to update the global index and delete the list document.
    await _firestore.runTransaction((transaction) async {
      // --- PHASE 1: ALL READS ---
      // First, perform all the reads for every item's global index document.
      final indexRefs = itemIds.map((id) => _listedProductIdsRef(uid).doc(id)).toList();
      final indexSnapshots = await Future.wait(indexRefs.map((ref) => transaction.get(ref)));

      // --- PHASE 2: ALL WRITES ---
      // Now that all reads are complete, perform the logic and schedule all writes.
      for (var i = 0; i < indexSnapshots.length; i++) {
        final indexSnapshot = indexSnapshots[i];
        final indexDocRef = indexRefs[i];

        if (indexSnapshot.exists) {
          final currentCount = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
          if (currentCount <= 1) {
            transaction.delete(indexDocRef); // Schedule a delete
          } else {
            transaction.update(indexDocRef, {'count': FieldValue.increment(-1)}); // Schedule an update
          }
        }
      }
      // Finally, schedule the deletion of the list document itself.
      transaction.delete(listDocRef);
    });

    // Step 3 (Your excellent addition): After the transaction is successful,
    // clean up the subcollection items using a batched write. This is efficient and correct.
    if (listItemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in listItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
  // ====================================================================

  Stream<Set<String>> getListedProductIdsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value({});
    return _listedProductIdsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Stream<List<ShoppingListInfo>> getAllShoppingListsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _shoppingListsRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ShoppingListInfo.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getShoppingListItemsStream({required String listId}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    final collectionRef = _shoppingListsRef(uid).doc(listId).collection('items');
    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> createNewList({required String listName}) async {
    final uid = _uid;
    if (uid == null) return;
    final listRef = _shoppingListsRef(uid).doc(listName);
    await listRef.set({'createdAt': FieldValue.serverTimestamp()});
  }

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
}