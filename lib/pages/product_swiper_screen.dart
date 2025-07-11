import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// Custom scroll physics for smoother drag behavior. This remains unchanged.
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
      // This allows the user to dismiss the screen with a downward swipe.
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 1500) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        // The Scaffold's body is wrapped in a SafeArea. This is the core of the fix.
        // It ensures the content is rendered below the status bar, while the
        // Scaffold's background color correctly fills the space behind it.
        body: SafeArea(
          top: true,    // Apply padding for the top system UI (status bar/notch).
          bottom: false, // Do NOT apply padding at the bottom.
          child: Column(
            // The main layout is a Column containing the PageView and the close button.
            children: [
              Expanded(
                child: PageView.builder(
                  physics: const CustomPageScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.down,
                  controller: _pageController,
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    // We directly return the ProductDetails widget.
                    // It should NOT have its own SafeArea. The parent handles it now.
                    return ProductDetails(product: product);
                  },
                ),
              ),
              // The close button is the last item in the Column.
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the consistent close button at the bottom of the screen.
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: const Icon(
          Icons.arrow_downward,
          size: 32,
          color: AppColors.accent,
        ),
      ),
    );
  }
}