// lib/pages/home_page.dart

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
        unifiedItems.add(ShowMoreListItem(group, canLoadMore: true));
      } else if (itemsToShowCount > kCollapsedItemLimit) {
        unifiedItems.add(ShowMoreListItem(group, canLoadMore: false));
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

class _ProductList extends ConsumerStatefulWidget {
  final List<ProductGroup> allProductGroups;
  const _ProductList({required this.allProductGroups});

  @override
  ConsumerState<_ProductList> createState() => _ProductListState();
}

class _ProductListState extends ConsumerState<_ProductList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _headerKeys = {};

  @override
  void initState() {
    super.initState();
    for (final group in widget.allProductGroups) {
      _headerKeys[group.firestoreName] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- REVERTED TO A SIMPLER "SCROLL-TO-TOP" METHOD ---
  // This is now acceptable because the collapse action is more drastic.
  void _scrollToHeader(GlobalKey headerKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = headerKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.05, // Aligns to the top with a small padding
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The ref.listen block has been removed as it's no longer needed.
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
        thumbVisibility: false,
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

  List<Widget> _buildSlivers(
      BuildContext context,
      WidgetRef ref,
      List<ListItem> unifiedList,
      List<PlainProduct> allProductsForSwiper,
      AppLocalizations l10n) {
    // This method's implementation remains the same...
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
      key: _headerKeys[item.group.firestoreName],
      child: _GroupHeader(group: item.group, l10n: l10n),
    );
  }

  Widget _buildAdSliver() {
    // ... implementation remains the same
    return const SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      sliver: SliverToBoxAdapter(child: AdPlaceholderWidget()),
    );
  }

  Widget _buildShowMoreSliver(WidgetRef ref, ShowMoreListItem item) {
    final categoryKey = item.group.firestoreName;
    final headerKey = _headerKeys[categoryKey]!;

    return SliverToBoxAdapter(
      child: _LoadMoreControl(
        totalItemCount: item.group.products.length,
        showingItemCount: ref.watch(categoryPaginationProvider)[categoryKey] ?? kCollapsedItemLimit,
        canLoadMore: item.canLoadMore,
        // --- THE onCollapse ACTION IS NOW USED FOR THE SINGLE TAP ---
        onCollapse: () {
          _scrollToHeader(headerKey); // Scroll to the top of the section
          ref.read(categoryPaginationProvider.notifier).reset(categoryKey); // Reset the state
        },
        onShowMore: () => ref.read(categoryPaginationProvider.notifier).increase(categoryKey),
      ),
    );
  }

  int _buildProductGridSliver(
      // ... implementation remains the same
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

// The button widget itself does not need any changes.
class _LoadMoreControl extends ConsumerWidget {
  final int totalItemCount;
  final int showingItemCount;
  final bool canLoadMore;
  final VoidCallback onShowMore;
  final VoidCallback onCollapse; // The only "show less" action now

  const _LoadMoreControl({
    required this.totalItemCount,
    required this.showingItemCount,
    required this.canLoadMore,
    required this.onShowMore,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final remainingCount = totalItemCount - showingItemCount;
    final bool canShowLess = showingItemCount > kCollapsedItemLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          // This border is now handled by the inner elements
          // to achieve the desired visual separation without an outer frame.
          border: Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Row(
            children: [
              if (canShowLess)
                Expanded(
                  flex: 1,
                  child: Material(
                    color: theme.accent,
                    child: InkWell(
                      // --- A SIMPLE TAP NOW TRIGGERS THE FULL COLLAPSE ---
                      onTap: onCollapse,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: theme.secondary.withOpacity(0.5), width: 1.5),
                          ),
                        ),
                        child: Icon(Icons.expand_less, color: theme.primary),
                      ),
                    ),
                  ),
                ),
              if (canLoadMore)
                Expanded(
                  flex: 4,
                  child: Material(
                    color: theme.secondary,
                    child: InkWell(
                      onTap: onShowMore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.showMore(remainingCount.clamp(0, 1000)),
                              style: TextStyle(
                                color: theme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.expand_more, color: theme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}