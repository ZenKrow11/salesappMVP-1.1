import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/product_provider.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/details_screen.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

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
    // Prevent multiple calls if already loading more or no more items
    final notifier = ref.read(paginatedProductsProvider.notifier);
    // Assuming your notifier has a way to check if it's currently loading or has more items
    // For example, if it's a StateNotifier<AsyncValue<List<Product>>> or has a custom isLoadingMore flag.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !ref.read(paginatedProductsProvider).isLoading) { // Example check
      ref.read(paginatedProductsProvider.notifier).loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(paginatedProductsProvider);
    // It's good practice to also listen to the notifier if you need to react to its state changes
    // for things like showing a loading indicator at the bottom during pagination.
    // final productNotifier = ref.watch(paginatedProductsProvider.notifier);

    // Handle case where maxScrollExtent might be 0 initially if content is less than viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productsAsync is AsyncData && productsAsync.value!.isNotEmpty && _scrollController.position.maxScrollExtent == 0) {
        // Potentially trigger loadMore if initial content doesn't fill screen and more might be available
        // This depends on your exact pagination logic.
      }
    });

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        print(stackTrace);
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
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'No products found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Consider adding a loading indicator at the bottom if paginating
        // final isLoadingMore = productNotifier.isLoadingMore; // Assuming your notifier exposes this

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: products.length, // + (isLoadingMore ? 1 : 0) if showing loading item
                itemBuilder: (context, index) {
                  // if (isLoadingMore && index == products.length) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  final product = products[index];
                  return ProductTile(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // if (productsAsync.isLoading) // Or a specific isLoadingMore flag from your notifier
            //   const Padding(
            //     padding: EdgeInsets.all(8.0),
            //     child: CircularProgressIndicator(),
            //   ),
          ],
        );
      },
    );
  }
}