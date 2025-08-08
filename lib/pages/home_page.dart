// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';

import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

import 'package:sales_app_mvp/widgets/color_utilities.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/search_bar_widget.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart';

import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/category_style.dart';


const double kHeaderVerticalPadding = 8.0;
const double kHeaderHeight = 44.0;
const double kStickyHeaderTotalHeight = kHeaderHeight + (kHeaderVerticalPadding * 2);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final asyncGroups = ref.watch(homePageProductsProvider);

    return Column(
      children: [
        Container(
          color: theme.primary,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildSearchBarAndCount(), _buildActionButtons()],
          ),
        ),
        Expanded(
          child: asyncGroups.when(
            // ADDED BACK: The required loading handler
            loading: () => const Center(child: CircularProgressIndicator()),

            // ADDED BACK: The required error handler
            error: (error, stack) => Center(child: Text('Error: $error')),

            // The data handler remains the same
            data: (groups) {
              if (groups.isEmpty) {
                return const Center(child: Text('No products found matching your criteria.'));
              }
              return _ProductList(groups: groups);
            },
          ),
        ),
      ],
    );
  }


  Widget _buildSearchBarAndCount() {
    return SizedBox(
      height: 50,
      child: SearchBarWidget(
        hasBorder: false,
        trailing: Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(homePageProductsProvider).whenData((groups) {
              final filtered = groups.fold<int>(0, (sum, group) => sum + group.products.length);
              final total = ref.read(initialProductsProvider).value?.length ?? 0;
              return ProductCount(filtered: filtered, total: total);
            }).value ?? ProductCount(filtered: 0, total: 0);
            return ItemCountWidget(filtered: count.filtered, total: count.total);
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = ref.watch(themeProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: Icon(Icons.add_shopping_cart, color: theme.secondary, size: 24.0),
            label: Text(buttonText, style: TextStyle(color: theme.inactive), overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet((_) => const ShoppingListBottomSheet(), isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: theme.background.withOpacity(0.5)),
        Expanded(
          child: TextButton.icon(
            icon: Icon(Icons.filter_alt, color: theme.secondary, size: 24.0),
            label: Text('Filter', style: TextStyle(color: theme.inactive), overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet((_) => const FilterBottomSheet(), isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: theme.background.withOpacity(0.5)),
        const Expanded(child: SortButton()),
      ],
    );
  }

  ButtonStyle _actionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  void _showModalSheet(Widget Function(BuildContext) builder, {bool isScrollControlled = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
}

class _ProductList extends ConsumerWidget {
  final List<ProductGroup> groups;

  const _ProductList({required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginationState = ref.watch(categoryPaginationProvider);

    return CustomScrollView(
      slivers: [
        // The for-loop now directly adds the slivers to the CustomScrollView
        for (final group in groups) ...[
          // REMOVED the MultiSliver wrapper from here
          SliverToBoxAdapter(
            child: _GroupHeader(
              style: group.style,
              itemCount: group.products.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            sliver: _buildSliverGrid(ref, group, paginationState),
          ),
          if ((paginationState[group.style.displayName] ?? kCollapsedItemLimit) < group.products.length)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _ShowMoreButton(
                  totalItemCount: group.products.length,
                  showingItemCount: paginationState[group.style.displayName] ?? kCollapsedItemLimit,
                  onPressed: () {
                    ref.read(categoryPaginationProvider.notifier).update((state) {
                      final categoryName = group.style.displayName;
                      final newCount = (state[categoryName] ?? kCollapsedItemLimit) + kPaginationIncrement;
                      return {...state, categoryName: newCount};
                    });
                  },
                ),
              ),
            ),
          // REMOVED the closing of MultiSliver
        ],
      ],
    );
  }

  Widget _buildSliverGrid(WidgetRef ref, ProductGroup group, Map<String, int> paginationState) {
    final categoryName = group.style.displayName;
    final itemsToShowCount = paginationState[categoryName] ?? kCollapsedItemLimit;
    final List<Product> productsToShow = group.products.take(itemsToShowCount).toList();

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, gridIndex) {
          final product = productsToShow[gridIndex];
          return ProductTile(
            product: product,
            onTap: () {
              final flatSortedProducts = groups.expand((g) => g.products).toList();
              final initialIndex = flatSortedProducts.indexWhere((p) => p.id == product.id);

              // Use a variable to hold the widget instance before passing it to the route.
              // This often helps the Dart analyzer resolve types correctly.
              final Widget swiperPage = ProductSwiperScreen(
                products: flatSortedProducts,
                initialIndex: initialIndex != -1 ? initialIndex : 0,
              );

              Navigator.of(context).push(SlideUpPageRoute(
                page: swiperPage, // Now pass the variable
              ));
            },
          );
        },
        childCount: productsToShow.length,
      ),
    );
  }
}

class _GroupHeader extends ConsumerWidget {
  const _GroupHeader({required this.style, this.itemCount});
  final CategoryStyle style;
  final int? itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final textColor = getContrastColor(style.color);

    return Material(
      color: theme.pageBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kHeaderVerticalPadding, horizontal: 8.0),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // REPLACED Icon with SvgPicture
              SvgPicture.asset(
                style.iconAssetPath,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Text(
                style.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (itemCount != null)
                Text(
                  '[ $itemCount ]',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowMoreButton extends ConsumerWidget {
  final int totalItemCount;
  final int showingItemCount;
  final VoidCallback onPressed;

  const _ShowMoreButton({
    required this.totalItemCount,
    required this.showingItemCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final remainingCount = totalItemCount - showingItemCount;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextButton.icon(
        icon: Icon(Icons.expand_more, color: theme.secondary),
        label: Text(
          'Show $remainingCount more',
          style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: theme.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
