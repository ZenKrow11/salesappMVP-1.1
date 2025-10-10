// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/color_utilities.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/components/ad_placeholder_widget.dart';

// --- Constants (Unchanged) ---
const double kHeaderVerticalPadding = 8.0;
const double kHeaderHeight = 44.0;
const double kStickyHeaderTotalHeight = kHeaderHeight + (kHeaderVerticalPadding * 2);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroups = ref.watch(homePageProductsProvider);
    final l10n = AppLocalizations.of(context)!;

    return asyncGroups.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(l10n.error(error.toString()))),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Text(l10n.noProductsFound),
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
        // ========== THE FIX IS HERE ==========
        // Change the loop to a standard 'for' loop to get an index 'i'.
        for (int i = 0; i < groups.length; i++) ...[
          // For convenience, we still create a 'group' variable for each iteration.
          SliverToBoxAdapter(
            child: _GroupHeader(
              style: groups[i].style,
              itemCount: groups[i].products.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            sliver: _buildSliverGrid(ref, groups, groups[i], paginationState),
          ),

          // --- AD PLACEMENT LOGIC ---
          // If a "Show More" button will be displayed for this group...
          if ((paginationState[groups[i].firestoreName] ?? kCollapsedItemLimit) < groups[i].products.length)
          // ...then show an ad banner just before it.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 16.0), // Added bottom padding
                child: AdPlaceholderWidget(adType: AdType.banner),
              ),
            ),

          // --- SHOW MORE BUTTON LOGIC ---
          // This if-condition is the same as the one for the ad above.
          if ((paginationState[groups[i].firestoreName] ?? kCollapsedItemLimit) < groups[i].products.length)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                // Now that 'i' exists, this code will work correctly.
                child: _ShowMoreButton(
                  totalItemCount: groups[i].products.length,
                  showingItemCount: paginationState[groups[i].firestoreName] ?? kCollapsedItemLimit,
                  onPressed: () {
                    ref.read(categoryPaginationProvider.notifier).update((state) {
                      final categoryKey = groups[i].firestoreName;
                      final newCount = (state[categoryKey] ?? kCollapsedItemLimit) + kPaginationIncrement;
                      return {...state, categoryKey: newCount};
                    });
                  },
                ),
              ),
            ),

          // I have removed the duplicate ad placement logic (if i == 0 || i == 2)
          // to match your request of placing the ad only before the "Show More" button.
        ],
      ],
    );
  }

  // This method and the widgets below are unchanged.
  Widget _buildSliverGrid(WidgetRef ref, List<ProductGroup> allGroups, ProductGroup group, Map<String, int> paginationState) {
    final categoryKey = group.firestoreName;
    final itemsToShowCount = paginationState[categoryKey] ?? kCollapsedItemLimit;
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
          return ProductTile(
            product: product,
            onTap: () {
              final flatSortedProducts = allGroups.expand((g) => g.products).toList();
              final initialIndex = flatSortedProducts.indexWhere((p) => p.id == product.id);

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

// --- The _GroupHeader and _ShowMoreButton widgets below are completely unchanged ---

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
              Expanded(
                child: AutoSizeText(
                  style.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  minFontSize: 14,
                  maxLines: 1,
                ),
              ),
              if (itemCount != null) ...[
                const SizedBox(width: 8),
                Text(
                  '[ $itemCount ]',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withAlpha(220),
                  ),
                ),
              ]
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: TextButton.icon(
          icon: Icon(Icons.expand_more, color: theme.secondary),
          label: Text(
            l10n.showMore(remainingCount),
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