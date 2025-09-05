// lib/models/products_provider.dart

// This is the only class still needed from this file.
// All the Riverpod providers (@Riverpod annotations, FutureProvider, etc.) and
// fetch functions (_fetchAndSyncProducts) have been removed because their
// responsibilities are now handled by the new architecture:
//
// - App initialization and data loading is now done by `appDataProvider`.
// - Data syncing logic now lives in `ProductSyncService`.
// - The UI reads total counts from `appDataProvider` and filtered results
//   from `homePageProductsProvider`.

class ProductCount {
  final int filtered;
  final int total;
  ProductCount({required this.filtered, required this.total});
}