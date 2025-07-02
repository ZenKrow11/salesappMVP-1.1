import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider imports
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';

// Component and Screen imports
// --- IMPORTANT: Import your new sheet ---
import 'package:sales_app_mvp/components/active_list_selector_bottom_sheet.dart';
import 'package:sales_app_mvp/components/filter_sort_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/search_bar.dart';
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // FIX: This makes the sheet appear above the nav bar
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return const FilterSortBottomSheet();
      },
    );
  }

  // --- REFACTORED: This now calls the correct sheet ---
  void _showActiveListSelector() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // FIX: This makes the sheet appear above the nav bar
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Call the new, correct bottom sheet
        return const ActiveListSelectorBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The rest of the build method is the same as the last correct version
    final productsAsyncState = ref.watch(productsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList == null ? 'Select List' : 'Active: $activeList';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(
              12.0,
              MediaQuery.of(context).padding.top + 10,
              12.0,
              12.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SearchBarWidget(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.list, color: AppColors.secondary, size: 24.0),
                        label: Flexible(
                          child: Text(
                            buttonText,
                            style: const TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: _showActiveListSelector,
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
                            'Filter & Sort',
                            style: TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: _showFilterSheet,
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
            child: productsAsyncState.when(
              data: (productState) {
                if (productState.products.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: productState.products.length + (productState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= productState.products.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final product = productState.products[index];
                    return ProductTile(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductSwiperScreen(
                              products: productState.products,
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