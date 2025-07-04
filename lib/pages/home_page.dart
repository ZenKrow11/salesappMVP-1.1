import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider imports
import 'package:sales_app_mvp/providers/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';

// Component and Screen imports
import 'package:sales_app_mvp/components/active_list_selector_bottom_sheet.dart';
import 'package:sales_app_mvp/components/filter_sort_bottom_sheet.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/search_bar.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// --- MODIFICATION 1: Convert to ConsumerStatefulWidget ---
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // --- MODIFICATION 2: Add state variables ---
  // Controller to detect scroll position
  final ScrollController _scrollController = ScrollController();
  // Boolean to control the FAB's visibility
  bool _isFabVisible = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to the scroll controller
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // ALWAYS dispose of controllers
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // --- MODIFICATION 3: The listener function ---
  // This function is called every time the user scrolls
  void _scrollListener() {
    // Check if the user has scrolled down more than 400 pixels
    if (_scrollController.offset > 400 && !_isFabVisible) {
      setState(() {
        _isFabVisible = true;
      });
    }
    // Check if the user has scrolled back up
    else if (_scrollController.offset <= 400 && _isFabVisible) {
      setState(() {
        _isFabVisible = false;
      });
    }
  }

  // --- MODIFICATION 4: Function to scroll to the top ---
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0, // Scroll to the top of the list
      duration: const Duration(milliseconds: 500), // Animation duration
      curve: Curves.easeInOut, // Animation curve
    );
  }

  // Helper methods are now part of the State class
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => const FilterSortBottomSheet(),
    );
  }

  void _showActiveListSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const ActiveListSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList == null ? 'Select List' : 'List: $activeList';

    return Scaffold(
      backgroundColor: AppColors.background,
      // --- MODIFICATION 5: Add the FloatingActionButton to the Scaffold ---
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFabVisible ? 1.0 : 0.0, // Control visibility
        child: FloatingActionButton(
          onPressed: _isFabVisible ? _scrollToTop : null, // Prevent accidental taps when hidden
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.arrow_upward,
              size: 32.0),
        ),
      ),
      body: Column(
        children: [
          // The header UI remains the same.
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(12.0, MediaQuery.of(context).padding.top / 4, 12.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 56, child: SearchBarWidget()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary, size: 24.0),
                        label: Flexible(
                          child: Text(
                            buttonText,
                            style: const TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () => _showActiveListSelector(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: AppColors.inactive.withAlpha(128)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.filter_alt, color: AppColors.secondary, size: 24.0),
                        label: const Flexible(
                          child: Text(
                            'Filter and Sort',
                            style: TextStyle(color: AppColors.inactive),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () => _showFilterSheet(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: AppColors.inactive.withAlpha(128)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products match your filter.'));
                }
                return GridView.builder(
                  // --- MODIFICATION 6: Attach the scroll controller ---
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () {
                        // --- START OF NEW CODE ---
                        showModalBottomSheet(
                          context: context,
                          // Allows the sheet to be full-screen. This is essential.
                          isScrollControlled: true,
                          // We make the sheet's container transparent to control the color and corners ourselves.
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            // Wrap your screen in a Container to apply custom styling.
                            return Container(
                              // Make it slightly less than full height to show it's a modal overlay.
                              height: MediaQuery.of(context).size.height * 0.95,
                              decoration: const BoxDecoration(
                                // Use the same background color as your swiper screen.
                                color: AppColors.background,
                                // Apply rounded corners only to the top.
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              // The content of the sheet is your existing swiper screen.
                              child: ProductSwiperScreen(
                                products: products,
                                initialIndex: index,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Failed to load products: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}