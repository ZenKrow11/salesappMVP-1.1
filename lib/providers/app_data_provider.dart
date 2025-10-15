// lib/providers/app_data_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/product_sync_service.dart';

enum InitializationStatus { uninitialized, loading, loaded, error }

class AppDataState {
  final InitializationStatus status;
  final List<Product> allProducts;
  final Map<String, dynamic> metadata;
  final String? errorMessage;
  final String loadingMessage; // This now holds a LOCALIZATION KEY
  final double loadingProgress;

  AppDataState({
    required this.status,
    this.allProducts = const [],
    this.metadata = const {},
    this.errorMessage,
    // THE DEFAULT IS NOW A KEY
    this.loadingMessage = 'loadingInitializing',
    this.loadingProgress = 0.0,
  });

  int get grandTotal => metadata['grandTotal'] as int? ?? 0;
  Map<String, int> get storeCounts =>
      Map<String, int>.from(metadata['storeCounts'] ?? {});

  AppDataState copyWith({
    InitializationStatus? status,
    List<Product>? allProducts,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    String? loadingMessage,
    double? loadingProgress,
  }) {
    return AppDataState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      loadingProgress: loadingProgress ?? this.loadingProgress,
    );
  }
}

class AppDataController extends StateNotifier<AppDataState> {
  final Ref _ref;
  final ProductSyncService _syncService;

  AppDataController(this._ref, this._syncService)
      : super(AppDataState(status: InitializationStatus.uninitialized));

  // --- ADD THIS METHOD ---
  /// Resets the controller to its initial state. Called on user logout.
  void reset() {
    state = AppDataState(status: InitializationStatus.uninitialized);
  }

  Future<void> initialize() async {
    // This guard is now even more important.
    if (state.status != InitializationStatus.uninitialized) return;

    try {
      state = state.copyWith(status: InitializationStatus.loading, loadingMessage: 'loadingPreparingStorage', loadingProgress: 0.1);
      await _ref.read(hiveInitializationProvider.future);

      state = state.copyWith(loadingMessage: 'loadingCheckingUpdates', loadingProgress: 0.4);
      final productBox = _ref.read(productsBoxProvider);
      final needsToSync = await _syncService.needsSync();

      Map<String, dynamic> loadedMetadata;

      if (needsToSync) {
        state = state.copyWith(loadingMessage: 'loadingDownloadingDeals', loadingProgress: 0.6);
        loadedMetadata = await _syncService.syncFromFirestore();
      } else {
        state = state.copyWith(loadingMessage: 'loadingFromCache', loadingProgress: 0.8);
        loadedMetadata = _syncService.getLocalMetadata();
      }

      final allProducts = productBox.values.toList();
      print("[AppDataProvider] Initialization complete. Loaded ${allProducts.length} products.");

      state = state.copyWith(loadingMessage: 'loadingAllSet', loadingProgress: 1.0);
      await Future.delayed(const Duration(milliseconds: 250));

      state = state.copyWith(
        status: InitializationStatus.loaded,
        allProducts: allProducts,
        metadata: loadedMetadata,
      );

    } catch (e, stack) {
      print("[AppDataProvider] CRITICAL ERROR during initialization: $e\n$stack");
      state = state.copyWith(
        status: InitializationStatus.error,
        errorMessage: e.toString(),
        loadingMessage: 'errorCouldNotLoadData',
        loadingProgress: 1.0,
      );
    }
  }
}

// ... (provider definition is unchanged) ...
final appDataProvider =
StateNotifierProvider<AppDataController, AppDataState>((ref) {
  final syncService = ref.watch(productSyncProvider);
  return AppDataController(ref, syncService);
});