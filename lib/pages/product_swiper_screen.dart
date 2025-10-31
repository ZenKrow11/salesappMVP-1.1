// C:\Users\patri\AndroidStudioProjects\salesappMVP-1.2\lib\pages\product_swiper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sales_app_mvp/components/preloaded_ad_widget.dart';
import 'package:sales_app_mvp/components/product_details.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

const int _adFrequency = 8;
const double _kSwipeVelocityThreshold = 50.0;

// --- DEFINE THE GRACE PERIOD THRESHOLD ---
const int _adGracePeriodSwipes = 4; // The ad will only appear after this many swipes.

class ProductSwiperScreen extends ConsumerStatefulWidget {
  // ... (constructor is unchanged)
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

  // --- STEP 1: INTRODUCE STATE FOR SWIPE TRACKING ---
  int _userSwipeCount = 0;

  @override
  void initState() {
    super.initState();

    final isPremium = ref.read(isPremiumProvider);
    final int productIndex = widget.initialIndex;
    int initialPage;

    if (isPremium) {
      initialPage = productIndex;
    } else {
      final int adBlocksBefore = (productIndex / _adFrequency).floor();
      initialPage = productIndex + adBlocksBefore;
    }

    _pageController = PageController(
      initialPage: initialPage,
    );

    // Pre-loading logic remains the same.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

            // --- STEP 2: UPDATE STATE ON USER INTERACTION ---
            onPageChanged: (newPage) {
              // We only need to increment the counter, we don't care about the direction.
              // This ensures the grace period is "unlocked" once and stays unlocked.
              if (mounted) {
                setState(() {
                  _userSwipeCount++;
                });
              }
            },
            itemBuilder: (context, pageIndex) {
              // --- STEP 3: MODIFY THE AD DISPLAY LOGIC ---
              final bool isAdSlot = !isPremium && (pageIndex + 1) % (_adFrequency + 1) == 0 && pageIndex != 0;
              final bool isGracePeriodOver = _userSwipeCount >= _adGracePeriodSwipes;

              // Show the ad ONLY if it's an ad slot AND the grace period is over.
              if (isAdSlot && isGracePeriodOver) {
                return const Center(
                  child: PreloadedAdWidget(
                    placement: AdPlacement.productSwiper,
                    adSize: AdSize.largeBanner,
                  ),
                );
              } else {
                // In all other cases (premium user, not an ad slot, OR during the grace period),
                // show the product.
                final int adOffset = isPremium
                    ? 0
                // Calculate the number of ads that SHOULD have appeared before this page.
                    : ((pageIndex + 1) / (_adFrequency + 1)).floor();
                final int productIndex = pageIndex - adOffset;

                if (productIndex < 0 || productIndex >= widget.products.length) {
                  return const Center(child: Text("Error: Product index out of bounds."));
                }

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