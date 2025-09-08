// lib/models/shopping_list_info.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A lightweight model representing a single shopping list.
class ShoppingListInfo {
  final String id; // The document ID, which is the list name
  final String name;

  ShoppingListInfo({required this.id, required this.name});

  factory ShoppingListInfo.fromFirestore(DocumentSnapshot doc) {
    // For simplicity, the document ID is the name of the list.
    return ShoppingListInfo(
      id: doc.id,
      name: doc.id,
    );
  }
}