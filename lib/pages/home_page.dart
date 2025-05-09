import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/product_tile.dart';
import '../filters/filter_sheet.dart';
import '../providers/product_provider.dart';
import '../search/search_bar.dart';
import '../providers/filtered_product_provider.dart';
import '../providers/sort_provider.dart'; // <-- Make sure this import exists

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final sortNotifier = ref.read(sortOptionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Column(
        children: [
          const SearchBarWidget(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<SortOption>(
                  value: sortOption,
                  onChanged: (value) {
                    if (value != null) {
                      sortNotifier.state = value;
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.alphabeticalStore,
                      child: Text('Alphabetical by Store'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.alphabetical,
                      child: Text('Alphabetical'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.priceLowToHigh,
                      child: Text('Price: Low → High'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.discountHighToLow,
                      child: Text('Discount: High → Low'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No sales items available.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductTile(product: products[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading products: $error'),
                    ElevatedButton(
                      onPressed: () => ref.refresh(productsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => const FilterSheet(),
          );
        },
        child: const Icon(Icons.filter_alt),
      ),
    );
  }
}
