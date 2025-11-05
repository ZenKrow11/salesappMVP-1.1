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

  // =======================================================================
  // === CORE CHANGES FOR NEW ARCHITECTURE ARE HERE ========================
  // =======================================================================

  /// Creates a new shopping list with a unique ID.
  Future<void> createNewList({required String listName}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    // Get a reference to a new document with an AUTO-GENERATED ID.
    final listRef = _shoppingListsRef(uid).doc();

    // Set the data inside the document, including the 'name'.
    await listRef.set({
      'name': listName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // NOTE: The `ensureDefaultListExists` method has been completely removed.
  // It is no longer needed in the new architecture.

  // =======================================================================
  // === NO OTHER CHANGES ARE NEEDED BELOW THIS LINE =======================
  // =======================================================================

  Future<void> deleteList({required String listId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final listDocRef = _shoppingListsRef(uid).doc(listId);
    final listItemsColRef = listDocRef.collection('items');

    final listItemsSnapshot = await listItemsColRef.get();
    final itemIds = listItemsSnapshot.docs.map((doc) => doc.id).toList();

    // First, delete all items within the list subcollection
    if (listItemsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in listItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Next, update the listedProductIds index in a transaction
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
      // Finally, delete the main list document
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
        final currentCount = (indexSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
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
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

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

  Future<void> removeItemsFromList({
    required String listId,
    required List<String> productIds,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');
    if (productIds.isEmpty) return;

    await _firestore.runTransaction((transaction) async {
      final indexRefs = productIds
          .map((id) => _listedProductIdsRef(uid).doc(id))
          .toList();
      final indexSnapshots = await Future.wait(
          indexRefs.map((ref) => transaction.get(ref))
      );
      for (var i = 0; i < productIds.length; i++) {
        final productId = productIds[i];
        final indexSnapshot = indexSnapshots[i];
        final listDocRef = _shoppingListsRef(uid).doc(listId).collection('items').doc(productId);
        transaction.delete(listDocRef);
        if (indexSnapshot.exists) {
          final currentCount = (indexSnapshot.data() as Map<String, dynamic>)?['count'] ?? 0;
          if (currentCount <= 1) {
            transaction.delete(indexSnapshot.reference);
          } else {
            transaction.update(indexSnapshot.reference, {'count': FieldValue.increment(-1)});
          }
        }
      }
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