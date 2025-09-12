// lib/components/management_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/services/category_service.dart'; // Ensure this is imported
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

class ManagementGridTile extends ConsumerWidget {
  final Product product;
  final List<Product> allProductsInList;

  // Callbacks are now correctly included
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const ManagementGridTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Card(
      elevation: 2,
      color: theme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Use the provided callbacks, with a fallback for the main list page's onTap
        onTap: onTap ?? (product.isCustom ? null : () => _navigateToDetails(context)),
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: product.isCustom
            ? _buildCustomItemContent(theme)
            : _buildRegularItemContent(theme),
      ),
    );
  }

  /// Builds the polished V4 tile for a regular sale item using a Stack.
  Widget _buildRegularItemContent(AppThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: The Image
        Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ImageWithAspectRatio(
              imageUrl: product.imageUrl,
              fit: BoxFit.contain,
              maxHeight: double.infinity,
              maxWidth: double.infinity,
            ),
          ),
        ),

        // Layer 2: The Gradient Scrim
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [ Colors.black.withOpacity(0.8), Colors.transparent ],
              ),
            ),
          ),
        ),

        // Layer 3: The Content Overlays
        Positioned(
          top: 8,
          left: 8,
          child: StoreLogo(storeName: product.store, height: 20),
        ),

        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 2,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${product.currentPrice.toStringAsFixed(2)} Fr.',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the content for a custom item.
  Widget _buildCustomItemContent(AppThemeData theme) {
    return Container(
      color: theme.primary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_basket_outlined,
                  color: theme.inactive.withOpacity(0.7), size: 40),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.inactive,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for navigation. No changes needed.
  void _navigateToDetails(BuildContext context) {
    final initialIndex =
    allProductsInList.indexWhere((p) => p.id == product.id);
    if (initialIndex != -1) {
      Navigator.of(context).push(SlideUpPageRoute(
        page: ProductSwiperScreen(
          products: allProductsInList,
          initialIndex: initialIndex,
        ),
      ));
    }
  }
}