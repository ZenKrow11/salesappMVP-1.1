// lib/services/product_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  Future<Map<String, dynamic>?> getRemoteMetadata() async {
    try {
      final docSnapshot =
      await _firestore.collection('metadata').doc('product_info').get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching remote metadata: $e');
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
      debugPrint("[ProductSyncService] Warning: Remote metadata is missing 'lastUpdated' field.");
      return false;
    }

    if (localTimestampValue == null) {
      return true;
    }

    final remoteTimestamp = (remoteTimestampValue as Timestamp).toDate();
    final localTimestamp = localTimestampValue as DateTime;

    return remoteTimestamp.isAfter(localTimestamp);
  }

  Future<Map<String, dynamic>> syncFromFirestore(
      void Function(String message, double progress) onProgress,
      ) async {
    final remoteMetadata = await getRemoteMetadata();

    if (remoteMetadata == null) {
      onProgress("No remote data. Clearing cache...", 0.9);
      await _productBox.clear();
      await _metadataBox.clear();
      return {};
    }

    if (remoteMetadata['lastUpdated'] == null) {
      throw Exception("Aborting sync: Remote metadata is present but is missing the 'lastUpdated' field.");
    }

    await _productBox.clear();

    final List<Product> allProducts = [];
    final int grandTotal = (remoteMetadata['grandTotal'] as num?)?.toInt() ?? 0;
    const int pageSize = 400;
    bool hasMore = true;
    DocumentSnapshot? lastDoc;

    onProgress("Starting download...", 0.1);

    if (grandTotal == 0) {
      hasMore = false;
      onProgress("No products to download.", 0.8);
    }

    while(hasMore) {

      Query query = _firestore
          .collection('products')
          .where('isOnSale', isEqualTo: true)
          .orderBy(FieldPath.documentId)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDoc = snapshot.docs.last;

        final products = snapshot.docs
            .map((doc) => Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        allProducts.addAll(products);

        final progress = (allProducts.length / grandTotal).clamp(0.1, 0.8);
        onProgress("Downloaded ${allProducts.length} of $grandTotal products...", progress);
      }

      if(snapshot.docs.length < pageSize) {
        hasMore = false;
      }
    }

    onProgress("Saving ${allProducts.length} products to device...", 0.9);

    final Map<String, Product> productMap = {for (var p in allProducts) p.id: p};
    await _productBox.putAll(productMap);

    onProgress("Finalizing sync...", 0.95);
    final newLocalMetadata = Map<String, dynamic>.from(remoteMetadata);
    newLocalMetadata['lastUpdated'] =
        (remoteMetadata['lastUpdated'] as Timestamp).toDate();

    await _metadataBox.put('localMetadata', newLocalMetadata);

    return newLocalMetadata;
  }
}