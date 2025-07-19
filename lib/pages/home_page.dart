import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  bool _isFabVisible = false;
  List<String> _headerOrder = [];
  final Map<String, CategoryStyle> _styleByDisplayName = _getStyleByDisplayName();

  static Map<String, CategoryStyle> _getStyleByDisplayName() {
    final Map<String, CategoryStyle> map = {};
    for (final mainCat in allCategories) {
      map[mainCat.style.displayName] = mainCat.style;
    }
    map[defaultCategoryStyle.displayName] = defaultCategoryStyle;
    return map;
  }

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final firstVisibleItem = positions.first.index;
    final shouldBeVisible = firstVisibleItem > 1;
    if (shouldBeVisible != _isFabVisible) {
      setState(() => _isFabVisible = shouldBeVisible);
    }

    // List structure is [SizedBox, Header, Grid, Header, Grid, ...]
    // So the category index is based on the item index.
    final newActiveCategoryIndex = ((firstVisibleItem - 1) / 2).floor();

    final currentActiveIndex = ref.read(currentCategoryIndexProvider);
    if (newActiveCategoryIndex != currentActiveIndex) {
      ref.read(currentCategoryIndexProvider.notifier).state = newActiveCategoryIndex;
    }
  }

  void _scrollToTop() {
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  // lib/pages/home_page.dart

  void _scrollToBottom() {
    // 1. Read the AsyncValue object from the provider.
    final asyncGroups = ref.read(groupedProductsProvider);

    // 2. Access the actual data using .value and handle the case where it might be null
    //    (e.g., if it's still loading or has an error). The `?? []` provides a safe default.
    final groups = asyncGroups.value ?? [];

    if (groups.isNotEmpty) {
      // The rest of your logic is correct and remains unchanged.
      // The last item is the final grid, whose index is total groups * 2
      final lastIndex = groups.length * 2;
      _itemScrollController.scrollTo(
        index: lastIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToCategory({required bool down}) {
    final currentIndex = ref.read(currentCategoryIndexProvider);
    final totalCategories = _headerOrder.length;
    final targetCategoryIndex = down ? currentIndex + 1 : currentIndex - 1;

    if (targetCategoryIndex >= 0 && targetCategoryIndex < totalCategories) {
      // The item index for a header is (categoryIndex * 2) + 1
      final targetItemIndex = (targetCategoryIndex * 2) + 1;
      _itemScrollController.scrollTo(
        index: targetItemIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final fetchStatus = ref.watch(productsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';

    final currentIndex = ref.watch(currentCategoryIndexProvider);
    final totalCategories = _headerOrder.length;
    final defaultFabColor = theme.secondary;
    final disabledFabColor = Colors.grey.shade400;

    final bool isUpEnabled = currentIndex > 0;
    final Color fabUpBgColor;
    if (isUpEnabled) {
      final prevCategoryName = _headerOrder[currentIndex];
      fabUpBgColor = _styleByDisplayName[prevCategoryName]?.color ?? defaultFabColor;
    } else {
      fabUpBgColor = disabledFabColor;
    }
    final fabUpFgColor = getContrastColor(fabUpBgColor);

    final bool isDownEnabled = totalCategories > 0 && currentIndex < totalCategories - 1;
    final Color fabDownBgColor;
    if (isDownEnabled) {
      final nextCategoryName = _headerOrder[currentIndex + 1];
      fabDownBgColor = _styleByDisplayName[nextCategoryName]?.color ?? defaultFabColor;
    } else {
      fabDownBgColor = disabledFabColor;
    }
    final fabDownFgColor = getContrastColor(fabDownBgColor);

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
                  children: [
                    _buildSearchBarAndCount(),
                    const SizedBox(height: 0),
                    _buildActionButtons(buttonText),
                  ],
                ),
              ),
              Expanded(
                child: fetchStatus.when(
                  // When fetching from Firebase, show a main loading indicator
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error fetching products: $error')),
                  data: (_) {
                    // NOW, we watch the groupedProductsProvider. It will run in the background.
                    final asyncGroups = ref.watch(groupedProductsProvider);

                    // We use another .when() to handle the states of the grouping/sorting process
                    return asyncGroups.when(
                      // While grouping/sorting, show a loading indicator. This will be very brief.
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error grouping products: $error')),
                      data: (groups) {
                        // --- THIS IS YOUR ORIGINAL UI LOGIC, NOW SAFELY IN THE `data` CASE ---
                        if (groups.isEmpty) {
                          return const Center(child: Text('No products found matching your criteria.'));
                        }

                        // This setState call inside build can be problematic. Let's move it.
                        // It's better to derive this directly inside the build method.
                        // _headerOrder = groups.map((g) => g.style.displayName).toList();
                        final headerOrder = groups.map((g) => g.style.displayName).toList();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _headerOrder = headerOrder;
                            });
                          }
                        });


                        final totalItemCount = (groups.length * 2) + 1;

                        return ScrollablePositionedList.builder(
                          itemCount: totalItemCount,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const SizedBox(height: 12);
                            }

                            final groupIndex = ((index - 1) / 2).floor();
                            final group = groups[groupIndex];
                            final isHeader = (index - 1) % 2 == 0;

                            if (isHeader) {
                              return _GroupHeader(style: group.style);
                            } else {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 24.0),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10.0,
                                    mainAxisSpacing: 10.0,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: group.products.length,
                                  itemBuilder: (context, gridIndex) {
                                    final product = group.products[gridIndex];
                                    return ProductTile(
                                      product: product,
                                      onTap: () {
                                        // This logic remains valid
                                        final flatSortedProducts =
                                        groups.expand((g) => g.products).toList();
                                        final initialIndex = flatSortedProducts
                                            .indexWhere((p) => p.id == product.id);
                                        Navigator.of(context).push(
                                          SlideUpPageRoute(
                                            page: ProductSwiperScreen(
                                              products: flatSortedProducts,
                                              initialIndex:
                                              initialIndex != -1 ? initialIndex : 0,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: const Alignment(1.0, 0.5),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isFabVisible ? 1.0 : 0.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onLongPress: _isFabVisible ? _scrollToTop : null,
                      onTap: _isFabVisible && isUpEnabled
                          ? () => _skipToCategory(down: false)
                          : null,
                      child: FloatingActionButton(
                        heroTag: 'skip_up',
                        onPressed: null,
                        backgroundColor: fabUpBgColor,
                        foregroundColor: fabUpFgColor,
                        child: const Icon(Icons.keyboard_arrow_up),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onLongPress: _isFabVisible ? _scrollToBottom : null,
                      onTap: _isFabVisible && isDownEnabled
                          ? () => _skipToCategory(down: true)
                          : null,
                      child: FloatingActionButton(
                        heroTag: 'skip_down',
                        onPressed: null,
                        backgroundColor: fabDownBgColor,
                        foregroundColor: fabDownFgColor,
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildActionButtons(String buttonText) {
    final theme = ref.watch(themeProvider);
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: Icon(Icons.add_shopping_cart, color: theme.secondary, size: 24.0),
            label: Text(buttonText,
                style: TextStyle(color: theme.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet(
                    (_) => const ShoppingListBottomSheet(),
                isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: theme.background.withOpacity(0.5)),
        Expanded(
          child: TextButton.icon(
            icon: Icon(Icons.filter_alt, color: theme.secondary, size: 24.0),
            label: Text('Filter',
                style: TextStyle(color: theme.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet(
                    (_) => const FilterBottomSheet(),
                isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: theme.background.withOpacity(0.5)),
        const Expanded(
          child: SortButton(),
        ),
      ],
    );
  }

  ButtonStyle _actionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  void _showModalSheet(Widget Function(BuildContext) builder,
      {bool isScrollControlled = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
}

class _GroupHeader extends ConsumerWidget {
  const _GroupHeader({required this.style});
  final CategoryStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final Color contrastColor = getContrastColor(style.color);
    return Container(
      color: theme.pageBackground,
      padding: const EdgeInsets.fromLTRB(8, kHeaderTopPadding, 8, kHeaderBottomPadding),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(style.icon, color: contrastColor, size: 26),
            const SizedBox(width: 12),
            Text(
              style.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: contrastColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}