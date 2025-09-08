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