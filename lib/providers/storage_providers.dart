// lib/providers/storage_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../services/hive_storage_service.dart'; // Import your existing service

/// Handles the one-time initialization of Hive, including registering adapters and opening all necessary boxes.
final hiveInitializationProvider = FutureProvider<void>((ref) async {
  // Ensure all Hive type adapters are registered here.
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(NamedListAdapter());

  // Open all the boxes your app will need at startup.
  await Hive.openBox<Product>('products');
  await Hive.openBox<Product>('favorites'); // Required by your service
  await Hive.openBox<NamedList>('namedLists'); // Required by your service

  print("[HiveProvider] All Hive boxes initialized and opened.");
});

/// Creates and provides the single instance of your HiveStorageService.
/// This provider guarantees that the service is only created *after* Hive is fully initialized, preventing race conditions.
final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  // This dependency ensures the code below only runs after initialization is complete.
  ref.watch(hiveInitializationProvider);

  // Now that we know the boxes are open, we can safely get them.
  final favoritesBox = Hive.box<Product>('favorites');
  final namedListsBox = Hive.box<NamedList>('namedLists');

  // Create and return the service instance with the required open boxes.
  return HiveStorageService(
    favoritesBox: favoritesBox,
    namedListsBox: namedListsBox,
  );
});