// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$initialProductsHash() => r'63496fad223e03e4b07c50c577cf17b22d03b566';

/// This provider is responsible for the INITIAL fetch of products.
/// It fetches data once and then stays in the `data` state.
/// This prevents the "double load" flicker in the UI.
/// We use `keepAlive` so it doesn't get disposed and re-run needlessly.
///
/// Copied from [initialProducts].
@ProviderFor(initialProducts)
final initialProductsProvider = FutureProvider<List<Product>>.internal(
  initialProducts,
  name: r'initialProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initialProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InitialProductsRef = FutureProviderRef<List<Product>>;
String _$productsRefresherHash() => r'1c2a39091b26c58e875caf9024ae5d6ebe80fe47';

/// This notifier is now ONLY for handling background refreshes.
/// The UI will not watch it directly. Its job is to perform an action.
///
/// Copied from [ProductsRefresher].
@ProviderFor(ProductsRefresher)
final productsRefresherProvider =
    AutoDisposeAsyncNotifierProvider<ProductsRefresher, void>.internal(
  ProductsRefresher.new,
  name: r'productsRefresherProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productsRefresherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductsRefresher = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
