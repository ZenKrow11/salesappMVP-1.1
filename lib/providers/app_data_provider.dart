// lib/providers/app_data_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/services/product_sync_service.dart';
import 'package:sales_app_mvp/models/plain_product.dart';

enum InitializationStatus { uninitialized, loading, loaded, error }

// ADDED: Enum to distinguish between loading types for the UI.
enum LoadingType { fromCache, fromNetwork }

class AppDataState {
  final InitializationStatus status;
  final List<Product> allProducts;
  final Map<String, dynamic> metadata;
  final String? errorMessage;
  final String loadingMessage;
  final double loadingProgress;
  final LoadingType loadingType; // ADDED: Tracks the type of loading.

  AppDataState({
    required this.status,
    this.allProducts = const [],
    this.metadata = const {},
    this.errorMessage,
    this.loadingMessage = 'Initializing...',
    this.loadingProgress = 0.0,
    this.loadingType = LoadingType.fromCache, // Default to the faster type.
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
    LoadingType? loadingType, // ADDED: For updating loading type.
  }) {
    return AppDataState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      loadingType: loadingType ?? this.loadingType,
    );
  }
}

class AppDataController extends StateNotifier<AppDataState> {
  final Ref _ref;
  final ProductSyncService _syncService;

  AppDataController(this._ref, this._syncService)
      : super(AppDataState(status: InitializationStatus.uninitialized));

  Future<void> initialize() async {
    // Guard clause prevents re-initialization if already loaded or loading.
    if (state.status == InitializationStatus.loading || state.status == InitializationStatus.loaded) {
      return;
    }

    try {
      state = state.copyWith(status: InitializationStatus.loading, loadingMessage: 'Preparing local storage...', loadingProgress: 0.1);
      await _ref.read(hiveInitializationProvider.future);

      final productBox = _ref.read(productsBoxProvider);
      final needsToSync = await _syncService.needsSync();

      Map<String, dynamic> loadedMetadata;

      if (needsToSync) {
        // Set the loading type to network for the detailed UI.
        state = state.copyWith(loadingType: LoadingType.fromNetwork, loadingMessage: 'Connecting...', loadingProgress: 0.2);

        // Call the paginated sync service, passing a function to update the state.
        loadedMetadata = await _syncService.syncFromFirestore(
              (message, progress) {
            state = state.copyWith(loadingMessage: message, loadingProgress: progress);
          },
        );
      } else {
        // Set the loading type to cache for the simple spinner UI.
        state = state.copyWith(loadingType: LoadingType.fromCache, loadingMessage: 'Loading saved deals...', loadingProgress: 0.8);
        loadedMetadata = _syncService.getLocalMetadata();
        // Add a small artificial delay to prevent the spinner from just flashing on screen.
        await Future.delayed(const Duration(milliseconds: 700));
      }

      final allProducts = productBox.values.toList();
      print("[AppDataProvider] Initialization complete. Loaded ${allProducts.length} products.");

      state = state.copyWith(loadingMessage: 'All set!', loadingProgress: 1.0);
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
        loadingMessage: 'Error: Could not load data.',
        loadingProgress: 1.0,
      );
    }
  }

  void reset() {
    state = AppDataState(status: InitializationStatus.uninitialized);
    print("[AppDataProvider] State has been reset.");
  }
}

final appDataProvider =
StateNotifierProvider.autoDispose<AppDataController, AppDataState>((ref) {
  final syncService = ref.watch(productSyncProvider);
  return AppDataController(ref, syncService);
});

/// A provider that is responsible for the expensive conversion of Hive-backed
/// `Product` objects into isolate-friendly `PlainProduct` objects.
/// This should only be run ONCE per data load. All other providers that need
/// the plain list should read from this one.
final plainProductsProvider = Provider.autoDispose<List<PlainProduct>>((ref) {
  // Watch the master app state for the raw list of Hive products.
  final allProducts = ref.watch(appDataProvider).allProducts;

  // If the list is empty, return an empty list.
  if (allProducts.isEmpty) {
    return [];
  }

  // Perform the conversion. This is the one and only time this .map call
  // will happen for the entire dataset.
  return allProducts.map((p) => p.toPlainObject()).toList();
});