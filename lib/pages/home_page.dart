import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/search_bar_widget.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = false;

  final Map<String, GlobalKey> _headerKeys = {};
  List<String> _headerOrder = [];

  Color? _previousCategoryColor;
  Color? _nextCategoryColor;

  // This map is now built correctly using the public data from CategoryService.
  final Map<String, CategoryStyle> _styleByDisplayName = _getStyleByDisplayName();

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

  // --- CORRECTED METHOD ---
  static Map<String, CategoryStyle> _getStyleByDisplayName() {
    final Map<String, CategoryStyle> map = {};
    // Use the now-public 'allCategories' list from the service file.
    for (final mainCat in allCategories) {
      map[mainCat.style.displayName] = mainCat.style;
    }
    // Use the now-public 'defaultCategoryStyle' from the service file.
    map[defaultCategoryStyle.displayName] = defaultCategoryStyle;
    return map;
  }

  void _scrollListener() {
    if (!mounted) return;

    final shouldBeVisible = _scrollController.offset > 400;
    if (shouldBeVisible != _isFabVisible) {
      setState(() => _isFabVisible = shouldBeVisible);
    }

    _updateFabColors();
  }

  void _updateFabColors() {
    final Map<String, double> offsets = _getHeaderOffsets();
    if (offsets.isEmpty) return;

    final currentOffset = _scrollController.offset;

    String? nextCategoryName = offsets.keys.firstWhere(
          (name) => offsets[name]! > currentOffset + 1.0,
      orElse: () => '',
    );

    String? prevCategoryName = offsets.keys.lastWhere(
          (name) => offsets[name]! < currentOffset - 1.0,
      orElse: () => '',
    );

    final newNextColor = _styleByDisplayName[nextCategoryName]?.color;
    final newPrevColor = _styleByDisplayName[prevCategoryName]?.color;

    if (newNextColor != _nextCategoryColor || newPrevColor != _previousCategoryColor) {
      if (mounted) {
        setState(() {
          _nextCategoryColor = newNextColor;
          _previousCategoryColor = newPrevColor;
        });
      }
    }
  }

  Map<String, double> _getHeaderOffsets() {
    final Map<String, double> offsets = {};
    for (final headerName in _headerOrder) {
      final keyContext = _headerKeys[headerName]?.currentContext;
      if (keyContext != null) {
        final renderObject = keyContext.findRenderObject();
        if (renderObject is RenderSliver) {
          final offset = renderObject.constraints.precedingScrollExtent;
          offsets[headerName] = offset;
        }
      }
    }
    return offsets;
  }

  void _scrollToTop() {
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  void _skipToCategory({required bool down}) {
    final offsets = _getHeaderOffsets();
    if (offsets.isEmpty) return;

    final currentOffset = _scrollController.offset;
    double? targetOffset;
    final sortedOffsets = offsets.values.toList()..sort();

    if (down) {
      targetOffset = sortedOffsets.firstWhere(
            (offset) => offset > currentOffset + 1.0,
        orElse: () => -1.0,
      );
    } else {
      targetOffset = sortedOffsets.lastWhere(
            (offset) => offset < currentOffset - 1.0,
        orElse: () => -1.0,
      );
    }

    if (targetOffset != null && targetOffset != -1.0) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of build method is unchanged ...
    final fetchStatus = ref.watch(productFetchProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';
    const Color defaultFabColor = AppColors.secondary;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: _isFabVisible ? _scrollToTop : null,
              onTap: _isFabVisible ? () => _skipToCategory(down: false) : null,
              child: FloatingActionButton.small(
                heroTag: 'skip_up',
                onPressed: null,
                backgroundColor: _previousCategoryColor ?? defaultFabColor,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: _isFabVisible ? _scrollToBottom : null,
              onTap: _isFabVisible ? () => _skipToCategory(down: true) : null,
              child: FloatingActionButton.small(
                heroTag: 'skip_down',
                onPressed: null,
                backgroundColor: _nextCategoryColor ?? defaultFabColor,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
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

  Widget _buildActionButtons(String buttonText) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextButton.icon(
            icon: const Icon(Icons.add_shopping_cart,
                color: AppColors.secondary, size: 24.0),
            label: Text(buttonText,
                style: const TextStyle(color: AppColors.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet(
                    (_) => const ShoppingListBottomSheet(),
                isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: TextButton.icon(
            icon: const Icon(Icons.filter_alt,
                color: AppColors.secondary, size: 24.0),
            label: const Text('Filter',
                style: TextStyle(color: AppColors.inactive),
                overflow: TextOverflow.ellipsis),
            onPressed: () => _showModalSheet(
                    (_) => const FilterBottomSheet(), isScrollControlled: true),
            style: _actionButtonStyle(),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          flex: 1,
          child: SortButton(),
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

  List<Widget> _buildProductGroupSlivers(List<ProductGroup> groups) {
    _headerOrder = groups.map((g) => g.style.displayName).toList();
    for (var group in groups) {
      _headerKeys.putIfAbsent(group.style.displayName, () => GlobalKey());
    }

    return [
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ...groups.expand((group) => [
        SliverToBoxAdapter(
          key: _headerKeys[group.style.displayName],
          child: _GroupHeader(style: group.style),
        ),
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