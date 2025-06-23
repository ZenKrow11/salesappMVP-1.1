import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart'; // Ensure this path is correct
import 'package:sales_app_mvp/providers/product_provider.dart'; // Ensure this path is correct
import 'package:sales_app_mvp/components/product_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // The scroll controller is still needed to detect when the user reaches the end.
  final ScrollController _scrollController = ScrollController();

  // The state for expanded tiles is UI-specific, so it's fine to keep it here.
  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // We check if the user has scrolled to 80% of the bottom of the page.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // We use ref.read to call a method on our notifier.
      // This triggers the data fetching but doesn't cause this widget to rebuild.
      // The rebuild will happen automatically when the provider's state changes.
      ref.read(paginatedProductsProvider.notifier).loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the provider. This is the only line needed to connect the UI to the state.
    // Riverpod will automatically handle rebuilding this widget when `productsAsync` changes.
    final productsAsync = ref.watch(paginatedProductsProvider);

    // 2. Use the `when` method to easily handle all possible states: loading, error, and data.
    return productsAsync.when(
      loading: () {
        // State 1: Initial loading. Show a centered spinner.
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        // State 2: An error occurred during fetching.
        print(stackTrace); // Good for debugging
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to load products. Please check your connection.\nError: $error',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (products) {
        // State 3: We have data!
        if (products.isEmpty) {
          // A sub-case of data: the list is empty.
          return const Center(
            child: Text(
              'No products found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Build the main UI with the list of products.
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85, // You may need to adjust this for your ProductTile
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductTile(
              product: product,
              isExpanded: _expandedStates[product.id] ?? false,
              onTap: () {
                // `setState` is fine here as it only affects the local `_expandedStates` map.
                setState(() {
                  // Toggle the expanded state for the specific product tile.
                  _expandedStates[product.id] = !(_expandedStates[product.id] ?? false);
                });
              },
            );
          },
        );
      },
    );
  }
}