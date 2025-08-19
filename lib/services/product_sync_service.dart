// lib/services/product_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

final productSyncProvider = Provider<ProductSyncService>((ref) {
  return ProductSyncService(ref);
});

class ProductSyncService {
  final Ref _ref;
  ProductSyncService(this._ref);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  Box<Product> get _productBox => _ref.read(productsBoxProvider);
  Box<dynamic> get _metadataBox => _ref.read(metadataBoxProvider);

  // CHANGED: Fetches the 'lastUpdated' timestamp from the server
  Future<DateTime?> getRemoteTimestamp() async {
    try {
      final docSnapshot =
      await _firestore.collection('metadata').doc('product_info').get();
      // Ensure the document and the field exist before trying to read it
      if (!docSnapshot.exists || docSnapshot.data()?['lastUpdated'] == null) {
        return null;
      }
      // Convert the Firestore Timestamp object to a Dart DateTime object
      return (docSnapshot.get('lastUpdated') as Timestamp).toDate();
    } catch (e) {
      print('Error fetching remote timestamp: $e');
      return null; // Return null on any error
    }
  }

  // CHANGED: Gets the last synced timestamp from local storage
  DateTime? getLocalTimestamp() {
    // The key is changed to reflect we are storing a timestamp
    return _metadataBox.get('lastSyncTimestamp');
  }

  // CHANGED: Decides if a sync is needed by comparing timestamps
  Future<bool> needsSync() async {
    final remoteTimestamp = await getRemoteTimestamp();
    final localTimestamp = getLocalTimestamp();

    if (remoteTimestamp == null) {
      // If there's no timestamp on the server, we can't sync.
      return false;
    }
    if (localTimestamp == null) {
      // If we have never synced before, we must sync.
      return true;
    }

    // The core logic: if the server's data is newer than our local data, we sync.
    return remoteTimestamp.isAfter(localTimestamp);
  }

  // The main sync function, now updates the local timestamp on success
  Future<void> syncFromFirestore() async {
    // Get the timestamp before fetching products to ensure consistency
    final remoteTimestamp = await getRemoteTimestamp();
    if (remoteTimestamp == null) {
      print("Aborting sync: Could not retrieve a valid remote timestamp.");
      return;
    }

    final productsSnapshot = await _firestore.collection('products').get();
    final products = productsSnapshot.docs
        .map((doc) => Product.fromFirestore(doc.id, doc.data()))
        .toList();

    // Perform the database operations
    await _productBox.clear();
    final Map<String, Product> productMap = {for (var p in products) p.id: p};
    await _productBox.putAll(productMap);

    // CHANGED: On success, save the new server timestamp locally.
    // This marks our local data as being up-to-date with this server version.
    await _metadataBox.put('lastSyncTimestamp', remoteTimestamp);
  }
}