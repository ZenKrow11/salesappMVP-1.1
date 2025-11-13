// lib/providers/storage_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../services/hive_storage_service.dart';

/// Handles the one-time initialization of Hive.
final hiveInitializationProvider = FutureProvider<void>((ref) async {
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(NamedListAdapter());

  await Hive.openBox<Product>('products');
  await Hive.openBox<NamedList>('namedLists');

  // --- ADDED THIS LINE ---
  // This opens the new box for storing metadata like the sync timestamp.
  await Hive.openBox<dynamic>('metadata');

  // IMPORTANT: We open the old 'favorites' box one last time here so that our
  // migration logic in the ShoppingListNotifier can access it.
  // After you are confident your users have updated, you can safely remove this line.
  await Hive.openBox<Product>('favorites');

});

/// Creates and provides the single instance of your HiveStorageService.
final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  // This dependency ensures the code below only runs after initialization is complete.
  ref.watch(hiveInitializationProvider);

  final namedListsBox = Hive.box<NamedList>('namedLists');

  // The service is now created with only the namedListsBox, as required.
  return HiveStorageService(
    namedListsBox: namedListsBox,
  );
});

// --- ADDED THE FOLLOWING TWO PROVIDERS ---

/// Provider for the main product data storage box.
/// This is used by the ProductSyncService to store all product data from Firebase.
final productsBoxProvider = Provider<Box<Product>>((ref) {
  // This ensures that the box is open before we try to access it.
  ref.watch(hiveInitializationProvider);
  return Hive.box<Product>('products');
});

/// Provider for the metadata box.
/// This is used by the ProductSyncService to read and write the last sync timestamp.
final metadataBoxProvider = Provider<Box<dynamic>>((ref) {
  // This ensures that the box is open before we try to access it.
  ref.watch(hiveInitializationProvider);
  return Hive.box<dynamic>('metadata');
});