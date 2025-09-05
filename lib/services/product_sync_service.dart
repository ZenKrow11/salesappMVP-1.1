// lib/services/product_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

// The provider definition remains the same.
final productSyncProvider = Provider<ProductSyncService>((ref) {
  return ProductSyncService(ref);
});

class ProductSyncService {
  final Ref _ref;
  ProductSyncService(this._ref);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  Box<Product> get _productBox => _ref.read(productsBoxProvider);
  Box<dynamic> get _metadataBox => _ref.read(metadataBoxProvider);

  /// --- NEW: Fetches the entire metadata document from Firestore ---
  /// This document acts as the "control panel" for the app.
  Future<Map<String, dynamic>?> getRemoteMetadata() async {
    try {
      final docSnapshot =
      await _firestore.collection('metadata').doc('product_info').get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error fetching remote metadata: $e');
      return null;
    }
  }

  /// --- Gets the locally stored metadata ---
  Map<String, dynamic> getLocalMetadata() {
    // Use .toMap() to convert the Hive Map to a standard Dart Map
    // Default to an empty map if null
    return Map<String, dynamic>.from(_metadataBox.get('localMetadata') ?? {});
  }


  /// --- The Core Logic: Decides if a sync is needed ---
  Future<bool> needsSync() async {
    final remoteMetadata = await getRemoteMetadata();
    final localMetadata = getLocalMetadata();

    // Can't sync if there's no remote data.
    if (remoteMetadata?['lastUpdated'] == null) {
      return false;
    }
    // Must sync if we have no local data.
    if (localMetadata['lastUpdated'] == null) {
      return true;
    }

    final remoteTimestamp = (remoteMetadata!['lastUpdated'] as Timestamp).toDate();
    final localTimestamp = localMetadata['lastUpdated'];

    // Sync if the server data is newer.
    return remoteTimestamp.isAfter(localTimestamp);
  }

  /// --- The main sync function ---
  /// Fetches all products and the latest metadata from Firestore,
  /// saves them to Hive, and returns the new metadata.
  Future<Map<String, dynamic>> syncFromFirestore() async {
    final remoteMetadata = await getRemoteMetadata();
    if (remoteMetadata == null || remoteMetadata['lastUpdated'] == null) {
      throw Exception("Aborting sync: Could not retrieve valid remote metadata.");
    }

    final productsSnapshot = await _firestore.collection('products').get();
    final products = productsSnapshot.docs
        .map((doc) => Product.fromFirestore(doc.id, doc.data()))
        .toList();

    // Perform the database write operations
    await _productBox.clear();
    final Map<String, Product> productMap = {for (var p in products) p.id: p};
    await _productBox.putAll(productMap);

    // On success, save the new metadata document locally.
    // We convert the Firestore Timestamp to a standard DateTime for Hive.
    final newLocalMetadata = Map<String, dynamic>.from(remoteMetadata);
    newLocalMetadata['lastUpdated'] = (remoteMetadata['lastUpdated'] as Timestamp).toDate();

    await _metadataBox.put('localMetadata', newLocalMetadata);

    return newLocalMetadata;
  }
}