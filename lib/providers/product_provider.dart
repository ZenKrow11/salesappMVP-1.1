import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

final productsProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((snapshot) {
    final products = snapshot.docs.map((doc) {
      return Product.fromFirestore(doc.id, doc.data());
    }).toList();
    print('Streamed ${products.length} products');
    return products;
  });
});
