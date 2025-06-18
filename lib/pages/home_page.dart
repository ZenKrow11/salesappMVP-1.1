import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/product_detail_overlay.dart';
import '../components/product_tile.dart'; // Adjust path if needed
import '../filters/filter_sheet.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../search/search_bar.dart';
import '../providers/filtered_product_provider.dart';
import '../providers/sort_provider.dart';

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
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  childAspectRatio: 0.85, // Adjust to fit the three-row layout
                  children: products.map((product) {
                    return ProductTile(
                      product: product,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => Consumer(
                            builder: (context, ref, _) {
                              return ProductDetailOverlay(product: product);
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
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

// Ensure ProductTile matches the structure used in ProductDetailOverlay
class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Store name and Product name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product.store,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            // Second row: Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 100,
                child: (product.imageUrl.isEmpty || !(Uri.tryParse(product.imageUrl)?.hasAbsolutePath ?? false))
                    ? const Center(child: Text("Placeholder Picture"))
                    : Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text("Placeholder Picture"));
                  },
                ),
              ),
            ),
            // Third row: Price details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    '${product.normalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.discountPercentage}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}