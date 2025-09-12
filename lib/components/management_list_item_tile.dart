// lib/components/management_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

class ManagementListItemTile extends ConsumerWidget {
  final Product product;
  final List<Product> allProductsInList;
  // --- The onDoubleTap callback is PRESERVED as requested ---
  final VoidCallback onDoubleTap;

  const ManagementListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    // --- REFACTOR 1: Create a single, common "shell" for both tile types ---
    // This ensures consistent margins, shape, color, and tap behavior.
    return Card(
      elevation: 0,
      color: theme.background,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // The main tap action navigates to details, but only for regular items.
        onTap: product.isCustom ? null : () => _navigateToDetails(context),
        // The double-tap action is the primary interaction for removal.
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          // The content inside the shell is what changes based on the product type.
          child: product.isCustom
              ? _buildCustomItemContent(theme)
              : _buildRegularItemContent(theme),
        ),
      ),
    );
  }

  // Helper method for navigation to keep the build method clean.
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

  /// Builds the CONTENT for a regular sale item.
  Widget _buildRegularItemContent(AppThemeData theme) {
    final priceString = product.currentPrice.toStringAsFixed(2);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: ImageWithAspectRatio(
            imageUrl: product.imageUrl,
            maxWidth: 60,
            maxHeight: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  color: theme.inactive,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              StoreLogo(storeName: product.store, height: 16),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$priceString Fr.',
          style: TextStyle(
            color: theme.inactive,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Builds the CONTENT for a custom item.
  Widget _buildCustomItemContent(AppThemeData theme) {
    // --- REFACTOR 2: Consistent icon styling and structure ---
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: theme.primary, // Use a subtle background color
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(Icons.shopping_basket_outlined, color: theme.inactive.withOpacity(0.7), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  color: theme.inactive,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // --- NEW: Display the category for better context, making it feel more complete ---
              Text(
                // Show custom subcategory if it exists, otherwise the main category.
                product.subcategory.isNotEmpty ? product.subcategory : product.category,
                style: TextStyle(color: theme.inactive.withOpacity(0.6), fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // --- NOTE: There is no price or remove button, preserving the simple look ---
      ],
    );
  }
}