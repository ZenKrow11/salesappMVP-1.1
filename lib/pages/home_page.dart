// lib/pages/home_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_app_mvp/services/idle_precache_service.dart';
import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/color_utilities.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/search_bar_widget.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const double kHeaderTopPadding = 4.0;
const double kHeaderBottomPadding = 4.0;

final Map<String, CategoryStyle> _styleByDisplayName = () {
  final Map<String, CategoryStyle> map = {};
  for (final mainCat in allCategories) {
    map[mainCat.style.displayName] = mainCat.style;
  }
  map[defaultCategoryStyle.displayName] = defaultCategoryStyle;
  return map;
}();

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isFabVisible = false;
  bool _isScrollingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the context is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Give the service the context it needs to start its work.
        ref.read(idlePrecacheServiceProvider).setContext(context);
      }
    });
    // The scroll listener setup belongs here.
    _itemPositionsListener.itemPositions.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    // Notify the idle service of scroll activity.
    ref.read(idlePrecacheServiceProvider).onUserScroll();

    // The rest of the logic for FABs and active category.
    if (_isScrollingProgrammatically) return;
    if (!mounted) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final firstVisibleItem = positions.first;
    final shouldBeVisible = firstVisibleItem.index > 1;
    if (shouldBeVisible != _isFabVisible) {
      setState(() => _isFabVisible = shouldBeVisible);
    }
    final newActiveCategoryIndex = ((firstVisibleItem.index - 1) / 2).floor();
    if (newActiveCategoryIndex < 0) return;
    final currentActiveIndex = ref.read(currentCategoryIndexProvider);
    if (newActiveCategoryIndex != currentActiveIndex) {
      ref.read(currentCategoryIndexProvider.notifier).state = newActiveCategoryIndex;
    }
  }

  void _scrollToTop() {
    _itemScrollController.scrollTo(index: 0, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
  }

  void _scrollToBottom() {
    final groups = ref.read(homePageProductsProvider).value ?? [];
    if (groups.isNotEmpty) {
      final lastIndex = groups.length * 2;
      _itemScrollController.scrollTo(index: lastIndex, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
    }
  }

  void _skipUp() {
    if (_isScrollingProgrammatically) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final currentIndex = ref.read(currentCategoryIndexProvider);
    final currentHeaderIndex = (currentIndex * 2) + 1;
    final currentHeaderPos = positions.firstWhere((pos) => pos.index == currentHeaderIndex, orElse: () => positions.first);
    int targetItemIndex;
    if (currentHeaderPos.itemLeadingEdge < 0) {
      targetItemIndex = currentHeaderIndex;
    } else {
      final targetCategoryIndex = currentIndex - 1;
      if (targetCategoryIndex < 0) return;
      targetItemIndex = (targetCategoryIndex * 2) + 1;
    }
    _scrollToIndex(targetItemIndex);
  }

  void _skipDown() {
    if (_isScrollingProgrammatically) return;
    final headerOrder = (ref.read(homePageProductsProvider).value ?? []).map((g) => g.style.displayName).toList();
    if (headerOrder.isEmpty) return;
    final currentIndex = ref.read(currentCategoryIndexProvider);
    final targetCategoryIndex = currentIndex + 1;
    if (targetCategoryIndex >= headerOrder.length) return;
    final targetItemIndex = (targetCategoryIndex * 2) + 1;
    _scrollToIndex(targetItemIndex);
  }

  void _scrollToIndex(int index) {
    if (_isScrollingProgrammatically) return;
    setState(() { _isScrollingProgrammatically = true; });
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() { _isScrollingProgrammatically = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final asyncGroups = ref.watch(homePageProductsProvider);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: theme.primary,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildSearchBarAndCount(), const SizedBox(height: 0), _buildActionButtons()],
                ),
              ),
              Expanded(
                child: asyncGroups.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return const Center(child: Text('No products found matching your criteria.'));
                    }
                    return _ProductList(
                      groups: groups,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                    );
                  },
                ),
              ),
            ],
          ),
          _buildFabColumn(asyncGroups),
        ],
      ),
    );
  }

  Widget _buildFabColumn(AsyncValue<List<ProductGroup>> asyncGroups) {
    if (!asyncGroups.hasValue || (asyncGroups.value ?? []).isEmpty) { return const SizedBox.shrink(); }
    final groups = asyncGroups.value!;
    final headerOrder = groups.map((g) => g.style.displayName).toList();
    final currentIndex = ref.watch(currentCategoryIndexProvider);
    final theme = ref.watch(themeProvider);
    final isUpEnabled = currentIndex > 0;
    final isDownEnabled = currentIndex < headerOrder.length - 1;
    final Color fabUpBgColor;
    if (isUpEnabled) {
      fabUpBgColor = _styleByDisplayName[headerOrder[currentIndex]]?.color ?? theme.secondary;
    } else {
      fabUpBgColor = Colors.transparent;
    }
    final Color fabDownBgColor;
    if (isDownEnabled) {
      fabDownBgColor = _styleByDisplayName[headerOrder[currentIndex + 1]]?.color ?? theme.secondary;
    } else {
      fabDownBgColor = Colors.transparent;
    }
    return Align(
      alignment: const Alignment(1.0, 0.5),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: _isFabVisible ? _scrollToTop : null,
                onTap: _isFabVisible ? _skipUp : null,
                child: FloatingActionButton(
                  heroTag: 'skip_up',
                  onPressed: null,
                  backgroundColor: isUpEnabled ? fabUpBgColor : Colors.grey.shade400,
                  foregroundColor: getContrastColor(isUpEnabled ? fabUpBgColor : Colors.grey.shade400),
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onLongPress: _isFabVisible ? _scrollToBottom : null,
                onTap: _isFabVisible ? _skipDown : null,
                child: FloatingActionButton(
                  heroTag: 'skip_down',
                  onPressed: null,
                  backgroundColor: isDownEnabled ? fabDownBgColor : Colors.grey.shade400,
                  foregroundColor: getContrastColor(isDownEnabled ? fabDownBgColor : Colors.grey.shade400),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ],
          ),
        ),
      ),
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
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  const _ProductList({
    required this.groups,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedCategoryNames = ref.watch(expandedCategoriesProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productsRefresherProvider.notifier).refresh();
      },
      child: ScrollablePositionedList.builder(
        itemCount: (groups.length * 2) + 1,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox(height: 12);
          final groupIndex = ((index - 1) / 2).floor();
          if (groupIndex >= groups.length) return const SizedBox.shrink();
          final group = groups[groupIndex];
          final isHeader = (index - 1) % 2 == 0;
          if (isHeader) {
            return _GroupHeader(style: group.style);
          } else {
            const int collapsedItemLimit = 30;
            final bool isExpanded = expandedCategoryNames.contains(group.style.displayName);
            final List<Product> productsToShow = isExpanded
                ? group.products
                : group.products.take(collapsedItemLimit).toList();
            final bool canBeExpanded = group.products.length > collapsedItemLimit;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: productsToShow.length,
                    itemBuilder: (context, gridIndex) {
                      final product = productsToShow[gridIndex];
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
                  ),
                ),
                if (canBeExpanded && !isExpanded)
                  _ShowMoreButton(
                    totalItemCount: group.products.length,
                    showingItemCount: collapsedItemLimit,
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (!context.mounted) return;
                      ref.read(expandedCategoriesProvider.notifier).update((state) {
                        return {...state, group.style.displayName};
                      });
                    },
                  ),
                const SizedBox(height: 24.0),
              ],
            );
          }
        },
      ),
    );
  }
}

class _GroupHeader extends ConsumerWidget {
  const _GroupHeader({required this.style});
  final CategoryStyle style;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final backgroundColor = style.color;
    final textColor = getContrastColor(backgroundColor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kHeaderTopPadding, kHeaderBottomPadding, kHeaderTopPadding, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            style.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowMoreButton extends ConsumerStatefulWidget {
  final int totalItemCount;
  final int showingItemCount;
  final Future<void> Function() onPressed;
  const _ShowMoreButton({required this.totalItemCount, required this.showingItemCount, required this.onPressed});
  @override
  ConsumerState<_ShowMoreButton> createState() => _ShowMoreButtonState();
}

class _ShowMoreButtonState extends ConsumerState<_ShowMoreButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // This initState is ONLY for the button's animation controller.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = ref.watch(themeProvider);
    _colorAnimation = ColorTween(
      begin: theme.secondary.withOpacity(0.2),
      end: theme.secondary,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });
    _controller.forward();
    await widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final remainingCount = widget.totalItemCount - widget.showingItemCount;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return TextButton.icon(
            icon: _isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primary)))
                : Icon(Icons.expand_more, color: theme.primary),
            label: Text(
              _isLoading ? 'Loading...' : 'Show $remainingCount more',
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
            ),
            onPressed: _handleTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: _colorAnimation.value,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          );
        },
      ),
    );
  }
}