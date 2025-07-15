import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// This custom physics class from your original code can be kept
// as it works for both horizontal and vertical scrolling.
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
    // Get the height of the top status bar (the notch/island area).
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // We removed the outer GestureDetector as its vertical swipe-to-close
    // functionality would conflict with the new vertical PageView.
    return Scaffold(
      backgroundColor: AppColors.background,
      // We use a Column to stack the UI elements vertically.
      body: Column(
        children: [
          // 1. A Container that acts as a custom "app bar" area.
          // Its height perfectly matches the system's status bar.
          Container(
            height: statusBarHeight,
            color: AppColors.primary,
          ),
          // 2. The main content, which expands to fill the available space.
          Expanded(
            child: PageView.builder(
              // MODIFICATION: Changed scroll direction to vertical.
              scrollDirection: Axis.vertical,
              physics: const CustomPageScrollPhysics(),
              dragStartBehavior: DragStartBehavior.down,
              controller: _pageController,
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return ProductDetails(product: product);
              },
            ),
          ),
          // 3. The dedicated close button at the bottom of the screen.
          _buildCloseButton(context),
        ],
      ),
    );
  }

  /// Helper method to build the custom close button.
  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.background,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          // Use zero radius for a button that blends into the edge.
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        // MODIFICATION: Changed icon for better UX clarity.
        // An arrow icon is now ambiguous, but a close icon is clear.
        child: const Icon(
          Icons.close,
          size: 32,
          color: AppColors.accent,
        ),
      ),
    );
  }
}