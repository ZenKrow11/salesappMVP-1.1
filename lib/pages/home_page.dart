// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sales_app_mvp/components/product_tile.dart';
// --- REMOVE `Product` import, as this page only deals with the plain version now ---
// import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/plain_product.dart'; // <-- IMPORT PlainProduct
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/color_utilities.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/models/category_style.dart';


const double kHeaderVerticalPadding = 8.0;
const double kHeaderHeight = 44.0;
const double kStickyHeaderTotalHeight = kHeaderHeight + (kHeaderVerticalPadding * 2);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroups = ref.watch(homePageProductsProvider);

    return asyncGroups.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (groups) {
        if (groups.isEmpty) {
          return const Center(
            child: Text('No products found matching your criteria.'),
          );
        }
        return _ProductList(groups: groups);
      },
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
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: _GroupHeader(
              style: group.style,
              itemCount: group.products.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            // --- FIX A: Pass the full `groups` list for the onTap handler ---
            sliver: _buildSliverGrid(ref, groups, group, paginationState),
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
        ],
      ],
    );
  }

  Widget _buildSliverGrid(WidgetRef ref, List<ProductGroup> allGroups, ProductGroup group, Map<String, int> paginationState) {
    final categoryName = group.style.displayName;
    final itemsToShowCount = paginationState[categoryName] ?? kCollapsedItemLimit;

    // --- FIX B: (Error at line 97) `productsToShow` is now of type `List<PlainProduct>` ---
    final List<PlainProduct> productsToShow = group.products.take(itemsToShowCount).toList();

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

          // You will need to update ProductTile to accept a `PlainProduct`
          return ProductTile(
            product: product,
            onTap: () {
              // --- FIX C: `flatSortedProducts` is now of type `List<PlainProduct>` ---
              final flatSortedProducts = allGroups.expand((g) => g.products).toList();
              final initialIndex = flatSortedProducts.indexWhere((p) => p.id == product.id);

              // --- FIX D: (Error at line 116) `ProductSwiperScreen` must accept a `List<PlainProduct>` ---
              final Widget swiperPage = ProductSwiperScreen(
                products: flatSortedProducts,
                initialIndex: initialIndex != -1 ? initialIndex : 0,
              );

              Navigator.of(context).push(SlideUpPageRoute(
                page: swiperPage,
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
        padding: const EdgeInsets.symmetric(
            vertical: kHeaderVerticalPadding, horizontal: 8.0),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
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
                    color: textColor.withAlpha(220),
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

    return Center(
      child: Padding(
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
      ),
    );
  }
}