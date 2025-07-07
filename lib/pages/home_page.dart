// lib/pages/home_page.dart

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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 400 && !_isFabVisible) {
      setState(() {
        _isFabVisible = true;
      });
    } else if (_scrollController.offset <= 400 && _isFabVisible) {
      setState(() {
        _isFabVisible = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

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
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList == null ? 'Select List' : 'List: $activeList';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: FloatingActionButton(
          onPressed: _isFabVisible ? _scrollToTop : null,
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.arrow_upward, size: 32.0),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(12.0, MediaQuery.of(context).padding.top / 4, 12.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =========================================================================
                // === MODIFICATION START: Replaced SizedBox with a Row for search + count ==
                // =========================================================================
                SizedBox(
                  height: 56,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. The Search Bar, wrapped in Expanded to take available space
                      const Expanded(
                        child: SearchBarWidget(),
                      ),
                      const SizedBox(width: 12),

                      // 2. The new count display widget. It watches the count provider.
                      Consumer(
                        builder: (context, ref, child) {
                          final asyncCount = ref.watch(productCountProvider);
                          return asyncCount.when(
                            loading: () => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.inactive),
                            ),
                            error: (err, stack) => const Icon(Icons.error_outline, color: Colors.red),
                            data: (count) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.inactive.withAlpha(128)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                '${count.filtered}/${count.total}',
                                style: const TextStyle(
                                  color: AppColors.inactive,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // =========================================================================
                // === MODIFICATION END ====================================================
                // =========================================================================
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary, size: 24.0),
                        label: Text(
                          buttonText,
                          style: const TextStyle(color: AppColors.inactive),
                          overflow: TextOverflow.ellipsis,
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
                        label: const Text(
                          'Filter and Sort',
                          style: TextStyle(color: AppColors.inactive),
                          overflow: TextOverflow.ellipsis,
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
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products match your filter.'));
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.95,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: ProductSwiperScreen(
                                products: products,
                                initialIndex: index,
                              ),
                            );
                          },
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