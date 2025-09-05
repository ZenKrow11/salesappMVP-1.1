// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Adds a product ID to the user's list
  Future<void> addItemToList(
      {required String listId, required String productId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final docRef = _firestore.collection('users').doc(uid).collection(
        'shoppingLists').doc(listId).collection('items').doc(productId);
    await docRef.set({'addedAt': FieldValue.serverTimestamp()});
  }

  // Removes a product ID from the user's list
  Future<void> removeItemFromList(
      {required String listId, required String productId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    final docRef = _firestore.collection('users').doc(uid).collection(
        'shoppingLists').doc(listId).collection('items').doc(productId);
    await docRef.delete();
  }

  // Streams the list of product IDs in real-time
  Stream<List<String>> getShoppingListItemsStream({required String listId}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    final collectionRef = _firestore.collection('users').doc(uid).collection(
        'shoppingLists').doc(listId).collection('items');
    return collectionRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.id).toList());
  }

  // NEW: A method to ensure the default list exists in Firestore for a user.
  Future<void> ensureDefaultListExists({required String listId}) async {
    final uid = _uid;
    if (uid == null) return;

    final listRef = _firestore.collection('users').doc(uid).collection(
        'shoppingLists').doc(listId);
    final doc = await listRef.get();

    if (!doc.exists) {
      await listRef.set({
        'name': listId, // Use the parameter here
        'createdAt': FieldValue.serverTimestamp(),
        'index': -1
      });
    }
  }
}