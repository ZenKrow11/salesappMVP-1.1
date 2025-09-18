// lib/services/product_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

/// Provider for ProductSyncService
final productSyncProvider = Provider<ProductSyncService>((ref) {
  return ProductSyncService(ref);
});

class ProductSyncService {
  final Ref _ref;

  ProductSyncService(this._ref);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Box<Product> get _productBox => _ref.read(productsBoxProvider);

  Box<dynamic> get _metadataBox => _ref.read(metadataBoxProvider);

  /// --- Fetches the entire metadata document from Firestore ---
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
    return Map<String, dynamic>.from(_metadataBox.get('localMetadata') ?? {});
  }

  /// --- Decides if a sync is needed ---
  // lib/services/product_sync_service.dart

  /// --- Decides if a sync is needed (IMPROVED LOGIC) ---
  Future<bool> needsSync() async {
    final remoteMetadata = await getRemoteMetadata();
    final localMetadata = getLocalMetadata();

    // Case 1: No remote metadata exists at all.
    // If we have local data, we MUST sync to clear it.
    // If we have no local data, we don't need to do anything.
    if (remoteMetadata == null) {
      return localMetadata.isNotEmpty;
    }

    final remoteTimestampValue = remoteMetadata['lastUpdated'];
    final localTimestampValue = localMetadata['lastUpdated'];

    // Case 2: No timestamp on remote. Treat as an invalid state, but
    // safer not to sync than to wipe data accidentally. A log would be good here.
    if (remoteTimestampValue == null) {
      print("[ProductSyncService] Warning: Remote metadata is missing 'lastUpdated' field.");
      return false;
    }

    // Case 3: We have never synced before. We MUST sync.
    if (localTimestampValue == null) {
      return true;
    }

    // Case 4: Compare the timestamps.
    // Note: The local timestamp is already a DateTime from the last sync.
    final remoteTimestamp = (remoteTimestampValue as Timestamp).toDate();
    final localTimestamp = localTimestampValue as DateTime;

    // Sync only if the remote timestamp is newer.
    return remoteTimestamp.isAfter(localTimestamp);
  }

  /// --- Main sync function ---
  /// Fetches all products and the latest metadata from Firestore,
  /// saves them to Hive, and returns the new metadata.
  Future<Map<String, dynamic>> syncFromFirestore() async {
    final remoteMetadata = await getRemoteMetadata();

    // --- START: MODIFIED LOGIC ---

    // Case 1: No data on the server at all.
    // The correct action is to wipe the local cache and return an empty state.
    if (remoteMetadata == null) {
      print("[ProductSyncService] No remote metadata found. Clearing local cache.");
      await _productBox.clear();
      await _metadataBox.clear(); // Also clear local metadata
      return {}; // Return empty metadata
    }

    // This check is still good. If metadata exists, it MUST have a timestamp.
    if (remoteMetadata['lastUpdated'] == null) {
      throw Exception(
          "Aborting sync: Remote metadata is present but is missing the 'lastUpdated' field.");
    }

    // --- END: MODIFIED LOGIC ---

    // Query products explicitly marked as on sale
    final productsSnapshot = await _firestore
        .collection('products')
        .where('isOnSale', isEqualTo: true)
        .get();

    // Fallback: also fetch products missing the "isOnSale" field (legacy docs)
    final fallbackSnapshot = await _firestore
        .collection('products')
        .where('isOnSale', isNull: true)
        .get();

    final allDocs = [...productsSnapshot.docs, ...fallbackSnapshot.docs];

    final products = allDocs
        .map((doc) => Product.fromFirestore(doc.id, doc.data()))
        .toList();

    // Perform the database write operations
    await _productBox.clear();
    final Map<String, Product> productMap = {for (var p in products) p.id: p};
    await _productBox.putAll(productMap);

    // On success, save the new metadata locally
    final newLocalMetadata = Map<String, dynamic>.from(remoteMetadata);
    newLocalMetadata['lastUpdated'] =
        (remoteMetadata['lastUpdated'] as Timestamp).toDate();

    await _metadataBox.put('localMetadata', newLocalMetadata);

    return newLocalMetadata;
  }
}
