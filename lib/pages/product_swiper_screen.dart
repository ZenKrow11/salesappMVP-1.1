// lib/screens/product_swiper_screen.dart (or wherever this file is)

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class CustomPageScrollPhysics extends PageScrollPhysics {
  const CustomPageScrollPhysics({super.parent});

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 12.0;
}


class ProductSwiperScreen extends ConsumerStatefulWidget {
  final List<Product> products;
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
  // PageController is no longer needed because we're not tracking the current index for a title
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
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 1500) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // REMOVED: The entire AppBar is gone, as requested.
        // appBar: AppBar(...),

        // UPDATED: The body is now a Column to hold the PageView and the button.
        // We also wrap it in a SafeArea to avoid the system status bar at the top.
        body: SafeArea(
          child: Column(
            children: [
              // The PageView must be wrapped in Expanded to fill the available space.
              Expanded(
                child: PageView.builder(
                  physics: const CustomPageScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.down,
                  controller: _pageController,
                  itemCount: widget.products.length,
                  // The onPageChanged is no longer needed since we removed the title
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    return ProductDetails(product: product);
                  },
                ),
              ),
              // NEW: The bottom button is added here, outside the PageView.
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: A dedicated method for the new bottom arrow button.
  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Span the entire width
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          // Makes the button look like part of the background
          backgroundColor: AppColors.background,
          shadowColor: Colors.transparent,
          elevation: 0,
          // Add padding for a larger touch area and visual spacing
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No rounded corners
          ),
        ),
        child: const Icon(
          Icons.arrow_downward, // The "arrow button" icon
          size: 32,
          color: AppColors.accent, // A color that's visible on the dark background
        ),
      ),
    );
  }
}