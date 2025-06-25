import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/product_provider.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/details_screen.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:sales_app_mvp/providers/sort_provider.dart'; // Import sort_provider

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
    final notifier = ref.read(paginatedProductsProvider.notifier);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !ref.read(paginatedProductsProvider).isLoading) {
      ref.read(paginatedProductsProvider.notifier).loadMoreProducts();
    }
  }

  // Helper function to sort products based on the selected sort option
  List<Product> _sortProducts(List<Product> products, SortOption sortOption) {
    final sortedProducts = List<Product>.from(products); // Create a copy to avoid mutating the original
    switch (sortOption) {
      case SortOption.alphabeticalStore:
        sortedProducts.sort((a, b) => a.store.compareTo(b.store)); // Adjust field name if needed
        break;
      case SortOption.alphabetical:
        sortedProducts.sort((a, b) => a.name.compareTo(b.name)); // Adjust field name if needed
        break;
      case SortOption.priceLowToHigh:
        sortedProducts.sort((a, b) => a.currentPrice.compareTo(b.currentPrice)); // Adjust field name if needed
        break;
      case SortOption.discountHighToLow:
        sortedProducts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage)); // Adjust field name if needed
        break;
    }
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(paginatedProductsProvider);
    final sortOption = ref.watch(sortOptionProvider); // Watch the sort option

    // Handle case where maxScrollExtent might be 0 initially if content is less than viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productsAsync is AsyncData && productsAsync.value!.isNotEmpty && _scrollController.position.maxScrollExtent == 0) {
        // Potentially trigger loadMore if initial content doesn't fill screen
      }
    });

    return Column(
      children: [
        // Sorting dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<SortOption>(
                value: sortOption,
                items: SortOption.values.map((SortOption option) {
                  return DropdownMenuItem<SortOption>(
                    value: option,
                    child: Text(
                      option == SortOption.alphabeticalStore
                          ? 'Sort by Store'
                          : option == SortOption.alphabetical
                          ? 'Sort by Name'
                          : option == SortOption.priceLowToHigh
                          ? 'Price: Low to High'
                          : 'Discount: High to Low',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  );
                }).toList(),
                onChanged: (SortOption? newValue) {
                  if (newValue != null) {
                    ref.read(sortOptionProvider.notifier).state = newValue;
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
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

              // Sort the products based on the selected sort option
              final sortedProducts = _sortProducts(products, sortOption);

              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: sortedProducts.length,
                itemBuilder: (context, index) {
                  final product = sortedProducts[index];
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
              );
            },
          ),
        ),
      ],
    );
  }
}