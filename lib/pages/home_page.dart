import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/product_provider.dart';
import 'package:sales_app_mvp/providers/filtered_product_provider.dart';
import 'package:sales_app_mvp/components/product_tile.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:sales_app_mvp/widgets/search_bar.dart';
import 'package:sales_app_mvp/widgets/filter_sort_bottom_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = ref.read(paginatedProductsProvider.notifier);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !ref.read(paginatedProductsProvider).isLoading) {
      notifier.loadMoreProducts();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return const FilterSortBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final isPaginating = ref.watch(paginatedProductsProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false, // Remove top padding to move search bar higher
        child: Column(
          children: [
            // Search Bar at the very top
            const SearchBarWidget(),
            const SizedBox(height: 8),

            // Horizontal row of Filter & Sort and Quicksave buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  // Quicksave Button
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {}, // Empty for now, as per request
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.list, color: AppColors.secondary, size: 24.0),
                          SizedBox(width: 4.0),
                          Text(
                            'Quicksave',
                            style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter & Sort Button
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: _showFilterSheet,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.filter_alt, color: AppColors.secondary, size: 24.0),
                          SizedBox(width: 4.0),
                          Text(
                            'Filter and Sort',
                            style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Product Grid
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.active),
                ),
                error: (error, stackTrace) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load products.\nPlease check your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.inactive),
                      ),
                    ),
                  );
                },
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No products match your criteria.',
                        style: TextStyle(fontSize: 18, color: AppColors.inactive),
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length + (isPaginating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.active),
                        );
                      }
                      final product = products[index];
                      return ProductTile(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  ProductSwiperScreen(
                                    products: products,
                                    initialIndex: index,
                                  ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                final tween = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero);
                                final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                                return SlideTransition(
                                  position: tween.animate(curvedAnimation),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}