// lib/screens/product_swiper_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// 1. Import the file containing your new custom physics.
import 'package:sales_app_mvp/widgets/custom_physics_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            height: statusBarHeight,
            color: AppColors.primary,
          ),
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              // 2. KEY CHANGE: Use the new ComfortablePageScrollPhysics.
              //    This eliminates the "spring back" on slow, short drags.
              //    Feel free to adjust `dragThreshold` to your liking!
              physics: const ComfortablePageScrollPhysics(
                dragThreshold: 15.0,
              ),
              dragStartBehavior: DragStartBehavior.down,
              controller: _pageController,
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return ProductDetails(
                  product: product,
                  currentIndex: index + 1,
                  totalItems: widget.products.length,
                );
              },
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: const Icon(
          Icons.close,
          size: 32,
          color: AppColors.accent,
        ),
      ),
    );
  }
}