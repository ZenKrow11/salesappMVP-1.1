// lib/models/shopping_list_info.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import this for print statements

/// A lightweight model representing a single shopping list's metadata from Firestore.
class ShoppingListInfo {
  final String id; // The unique document ID
  final String name; // The human-readable name

  ShoppingListInfo({required this.id, required this.name});

  /// Creates a ShoppingListInfo object from a Firestore document snapshot.
  /// This is the critical conversion point.
  factory ShoppingListInfo.fromFirestore(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final listName = data['name'] as String? ?? 'Unnamed List';

    // --- DEBUGGING LINE ---
    // This will print to your debug console and prove what the code is seeing.
    if (kDebugMode) {
      print("--- Translating Firestore Doc ---");
      print("Doc ID: ${doc.id}");
      print("Name from data['name']: ${data['name']}");
      print("Final Name: $listName");
      print("-----------------------------");
    }

    return ShoppingListInfo(
      id: doc.id,
      name: listName,
    );
  }
}