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
      isScrollControlled: true, // Allows the sheet to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

    // We now use a Scaffold to host the FloatingActionButton
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterSheet,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.filter_alt,
            size: 32,
            color: AppColors.primary),
      ),
      body: Column(
        children: [
          // Search bar remains at the top
          const SearchBarWidget(),

          // The filter and sort dropdowns have been removed from here

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
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // Add padding at bottom for FAB
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
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
    );
  }
}