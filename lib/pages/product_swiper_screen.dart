import 'package:flutter/gestures.dart'; // Make sure this is imported
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// Your CustomPageScrollPhysics class remains the same and is still needed!
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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- REPLACED Dismissible with GestureDetector ---
    return GestureDetector(
      // We manually detect a fast downward swipe (a "fling").
      onVerticalDragEnd: (details) {
        // 'primaryVelocity' is the speed of the swipe.
        // A positive value means swiping downwards.
        // We set a threshold to only trigger on a fast swipe.
        if (details.primaryVelocity != null && details.primaryVelocity! > 1500) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text(
            widget.products[_currentIndex].name,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_downward, color: AppColors.secondary),
            tooltip: 'Swipe down to close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: PageView.builder(
          // This physics class is still important for the horizontal swipe feel!
          physics: const CustomPageScrollPhysics(),
          // This behavior helps the PageView win the gesture arena more easily.
          dragStartBehavior: DragStartBehavior.down,
          controller: _pageController,
          itemCount: widget.products.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final product = widget.products[index];
            return ProductDetails(product: product);
          },
        ),
      ),
    );
  }
}