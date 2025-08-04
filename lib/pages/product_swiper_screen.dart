// lib/screens/product_swiper_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/custom_physics_widget.dart';

// KEY CHANGE: Convert to a stateful widget to manage background opacity.
class ProductSwiperScreen extends ConsumerStatefulWidget {
  final List<Product> products;
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

  // NEW: State variable to control the background's opacity.
  double _backgroundOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // NEW: Callback function for the child to report drag progress.
  void _onDragUpdate(double progress) {
    setState(() {
      // As drag progress increases, opacity decreases.
      _backgroundOpacity = 1.0 - progress;
    });
  }

  // NEW: Callback for when a dismiss is cancelled (e.g., swipe up).
  void _onDismissCancelled() {
    setState(() {
      // Reset the opacity to fully opaque.
      _backgroundOpacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // KEY CHANGE: The background color is now transparent to let the
      // home page show through. We'll control the fade with a container.
      backgroundColor: Colors.transparent,
      body: Container(
        // This container now controls the fading background.
        color: theme.background.withOpacity(_backgroundOpacity),
        child: Column(
          children: [
            Container(
              height: statusBarHeight,
              // The status bar color should also fade.
              color: theme.primary.withOpacity(_backgroundOpacity),
            ),
            Expanded(
              child: PageView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ComfortablePageScrollPhysics(dragThreshold: 15.0),
                dragStartBehavior: DragStartBehavior.down,
                controller: _pageController,
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  // Pass the new callbacks to the ProductDetails widget.
                  return ProductDetails(
                    product: product,
                    currentIndex: index + 1,
                    totalItems: widget.products.length,
                    onDragUpdate: _onDragUpdate,
                    onDismissCancelled: _onDismissCancelled,
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