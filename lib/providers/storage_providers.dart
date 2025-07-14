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

  // IMPORTANT: We open the old 'favorites' box one last time here so that our
  // migration logic in the ShoppingListNotifier can access it.
  // After you are confident your users have updated, you can safely remove this line.
  await Hive.openBox<Product>('favorites');

  print("[HiveProvider] All Hive boxes initialized and opened.");
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