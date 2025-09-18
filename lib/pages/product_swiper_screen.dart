// lib/pages/product_swiper_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';

import 'package:sales_app_mvp/models/plain_product.dart'; // <-- TYPE CHANGE
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/custom_physics_widget.dart';

class ProductSwiperScreen extends ConsumerStatefulWidget {
  final List<PlainProduct> products; // <-- TYPE CHANGE
  final int initialIndex;

  const ProductSwiperScreen({
    super.key,
    required this.products,
    required this.initialIndex,
  });

  @override
  ConsumerState<ProductSwiperScreen> createState() => _ProductSwiperScreenState();
}

class _ProductSwiperScreenState extends ConsumerState<ProductSwiperScreen> {
  late final PageController _pageController;
  double _backgroundOpacity = 1.0;
  bool _isPopping = false;

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

  void _onDragUpdate(double progress) {
    if (_isPopping) return;
    setState(() => _backgroundOpacity = 1.0 - progress);
  }

  void _onDismissCancelled() {
    setState(() => _backgroundOpacity = 1.0);
  }

  void _onDismissConfirmed() {
    setState(() {
      _isPopping = true;
      _backgroundOpacity = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: theme.background.withOpacity(_backgroundOpacity),
        child: Column(
          children: [
            Container(height: statusBarHeight, color: theme.primary.withOpacity(_backgroundOpacity)),
            Expanded(
              child: IgnorePointer(
                ignoring: _isPopping,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const ComfortablePageScrollPhysics(dragThreshold: 15.0),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];

                    // This now correctly passes a PlainProduct to ProductDetails
                    return ProductDetails(
                      key: ValueKey(product.id),
                      product: product, // <-- TYPE CHANGE
                      currentIndex: index + 1,
                      totalItems: widget.products.length,
                      onDragUpdate: _onDragUpdate,
                      onDismissCancelled: _onDismissCancelled,
                      onDismissConfirmed: _onDismissConfirmed,
                      onPrevious: () {
                        if (_pageController.page?.round() != 0) {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      onNext: () {
                        if (_pageController.page?.round() != widget.products.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}