// lib/pages/product_swiper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

const double _kSwipeVelocityThreshold = 50.0;

class ProductSwiperScreen extends ConsumerStatefulWidget {
  final List<PlainProduct> products;
  final int initialIndex;

  const ProductSwiperScreen({
    super.key,
    required this.products,
    required this.initialIndex,
  });

  @override
  ConsumerState<ProductSwiperScreen> createState() =>
      _ProductSwiperScreenState();
}

class _ProductSwiperScreenState extends ConsumerState<ProductSwiperScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > _kSwipeVelocityThreshold) {
          Navigator.of(context).pop();
        }
      },
      // --- CHANGES ARE HERE ---
      child: Scaffold(
        // 1. Set the background to the solid theme color to match the details page.
        backgroundColor: theme.primary,
        // 2. The Stack and Positioned.fill are no longer needed.
        //    The body can now be the Column directly.
        body: Column(
          children: [
            // This is still needed to account for the phone's status bar area.
            Container(height: statusBarHeight),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const _ReelsPhysics(),
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];

                  return ProductDetails(
                    key: ValueKey(product.id),
                    product: product,
                    currentIndex: index + 1,
                    totalItems: widget.products.length,
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

/// Custom scroll physics tuned for TikTok/YouTube Shorts style
class _ReelsPhysics extends PageScrollPhysics {
  const _ReelsPhysics({super.parent});

  @override
  _ReelsPhysics applyTo(ScrollPhysics? ancestor) {
    return _ReelsPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 200.0;

  @override
  double get maxFlingVelocity => 4000.0;

  Duration get transitionDuration => const Duration(milliseconds: 180);
}