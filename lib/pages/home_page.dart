import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider and Model imports
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
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
  // All state variables and helper functions remain the same.
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
    if (!mounted) return;
    final shouldBeVisible = _scrollController.offset > 400;
    if (shouldBeVisible != _isFabVisible) {
      setState(() {
        _isFabVisible = shouldBeVisible;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (context) => const FilterSortBottomSheet(),
    );
  }

  void _showActiveListSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const ActiveListSelectorBottomSheet(),
    );
  }

  // --- THIS IS THE FULLY REFACTORED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Watch the providers needed for the static UI parts.
    final allProductsAsync = ref.watch(allProductsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';

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
          // This container holds the top UI elements that should always be visible,
          // even during loading.
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBarAndCount(), // Call the helper method
                const SizedBox(height: 12),
                _buildActionButtons(buttonText), // Call the helper method
              ],
            ),
          ),
          // This Expanded section handles the loading/error/data states
          // for the product list itself.
          Expanded(
            child: allProductsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load products: $error')),
              data: (allProductsData) {
                // Once the main data is loaded, we watch the transformed data.
                final groups = ref.watch(groupedProductsProvider);
                if (groups.isEmpty) {
                  // This correctly handles the "no results" state after filtering.
                  return const Center(
                      child: Text('No products match your filter.'));
                }
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: _buildProductGroupSlivers(groups),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for the search bar and product count.
  // This now uses the corrected productCountProvider logic.
  Widget _buildSearchBarAndCount() {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: SearchBarWidget()),
          const SizedBox(width: 12),
          Consumer(
            builder: (context, ref, child) {
              // Watch the synchronous provider directly.
              final count = ref.watch(productCountProvider);
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inactive.withAlpha(128)),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text('${count.filtered}/${count.total}',
                    style: const TextStyle(
                        color: AppColors.inactive,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method for the action buttons (unchanged).
  Widget _buildActionButtons(String buttonText) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.add_shopping_cart,
                color: AppColors.secondary, size: 24.0),
            label: Text(buttonText,
                style: const TextStyle(color: AppColors.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showActiveListSelector(context),
            style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: AppColors.inactive.withAlpha(128)))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.filter_alt,
                color: AppColors.secondary, size: 24.0),
            label: const Text('Filter and Sort',
                style: TextStyle(color: AppColors.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showFilterSheet(context),
            style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: AppColors.inactive.withAlpha(128)))),
          ),
        ),
      ],
    );
  }

  // Helper method for building the product list (unchanged).
  List<Widget> _buildProductGroupSlivers(List<ProductGroup> groups) {
    final List<Widget> slivers = [];
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

    for (final group in groups) {
      slivers.add(SliverToBoxAdapter(child: _GroupHeader(style: group.style)));
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final product = group.products[index];
                return ProductTile(
                  product: product,
                  onTap: () {
                    final flatSortedProducts =
                    groups.expand((g) => g.products).toList();
                    final initialIndex =
                    flatSortedProducts.indexWhere((p) => p.id == product.id);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        height: MediaQuery.of(context).size.height * 0.95,
                        decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                        child: ProductSwiperScreen(
                          products: flatSortedProducts,
                          initialIndex: initialIndex != -1 ? initialIndex : 0,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: group.products.length,
            ),
          ),
        ),
      );
    }
    return slivers;
  }
}

// Private helper widget for group headers (unchanged).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.style});
  final CategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 26),
          const SizedBox(width: 12),
          Text(style.displayName,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: style.color)),
        ],
      ),
    );
  }
}