import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/components/filter_bottom_sheet.dart'; // UPDATED import
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/search_bar_widget.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart'; // NEW import

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
    if (!mounted) return;
    final shouldBeVisible = _scrollController.offset > 400;
    if (shouldBeVisible != _isFabVisible) {
      setState(() => _isFabVisible = shouldBeVisible);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final fetchStatus = ref.watch(productFetchProvider);
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
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBarAndCount(),
                const SizedBox(height: 12),
                _buildActionButtons(buttonText),
              ],
            ),
          ),
          Expanded(
            child: fetchStatus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (_) {
                final groups = ref.watch(groupedProductsProvider);
                if (groups.isEmpty) {
                  return const Center(child: Text('No products found.'));
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

  Widget _buildSearchBarAndCount() {
    return SizedBox(
      height: 56,
      child: SearchBarWidget(
        trailing: Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(productCountProvider);
            return ItemCountWidget(
              filtered: count.filtered,
              total: count.total,
            );
          },
        ),
      ),
    );
  }

  // --- HEAVILY MODIFIED TO SPLIT BUTTONS ---
  Widget _buildActionButtons(String buttonText) {
    return Row(
      children: [
        Expanded(
          flex: 2, // Give more space to the list name
          child: TextButton.icon(
            icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary, size: 24.0),
            label: Text(buttonText, style: const TextStyle(color: AppColors.inactive), overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet((_) => const ShoppingListBottomSheet(), isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2, // Give less space to the filter button
          child: TextButton.icon(
            icon: const Icon(Icons.filter_alt, color: AppColors.secondary, size: 24.0),
            label: const Text('Filter', style: TextStyle(color: AppColors.inactive), overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet((_) => const FilterBottomSheet(), isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          flex: 1, // Give less space to the sort button
          child: SortButton(), // Use the new modular widget
        ),
      ],
    );
  }

  ButtonStyle _actionButtonStyle() {
    return TextButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }

  void _showModalSheet(Widget Function(BuildContext) builder, {bool isScrollControlled = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent, // Important for custom border radius
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }

  // The rest of the HomePage widget remains the same...
  // _buildProductGroupSlivers, _GroupHeader, etc. are unchanged.

  List<Widget> _buildProductGroupSlivers(List<ProductGroup> groups) {
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ...groups.expand((group) => [
        SliverToBoxAdapter(child: _GroupHeader(style: group.style)),
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
                    final flatSortedProducts = groups.expand((g) => g.products).toList();
                    final initialIndex = flatSortedProducts.indexWhere((p) => p.id == product.id);
                    Navigator.of(context).push(
                      SlideUpPageRoute(
                        page: ProductSwiperScreen(
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
      ]),
    ];
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.style});
  final CategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 26),
          const SizedBox(width: 12),
          Text(style.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: style.color)),
        ],
      ),
    );
  }
}