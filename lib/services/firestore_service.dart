// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart'; // To get the auth provider
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

  String? get _uid => _ref.read(authStateChangesProvider).value?.uid;

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
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  CollectionReference _shoppingListsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('shoppingLists');

  CollectionReference _listedProductIdsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('listedProductIds');

  CollectionReference _customItemsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('customItems');

  Future<void> createNewList({required String listName}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final listRef = _shoppingListsRef(uid).doc();
    await listRef.set({
      'name': listName,
      'createdAt': FieldValue.serverTimestamp(),
      // --- FIX #1: Initialize the itemCount field when a new list is created ---
      'itemCount': 0,
    });
  }

  // === THIS IS THE NEW METHOD YOU NEED TO ADD ===
  /// Updates the name of a specific shopping list.
  Future<void> updateShoppingListName(
      {required String listId, required String newName}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    await _shoppingListsRef(uid).doc(listId).update({'name': newName});
  }
  // ===============================================

  Future<void> deleteList({required String listId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final listDocRef = _shoppingListsRef(uid).doc(listId);
    final listItemsColRef = listDocRef.collection('items');

    final listItemsSnapshot = await listItemsColRef.get();
    final itemIds = listItemsSnapshot.docs.map((doc) => doc.id).toList();

    if (listItemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in listItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _firestore.runTransaction((transaction) async {
      final indexRefs =
      itemIds.map((id) => _listedProductIdsRef(uid).doc(id)).toList();
      final indexSnapshots =
      await Future.wait(indexRefs.map((ref) => transaction.get(ref)));

      for (var i = 0; i < indexSnapshots.length; i++) {
        final indexSnapshot = indexSnapshots[i];
        final indexDocRef = indexRefs[i];
        if (indexSnapshot.exists) {
          final currentCount =
              (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
          if (currentCount <= 1) {
            transaction.delete(indexDocRef);
          } else {
            transaction
                .update(indexDocRef, {'count': FieldValue.increment(-1)});
          }
        }
      }
      transaction.delete(listDocRef);
    });
  }

  Future<void> addItemToList({
    required String listId,
    required String productId,
    Map<String, dynamic>? productData,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final listDocRef = _shoppingListsRef(uid).doc(listId); // Reference to the parent list document
    final itemDocRef = listDocRef.collection('items').doc(productId); // Reference to the item in the subcollection
    final indexDocRef = _listedProductIdsRef(uid).doc(productId);

    final batch = _firestore.batch();

    final dataToSet = productData ?? {'addedAt': FieldValue.serverTimestamp()};
    batch.set(itemDocRef, dataToSet);
    batch.set(indexDocRef, {'count': FieldValue.increment(1)}, SetOptions(merge: true));

    // --- FIX #2: Atomically increment the itemCount on the parent document ---
    batch.update(listDocRef, {'itemCount': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> removeItemFromList({
    required String listId,
    required String productId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    final listDocRef = _shoppingListsRef(uid).doc(listId); // Reference to the parent list document
    final itemDocRef = listDocRef.collection('items').doc(productId); // Reference to the item in the subcollection
    final indexDocRef = _listedProductIdsRef(uid).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final indexSnapshot = await transaction.get(indexDocRef);

      transaction.delete(itemDocRef);

      // --- FIX #3: Atomically decrement the itemCount on the parent document ---
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(-1)});

      if (indexSnapshot.exists) {
        final currentCount =
            (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
        if (currentCount <= 1) {
          transaction.delete(indexDocRef);
        } else {
          transaction
              .update(indexDocRef, {'count': FieldValue.increment(-1)});
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
      return snapshot.docs
          .map((doc) => ShoppingListInfo.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getShoppingListItemsStream(
      {required String listId}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    final collectionRef =
    _shoppingListsRef(uid).doc(listId).collection('items');
    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getShoppingListItemsOnce(
      {required String listId}) async {
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

  Future<void> removeItemsFromList({
    required String listId,
    required List<String> productIds,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    if (productIds.isEmpty) return;

    final listDocRef = _shoppingListsRef(uid).doc(listId); // Reference to the parent list document

    await _firestore.runTransaction((transaction) async {
      final indexRefs = productIds.map((id) => _listedProductIdsRef(uid).doc(id)).toList();
      final indexSnapshots = await Future.wait(indexRefs.map((ref) => transaction.get(ref)));

      for (var i = 0; i < productIds.length; i++) {
        final productId = productIds[i];
        final indexSnapshot = indexSnapshots[i];
        final itemDocRef = listDocRef.collection('items').doc(productId);

        transaction.delete(itemDocRef);

        if (indexSnapshot.exists) {
          final currentCount = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
          if (currentCount <= 1) {
            transaction.delete(indexSnapshot.reference);
          } else {
            transaction.update(
                indexSnapshot.reference, {'count': FieldValue.increment(-1)});
          }
        }
      }

      // --- FIX #4: Decrement the itemCount by the number of items being removed ---
      transaction.update(listDocRef, {'itemCount': FieldValue.increment(-productIds.length)});
    });
  }

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
          .map((doc) => Product.fromFirestore(
          doc.id, doc.data() as Map<String, dynamic>))
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