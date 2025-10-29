// lib/pages/product_swiper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import for AdSize
import 'package:sales_app_mvp/components/preloaded_ad_widget.dart'; // Import new widget
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart'; // Import for AdPlacement
import 'package:sales_app_mvp/widgets/app_theme.dart';

const int _adFrequency = 8;
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

    // --- Start pre-loading the swiper ad as soon as the screen is opened ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        ref.read(adManagerProvider.notifier).preloadBannerAd(AdPlacement.productSwiper, AdSize.largeBanner);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final int adCount =
    isPremium ? 0 : (widget.products.length / _adFrequency).floor();
    final int totalPageCount = widget.products.length + adCount;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > _kSwipeVelocityThreshold) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.primary,
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const _ReelsPhysics(),
            itemCount: totalPageCount,
            itemBuilder: (context, pageIndex) {
              if (adCount > 0 && (pageIndex + 1) % (_adFrequency + 1) == 0) {
                // --- Use the new PreloadedAdWidget ---
                return const Center(
                  child: PreloadedAdWidget(
                    placement: AdPlacement.productSwiper,
                    adSize: AdSize.largeBanner,
                  ),
                );
              } else {
                final int adOffset = (adCount > 0)
                    ? ((pageIndex + 1) / (_adFrequency + 1)).floor()
                    : 0;
                final int productIndex = pageIndex - adOffset;
                final product = widget.products[productIndex];

                return ProductDetails(
                  key: ValueKey(product.id),
                  product: product,
                  currentIndex: productIndex + 1,
                  totalItems: widget.products.length,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Custom scroll physics (unchanged).
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