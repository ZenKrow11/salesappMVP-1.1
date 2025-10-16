// lib/pages/product_swiper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: theme.background.withOpacity(0.95)),
          ),
          Column(
            children: [
              // Leave status bar space transparent
              Container(height: statusBarHeight, color: Colors.transparent),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const _ReelsPhysics(),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];

                    // Each product detail fills the screen, like TikTok/Shorts
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
        ],
      ),
    );
  }
}

/// Custom scroll physics tuned for TikTok/YouTube Shorts style
class _ReelsPhysics extends PageScrollPhysics {
  const _ReelsPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _ReelsPhysics applyTo(ScrollPhysics? ancestor) {
    return _ReelsPhysics(parent: buildParent(ancestor));
  }

  /// Lower fling threshold so a light swipe changes pages
  @override
  double get minFlingVelocity => 200.0;

  /// Cap velocity to avoid overly fast flings
  @override
  double get maxFlingVelocity => 4000.0;

  /// Faster snapping animation (default is ~300ms)
  Duration get transitionDuration => const Duration(milliseconds: 180);
}
