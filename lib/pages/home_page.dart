import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/color_utilities.dart';
import 'package:sales_app_mvp/widgets/slide_in_page_route.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/components/ad_placeholder_widget.dart';

const double kHeaderVerticalPadding = 8.0;
const double kHeaderHeight = 44.0;

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
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        for (var group in groups) ...[
          SliverToBoxAdapter(
            child: _GroupHeader(
              group: group,
              l10n: l10n,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            sliver: _buildSliverGrid(ref, groups, group, paginationState),
          ),
          if ((paginationState[group.firestoreName] ?? kCollapsedItemLimit) < group.products.length)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 16.0),
                child: AdPlaceholderWidget(),
              ),
            ),
          if ((paginationState[group.firestoreName] ?? kCollapsedItemLimit) < group.products.length)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _ShowMoreButton(
                  totalItemCount: group.products.length,
                  showingItemCount: paginationState[group.firestoreName] ?? kCollapsedItemLimit,
                  onPressed: () {
                    ref.read(categoryPaginationProvider.notifier).update((state) {
                      final categoryKey = group.firestoreName;
                      final newCount = (state[categoryKey] ?? kCollapsedItemLimit) + kPaginationIncrement;
                      return {...state, categoryKey: newCount};
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

              Navigator.of(context).push(SlidePageRoute(
                page: ProductSwiperScreen(
                  products: flatSortedProducts,
                  initialIndex: initialIndex != -1 ? initialIndex : 0,
                ),
                direction: SlideDirection.rightToLeft,
              ));
            },
          );
        },
        childCount: productsToShow.length,
      ),
    );
  }
}

// ... (Rest of the file is unchanged and correct)
class _GroupHeader extends ConsumerWidget {
  final ProductGroup group;
  final AppLocalizations l10n;

  const _GroupHeader({required this.group, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final localizedStyle = CategoryService.getLocalizedStyleForGroupingName(group.firestoreName, l10n);
    final textColor = getContrastColor(localizedStyle.color);

    return Material(
      color: theme.pageBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kHeaderVerticalPadding, horizontal: 8.0),
        child: Container(
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: localizedStyle.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                localizedStyle.iconAssetPath,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  localizedStyle.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  minFontSize: 14,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '[ ${group.products.length} ]',
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