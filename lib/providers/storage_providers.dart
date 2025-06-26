// lib/providers/storage_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../services/hive_storage_service.dart';

/// Provider 1: A FutureProvider to handle the ONE-TIME initialization of Hive.
/// This will run once and its result will be cached by Riverpod.
/// It handles registering adapters and opening the boxes.
final hiveInitializationProvider = FutureProvider<void>((ref) async {
  // Register all your Hive type adapters here.
  // This is crucial! Hive needs to know how to (de)serialize your objects.
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(NamedListAdapter());

  // Open all the boxes you need for your app.
  await Hive.openBox<Product>('favorites');
  await Hive.openBox<NamedList>('namedLists');
  // You also had 'shoppingLists' but it was untyped. If you still need it,
  // add `await Hive.openBox('shoppingLists');` here.

  print("[HiveProvider] All Hive boxes initialized and opened.");
});

/// Provider 2: A regular Provider that creates and provides the
/// instance of our HiveStorageService.
final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  // This line creates a dependency. This provider will not build until
  // hiveInitializationProvider has successfully completed.
  // This guarantees that the boxes are open before we try to use them.
  ref.watch(hiveInitializationProvider);

  // Now that we know the boxes are open, we can safely get them.
  final favoritesBox = Hive.box<Product>('favorites');
  final namedListsBox = Hive.box<NamedList>('namedLists');

  // Create and return the service instance with the open boxes.
  return HiveStorageService(
    favoritesBox: favoritesBox,
    namedListsBox: namedListsBox,
  );
});