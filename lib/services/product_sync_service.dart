// lib/services/product_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';

// --- STEP 1: ADD THIS IMPORT ---
// We need this to access the user's saved product IDs.
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';


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

  // ... (getRemoteMetadata, getLocalMetadata, and needsSync methods remain unchanged) ...
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

  Map<String, dynamic> getLocalMetadata() {
    return Map<String, dynamic>.from(_metadataBox.get('localMetadata') ?? {});
  }

  Future<bool> needsSync() async {
    final remoteMetadata = await getRemoteMetadata();
    final localMetadata = getLocalMetadata();

    if (remoteMetadata == null) {
      return localMetadata.isNotEmpty;
    }

    final remoteTimestampValue = remoteMetadata['lastUpdated'];
    final localTimestampValue = localMetadata['lastUpdated'];

    if (remoteTimestampValue == null) {
      print("[ProductSyncService] Warning: Remote metadata is missing 'lastUpdated' field.");
      return false;
    }

    if (localTimestampValue == null) {
      return true;
    }

    final remoteTimestamp = (remoteTimestampValue as Timestamp).toDate();
    final localTimestamp = localTimestampValue as DateTime;

    return remoteTimestamp.isAfter(localTimestamp);
  }


  /// --- Main sync function (MODIFIED) ---
  /// Fetches all products and the latest metadata from Firestore,
  /// saves them to Hive, and returns the new metadata.
  Future<Map<String, dynamic>> syncFromFirestore() async {
    final remoteMetadata = await getRemoteMetadata();

    if (remoteMetadata == null) {
      print("[ProductSyncService] No remote metadata found. Clearing local cache.");
      await _productBox.clear();
      await _metadataBox.clear();
      return {};
    }

    if (remoteMetadata['lastUpdated'] == null) {
      throw Exception(
          "Aborting sync: Remote metadata is present but is missing the 'lastUpdated' field.");
    }

    // --- STEP 2: FETCH ALL SAVED PRODUCT IDS ---
    // Read the provider once to get the current set of all product IDs
    // the user has saved across all their lists.
    final savedProductIds = await _ref.read(listedProductIdsProvider.future);

    // This will hold all products we need to cache, using their ID as the key
    // to automatically handle duplicates (e.g., a product is on sale AND saved).
    final Map<String, Product> productMap = {};

    // --- QUERY 1: Fetch all products currently on sale ---
    final productsOnSaleSnapshot = await _firestore
        .collection('products')
        .where('isOnSale', isEqualTo: true)
        .get();

    for (var doc in productsOnSaleSnapshot.docs) {
      productMap[doc.id] = Product.fromFirestore(doc.id, doc.data());
    }

    // --- QUERY 2: Fetch all products saved by the user that are NOT already fetched ---
    final idsToFetch = savedProductIds.where((id) => !productMap.containsKey(id)).toList();

    if (idsToFetch.isNotEmpty) {
      // Firestore 'whereIn' queries are limited to 30 elements per query.
      // We must break our list of IDs into chunks of 30.
      for (var i = 0; i < idsToFetch.length; i += 30) {
        final chunk = idsToFetch.sublist(i, i + 30 > idsToFetch.length ? idsToFetch.length : i + 30);
        if (chunk.isNotEmpty) {
          final savedProductsSnapshot = await _firestore
              .collection('products')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (var doc in savedProductsSnapshot.docs) {
            productMap[doc.id] = Product.fromFirestore(doc.id, doc.data());
          }
        }
      }
    }

    // --- STEP 3: REPLACE THE OLD DATABASE LOGIC ---
    // Instead of mapping a specific query, we now use our combined map.
    await _productBox.clear();
    await _productBox.putAll(productMap);

    // On success, save the new metadata locally
    final newLocalMetadata = Map<String, dynamic>.from(remoteMetadata);
    newLocalMetadata['lastUpdated'] =
        (remoteMetadata['lastUpdated'] as Timestamp).toDate();

    await _metadataBox.put('localMetadata', newLocalMetadata);

    return newLocalMetadata;
  }
}