import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider imports
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';

// Component and Screen imports
import 'package:sales_app_mvp/components/active_list_selector_bottom_sheet.dart';
import 'package:sales_app_mvp/components/filter_sort_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/search_bar.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// The page is a simpler ConsumerWidget.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => const FilterSortBottomSheet(),
    );
  }

  void _showActiveListSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const ActiveListSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the new provider.
    final productsAsync = ref.watch(filteredProductsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList == null ? 'Select List' : 'Selected: $activeList';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // The header UI remains the same.
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(12.0, MediaQuery.of(context).padding.top / 4, 12.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 56, child: SearchBarWidget()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary, size: 24.0),
                        label: Flexible(
                          child: Text(
                            buttonText,
                            style: const TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () => _showActiveListSelector(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: AppColors.inactive.withAlpha(128)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.filter_alt, color: AppColors.secondary, size: 24.0),
                        label: const Flexible(
                          child: Text(
                            'Filter and Sort',
                            style: TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () => _showFilterSheet(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: AppColors.inactive.withAlpha(128)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            // THE FIX IS HERE: The .when() callback now works correctly.
            child: productsAsync.when(
              // The 'data' parameter is now a 'List<Product>', which we name 'products'.
              data: (products) {
                // We check 'products.isEmpty' directly.
                if (products.isEmpty) {
                  return const Center(child: Text('No products match your filter.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  // We use 'products.length' directly.
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    // We get the product from the 'products' list directly.
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductSwiperScreen(
                              products: products, // Pass the 'products' list.
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Failed to load products: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}