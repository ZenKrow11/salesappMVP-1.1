// C:\Users\patri\AndroidStudioProjects\salesappMVP-1.2\lib\pages\home_page.dart

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
import 'package:sales_app_mvp/models/list_item.dart';

const double kHeaderVerticalPadding = 8.0;
const double kHeaderHeight = 44.0;

final unifiedListProvider = Provider.autoDispose<List<ListItem>>((ref) {
  final asyncGroups = ref.watch(homePageProductsProvider);
  final paginationState = ref.watch(categoryPaginationProvider);
  const int adInterval = 8;

  if (asyncGroups.hasValue) {
    final groups = asyncGroups.value!;
    final List<ListItem> unifiedItems = [];
    for (var group in groups) {
      unifiedItems.add(HeaderListItem(group));
      final itemsToShowCount =
          paginationState[group.firestoreName] ?? kCollapsedItemLimit;
      final productsToShow = group.products.take(itemsToShowCount).toList();
      int productCountForAd = 0;
      for (int i = 0; i < productsToShow.length; i++) {
        final product = productsToShow[i];
        unifiedItems.add(ProductListItem(product));
        productCountForAd++;
        if (productCountForAd >= adInterval &&
            i < productsToShow.length - 1) {
          unifiedItems.add(AdListItem());
          productCountForAd = 0;
        }
      }
      if (group.products.length > itemsToShowCount) {
        unifiedItems.add(ShowMoreListItem(group));
      }
    }
    return unifiedItems;
  }
  return [];
}, dependencies: [homePageProductsProvider, categoryPaginationProvider]);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ProviderScope(
      overrides: [localizationProvider.overrideWithValue(l10n)],
      child: Consumer(builder: (context, ref, _) {
        final asyncGroups = ref.watch(homePageProductsProvider);
        return asyncGroups.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(l10n.error(error.toString()))),
          data: (groups) {
            if (groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(l10n.noProductsFound,
                      textAlign: TextAlign.center),
                ),
              );
            }
            return _ProductList(allProductGroups: groups);
          },
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Refactored _ProductList with linked Scrollbar
// ---------------------------------------------------------------------------

class _ProductList extends ConsumerStatefulWidget {
  final List<ProductGroup> allProductGroups;
  const _ProductList({required this.allProductGroups});

  @override
  ConsumerState<_ProductList> createState() => _ProductListState();
}

class _ProductListState extends ConsumerState<_ProductList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unifiedList = ref.watch(unifiedListProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final allProductsForSwiper = widget.allProductGroups
        .expand((group) => group.products)
        .map((p) => PlainProduct.fromProduct(p))
        .toList();

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(theme.secondary.withOpacity(0.7)),
        radius: const Radius.circular(4),
        thickness: MaterialStateProperty.all(6.0),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: false, // visible only when user scrolls
        interactive: true,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: _buildSlivers(
              context, ref, unifiedList, allProductsForSwiper, l10n),
        ),
      ),
    );
  }
  // ---------------------------------------------------------------------------
  // Sliver builders remain identical
  // ---------------------------------------------------------------------------

  List<Widget> _buildSlivers(
      BuildContext context,
      WidgetRef ref,
      List<ListItem> unifiedList,
      List<PlainProduct> allProductsForSwiper,
      AppLocalizations l10n) {
    final List<Widget> slivers = [];
    if (unifiedList.isEmpty) return slivers;

    for (int i = 0; i < unifiedList.length; i++) {
      final item = unifiedList[i];
      if (item is HeaderListItem) {
        slivers.add(_buildHeaderSliver(item, l10n));
      } else if (item is AdListItem) {
        slivers.add(_buildAdSliver());
      } else if (item is ShowMoreListItem) {
        slivers.add(_buildShowMoreSliver(ref, item));
      } else if (item is ProductListItem) {
        final productItemsProcessed = _buildProductGridSliver(
          context,
          slivers,
          unifiedList,
          i,
          allProductsForSwiper,
        );
        i += productItemsProcessed - 1;
      }
    }
    return slivers;
  }

  Widget _buildHeaderSliver(HeaderListItem item, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: _GroupHeader(group: item.group, l10n: l10n),
    );
  }

  Widget _buildAdSliver() {
    return const SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      sliver: SliverToBoxAdapter(child: AdPlaceholderWidget()),
    );
  }

  Widget _buildShowMoreSliver(WidgetRef ref, ShowMoreListItem item) {
    return SliverToBoxAdapter(
      child: _ShowMoreButton(
        totalItemCount: item.group.products.length,
        showingItemCount: ref.watch(
            categoryPaginationProvider)[item.group.firestoreName] ??
            kCollapsedItemLimit,
        onPressed: () {
          ref.read(categoryPaginationProvider.notifier).update((state) {
            final categoryKey = item.group.firestoreName;
            final newCount =
                (state[categoryKey] ?? kCollapsedItemLimit) +
                    kPaginationIncrement;
            return {...state, categoryKey: newCount};
          });
        },
      ),
    );
  }

  int _buildProductGridSliver(
      BuildContext context,
      List<Widget> slivers,
      List<ListItem> unifiedList,
      int startIndex,
      List<PlainProduct> allProductsForSwiper) {
    final productChunk = <PlainProduct>[];
    int currentIndex = startIndex;
    while (currentIndex < unifiedList.length &&
        unifiedList[currentIndex] is ProductListItem) {
      productChunk
          .add((unifiedList[currentIndex] as ProductListItem).product);
      currentIndex++;
    }
    slivers.add(SliverPadding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.7,
        ),
        itemCount: productChunk.length,
        itemBuilder: (context, gridIndex) {
          final product = productChunk[gridIndex];
          return ProductTile(
            product: product,
            onTap: () {
              final initialIndex =
              allProductsForSwiper.indexWhere((p) => p.id == product.id);
              if (initialIndex != -1) {
                Navigator.of(context).push(SlidePageRoute(
                  page: ProductSwiperScreen(
                    products: allProductsForSwiper,
                    initialIndex: initialIndex,
                  ),
                  direction: SlideDirection.rightToLeft,
                ));
              }
            },
          );
        },
      ),
    ));
    return productChunk.length;
  }
}

// ---------------------------------------------------------------------------
// UI Components (headers, show more button) unchanged
// ---------------------------------------------------------------------------

class _GroupHeader extends ConsumerWidget {
  final ProductGroup group;
  final AppLocalizations l10n;
  const _GroupHeader({required this.group, required this.l10n});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final localizedStyle = group.style;
    final textColor = getContrastColor(localizedStyle.color);
    return Material(
      color: theme.pageBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kHeaderVerticalPadding),
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
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: TextButton.icon(
          icon: Icon(Icons.expand_more, color: theme.secondary),
          label: Text(
            l10n.showMore(remainingCount),
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.bold,
            ),
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
