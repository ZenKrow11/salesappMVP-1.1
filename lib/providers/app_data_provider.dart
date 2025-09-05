// lib/providers/app_data_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/product_sync_service.dart';

// 1. An enum for clearer, more robust state management than a simple boolean.
enum InitializationStatus { loading, loaded, error }

// 2. The state class that holds all of our app's core data.
class AppDataState {
  final InitializationStatus status;
  final List<Product> allProducts;
  final Map<String, dynamic> metadata;

  AppDataState({
    this.status = InitializationStatus.loading,
    this.allProducts = const [],
    this.metadata = const {},
  });

  // Helper getters for clean and safe access in the UI.
  int get grandTotal => metadata['grandTotal'] as int? ?? 0;
  Map<String, int> get storeCounts => Map<String, int>.from(metadata['storeCounts'] ?? {});

  AppDataState copyWith({
    InitializationStatus? status,
    List<Product>? allProducts,
    Map<String, dynamic>? metadata,
  }) {
    return AppDataState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      metadata: metadata ?? this.metadata,
    );
  }
}

// 3. The StateNotifier, which acts as the "Controller" for our state.
class AppDataController extends StateNotifier<AppDataState> {
  final Ref _ref;

  AppDataController(this._ref) : super(AppDataState());

  /// This is the "Master Initialize Action" from your roadmap.
  /// It should be called only once when the app starts.
  Future<void> initialize() async {
    // Guard against multiple, unnecessary initializations.
    if (state.status != InitializationStatus.loading) return;

    try {
      // Read the services and boxes we will need.
      final syncService = _ref.read(productSyncProvider);
      final productBox = _ref.read(productsBoxProvider);

      Map<String, dynamic> loadedMetadata;

      // This is the core logic from your roadmap.
      final needsToSync = await syncService.needsSync();

      if (needsToSync) {
        // If timestamps differ, fetch everything fresh from Firestore.
        print("[AppDataProvider] Timestamps differ. Syncing from Firestore...");
        loadedMetadata = await syncService.syncFromFirestore();
      } else {
        // If timestamps match, load the existing metadata from the local cache.
        print("[AppDataProvider] Timestamps match. Loading from local Hive cache.");
        loadedMetadata = syncService.getLocalMetadata();
      }

      // At this point, the productBox in Hive is guaranteed to be up-to-date.
      final allProducts = productBox.values.toList();
      print("[AppDataProvider] Initialization complete. Loaded ${allProducts.length} products.");

      // Finally, update the state to notify the UI that we are ready.
      state = state.copyWith(
        status: InitializationStatus.loaded,
        allProducts: allProducts,
        metadata: loadedMetadata,
      );
    } catch (e) {
      // If any part of the process fails, put the app in an error state.
      print("[AppDataProvider] CRITICAL ERROR during initialization: $e");
      state = state.copyWith(status: InitializationStatus.error);
    }
  }
}

// 4. The final global provider that the rest of the app will interact with.
final appDataProvider = StateNotifierProvider<AppDataController, AppDataState>(
      (ref) => AppDataController(ref),
);