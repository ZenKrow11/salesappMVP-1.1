import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListInfo {
  final String id;
  final String name;
  final int itemCount;

  ShoppingListInfo({
    required this.id,
    required this.name,
    required this.itemCount,
  });

  factory ShoppingListInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final listName = data['name'] as String? ?? 'Unnamed List';

    // This now reads the denormalized count from the parent document
    final count = data['itemCount'] as int? ?? 0;

    return ShoppingListInfo(
      id: doc.id,
      name: listName,
      itemCount: count,
    );
  }
}